//
//  IJTArp-scan.m
//  IJTArp-scan
//
//  Created by 聲華 陳 on 2015/4/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArp-scan.h"
#import <sys/socket.h>
#import <net/if.h>
#import <sys/ioctl.h>
#import <net/bpf.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/if_arp.h>
#import <net/ethernet.h>
#import <net/if_dl.h>
#import <netinet/ip.h>
#import "IJTSysctl.h"
#import "IJTNetowrkStatus.h"
struct ijt_ether_arp_header {
    struct ether_header ether;
    u_short	ar_hrd;		/* format of hardware address */
    u_short	ar_pro;		/* format of protocol address */
    u_char	ar_hln;		/* length of hardware address */
    u_char	ar_pln;		/* length of protocol address */
    u_short	ar_op;		/* one of: */
    struct ether_addr senderEther;
    struct in_addr senderIP;
    struct ether_addr targetEther;
    struct in_addr targetIP;
} __attribute__((packed));
#define ARP_HDR_LEN 28
@interface IJTArp_scan ()

@property (nonatomic) int bpfd;
@property (nonatomic) int bpfbufsize;
@property (nonatomic) struct ijt_ether_arp_header sendarp;
@property (nonatomic) in_addr_t startIP;
@property (nonatomic) in_addr_t endIP;
@property (nonatomic) in_addr_t currentIP;

@end

@implementation IJTArp_scan

- (id)initWithInterface: (NSString *)interface {
    self = [super init];
    if(self) {
        _bpfd = -1;
        _startIP = 0;
        _endIP = 0;
        _currentIP = 0;
        
        [self open: interface];
    }
    return self;
}

- (void)open: (NSString *)interface {
    _bpfbufsize = -1;
    char buf[256];
    struct ifreq ifr; //interface
    int n = 0, maxbuf;
    NSString *currentIP = nil;
    NSString *macAddress = nil;
    
    if(_bpfd < 0) {
        do {
            snprintf(buf, sizeof(buf), "/dev/bpf%d", n++);
            _bpfd = open(buf, O_RDWR, 0);
        }//end do
        while (_bpfd < 0 && (errno == EBUSY || errno == EPERM));
        
        if(_bpfd < 0)
            goto BAD;
    }//end if
    
   
    //get BPF buffer size
    if(ioctl(_bpfd, BIOCGBLEN, &n) < 0)
        goto BAD;
    
    //try to set max buffer size
    maxbuf = [IJTSysctl sysctlValueByname:@"debug.bpf_maxbufsize"];
    if(maxbuf == -1)
        maxbuf = 1024*512;
    for (n += sizeof(int); n <= maxbuf ; n += sizeof(int)) {
        if (ioctl(_bpfd, BIOCSBLEN, &n) < 0) {
            if (errno == ENOBUFS)
                break;
            goto BAD;
        }
    }
    
    //get final size
    if(ioctl(_bpfd, BIOCGBLEN, &n) < 0)
        goto BAD;
    _bpfbufsize = n;
    
    //set interface name
    snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "%s", [interface UTF8String]);
    if(ioctl(_bpfd, BIOCSETIF, &ifr) < 0)
        goto BAD;
    
    //即時模式
    n = 1;
    if(ioctl(_bpfd, BIOCIMMEDIATE, &n) < 0)
        goto BAD;
    
    /*
     *  NetBSD and FreeBSD BPF have an ioctl for enabling/disabling
     *  automatic filling of the link level source address.
     */
    n = 0;
    if (ioctl(_bpfd, BIOCSHDRCMPLT, &n) < 0)
        goto BAD;
    
    /*
     *Example of using bpf to capture packets, (ssh)
     *https://gist.github.com/msantos/939154
     */
    
    struct bpf_program fcode = {0};
    /* dump arp op == reply packets only */
    struct bpf_insn insns[] = {
        BPF_STMT(BPF_LD + BPF_H + BPF_ABS, 12),
        BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, ETHERTYPE_ARP, 0, 3),
        BPF_STMT(BPF_LD + BPF_H + BPF_ABS, 20),
        BPF_JUMP(BPF_JMP + BPF_JEQ + BPF_K, 2, 0, 1),
        BPF_STMT(BPF_RET + BPF_K, 65535),
        BPF_STMT(BPF_RET + BPF_K, 0),
    };
    /* same as
     struct bpf_insn insns[] = {
     { 0x28, 0, 0, 0x0000000c },
     { 0x15, 0, 3, 0x00000806 },
     { 0x28, 0, 0, 0x00000014 },
     { 0x15, 0, 1, 0x00000002 },
     { 0x6, 0, 0, 0x0000ffff },
     { 0x6, 0, 0, 0x00000000 }};
     */
    /*
     in tcpdump
     ~ % sudo tcpdump -i en0 -d "arp[6:2] == 0x0002"
     (000) ldh      [12]
     (001) jeq      #0x806           jt 2	jf 5
     (002) ldh      [20]
     (003) jeq      #0x2             jt 4	jf 5
     (004) ret      #65535
     (005) ret      #0
     ~ % sudo tcpdump -i en0 -dd "arp[6:2] == 0x0002"
     { 0x28, 0, 0, 0x0000000c },
     { 0x15, 0, 3, 0x00000806 },
     { 0x28, 0, 0, 0x00000014 },
     { 0x15, 0, 1, 0x00000002 },
     { 0x6, 0, 0, 0x0000ffff },
     { 0x6, 0, 0, 0x00000000 },
     ~ % sudo tcpdump -i en0 -ddd "arp[6:2] == 0x0002"
     6
     40 0 0 12
     21 0 3 2054
     40 0 0 20
     21 0 1 2
     6 0 0 65535
     6 0 0 0
     */
    /* Set the filter */
    fcode.bf_len = sizeof(insns) / sizeof(struct bpf_insn);
    fcode.bf_insns = &insns[0];
    
    if(ioctl(_bpfd, BIOCSETF, &fcode) < 0)
        goto BAD;
    
    //fill some arp field
    currentIP = [IJTNetowrkStatus currentIPAddress:interface];
    if(currentIP == nil)
        goto BAD;
    
    macAddress = [IJTNetowrkStatus wifiMacAddress];
    if(macAddress == nil)
        goto BAD;
    
    //clear
    memset(&_sendarp, 0, sizeof(_sendarp));
    //ethernet
    
    memset(&_sendarp.ether.ether_dhost, 0xff, sizeof(_sendarp.ether.ether_dhost));
    _sendarp.ether.ether_type = htons(ETHERTYPE_ARP);
    
    //arp
    _sendarp.ar_hrd = htons(ARPHRD_ETHER);
    _sendarp.ar_op = htons(ARPOP_REQUEST);
    _sendarp.ar_hln = ETHER_ADDR_LEN;
    _sendarp.ar_pln = 4;
    _sendarp.ar_pro = htons(ETHERTYPE_IP);
    
    //arp ethernet
    memcpy(&_sendarp.senderEther, ether_aton([macAddress UTF8String]), sizeof(_sendarp.senderEther));
    if(inet_pton(AF_INET, [currentIP UTF8String], &_sendarp.senderIP) == -1)
        goto BAD;
    memset(&_sendarp.targetEther, 0, sizeof(_sendarp.targetEther));
    
    self.errorHappened = NO;
    return;
    
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    [self close];
    return;
}

- (void)dealloc {
    [self close];
}

- (void)close {
    if(_bpfd >= 0) {
        close(_bpfd);
        _bpfd = -1;
    }
}

- (int)setFrom: (NSString *)startIpAddress
            to: (NSString *)endIpAddress {
    struct in_addr startIp, endIp;
    
    
    if(inet_pton(AF_INET, [startIpAddress UTF8String], &startIp) == -1)
        goto BAD;
    if(inet_pton(AF_INET, [endIpAddress UTF8String], &endIp) == -1)
        goto BAD;
    
    //range error and swap
    if(startIp.s_addr > endIp.s_addr) {
        in_addr_t temp = startIp.s_addr;
        startIp.s_addr = endIp.s_addr;
        endIp.s_addr = temp;
    }//end if
    
    _startIP = startIp.s_addr;
    _endIP = endIp.s_addr;
    _currentIP = _startIP;
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (int)setNetwork: (NSString *)network
            slash: (int)slash {
    struct in_addr startIp, endIp, temp;
    u_int32_t mask;
    
    
    if(slash < 0 || slash > 32) {
        errno = EINVAL;		/* Invalid argument */
        goto BAD;
    }//end if
    
    mask = 1 << 31;
    temp.s_addr = 0;
    if(inet_pton(AF_INET, [network UTF8String], &startIp) == -1)
        goto BAD;
    
    //get real network ip
    for(u_int32_t i = 0 ; i < slash ; i++) {
        if(mask & ntohl(startIp.s_addr))
            temp.s_addr |= mask;
        mask >>= 1;
    }
    startIp.s_addr = htonl(temp.s_addr);
    
    //padding zero bit
    endIp.s_addr = ntohl(startIp.s_addr);
    mask = 1;
    for(u_int32_t i = 0 ; i < 32 - slash ; i++) {
        endIp.s_addr |= mask;
        mask <<= 1;
    }
    endIp.s_addr = htonl(endIp.s_addr);
    
    _startIP = startIp.s_addr;
    _endIP = endIp.s_addr;
    _currentIP = _startIP;
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (int)setLAN {
    struct ifreq ifr;
    int sockfd = -1;
    struct in_addr nmask;
    struct in_addr ip;
    int mask = 1;
    int slash = 0;
    
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if(sockfd < 0)
        goto BAD;
    
    //get mask addr
    memset(&ifr, 0, sizeof(ifr));
    snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "en0");
    if((ioctl(sockfd, SIOCGIFNETMASK, &ifr)) == -1)
        goto BAD;
    memcpy(&nmask.s_addr,
           &(*(struct sockaddr_in *)&ifr.ifr_addr).sin_addr,
           sizeof(nmask.s_addr));
    for(int i = 0 ; i < 32 ; i++) {
        if(mask & nmask.s_addr)
            slash++;
        mask <<= 1;
    }
    
    //get ip addr
    memset(&ifr, 0, sizeof(ifr));
    snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "en0");
    if((ioctl(sockfd, SIOCGIFADDR, &ifr)) == -1)
        goto BAD;
    memcpy(&ip.s_addr,
           &(*(struct sockaddr_in *)&ifr.ifr_addr).sin_addr, sizeof(ip.s_addr));
    
    close(sockfd);
    
    return [self setNetwork:[NSString stringWithUTF8String:inet_ntoa(ip)]
                      slash:slash];
    
BAD:
    self.errorCode = errno;
    if(sockfd >= 0)
        close(sockfd);
    self.errorHappened = YES;
    return -1;
}

- (int)injectWithInterval: (useconds_t)interval {
    ssize_t sizebuffer = 0;
    struct ijt_ether_arp_header temp = {0};
    in_addr_t targetAddr;
    
    if(ntohl(_currentIP) > ntohl(_endIP))
        goto OK;
    
    temp = _sendarp;
    targetAddr = _currentIP;
    memcpy(&temp.targetIP, &targetAddr, sizeof(temp.targetIP));
    
    //send
    if((sizebuffer = write(_bpfd, &temp, sizeof(temp))) < 0)
        goto BAD;
    if(sizebuffer != sizeof(temp))
        goto BAD;
    usleep(interval);
    
    _currentIP = htonl(ntohl(_currentIP) + 1);
    
OK:
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (int)readTimeout: (u_int32_t)timeout
            target: (id)target
          selector: (SEL)selector
            object: (id)object {
    ssize_t bpf_len = 0; //bpf receive len
    ArpscanCallback arpscancallback = NULL;
    
    //if need callback
    if(target && selector) {
        arpscancallback = (ArpscanCallback)[target methodForSelector:selector];
    }
    
    char *recvbuffer = NULL;
    recvbuffer = malloc(_bpfbufsize);
    if(!recvbuffer)
        goto BAD;
    
    while(1) {
        int n = 0;
        fd_set readfd = {};
        
        struct ijt_ether_arp_header *recvArp = NULL;
        struct timespec tv = {};
        tv.tv_sec = timeout / 1000;
        tv.tv_nsec = timeout % 1000 * 1000;
        struct bpf_hdr *bp = NULL; //bpf header
        char *p = NULL; //pointer to packet header start position
        
        FD_ZERO(&readfd);
        FD_SET(_bpfd, &readfd);
        if((n = pselect(_bpfd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
            goto BAD;
        if(n == 0) { //timeout
            break;
        }//end if
        
        if(!FD_ISSET(_bpfd, &readfd))
            continue;
        
        memset(recvbuffer, 0, sizeof(_bpfbufsize));
        if((bpf_len = read(_bpfd, recvbuffer, _bpfbufsize)) < 0)
            goto BAD;
        bp = (struct bpf_hdr *)recvbuffer;
        
        //analyze each packet
        while(bpf_len > 0) {
            p = (char *)bp + bp->bh_hdrlen;
            
            //receive
            recvArp = (struct ijt_ether_arp_header *)p;
            
            if(recvArp->ether.ether_type == htons(ETHERTYPE_ARP) &&
               recvArp->ar_op == htons(ARPOP_REPLY)) {
                int found = 0;
                
                //filter
                if(ntohl(recvArp->senderIP.s_addr) >= ntohl(_startIP) &&
                   ntohl(recvArp->senderIP.s_addr) <= ntohl(_endIP))
                    found = 1;
                
                if(!found)
                    continue;
                
                NSString *targetMac = [self ether_ntoa:&recvArp->senderEther];
                NSString *targetIp = [NSString stringWithUTF8String:inet_ntoa(recvArp->senderIP)];
                NSString *etherSource = [self ether_ntoa:((struct ether_addr *)recvArp->ether.ether_shost)];
                
                struct timeval timestamp = { bp->bh_tstamp.tv_sec, bp->bh_tstamp.tv_usec };
                
                if(arpscancallback) {
                    arpscancallback(target, selector, timestamp, targetIp, targetMac, etherSource, object);
                }
                else {
                    char timestr[16] = {};
                    time_t local_tv_sec = timestamp.tv_sec;
                    
                    strftime(timestr, sizeof timestr, "%H:%M:%S", localtime(&local_tv_sec));
                    
                    printf("At: %s.%.6d, IP: %s, MAC: %s\n",
                           timestr, bp->bh_tstamp.tv_usec, [targetIp UTF8String], [targetMac UTF8String]);
                }
            }//end if recv
            
            //next packet
            bpf_len -= BPF_WORDALIGN(bp->bh_hdrlen + bp->bh_caplen);
            if(bpf_len > 0) {
                bp = (struct bpf_hdr *) ((char *)bp + BPF_WORDALIGN(bp->bh_hdrlen + bp->bh_caplen));
            }
        }//end while bpf_len > 0
    }//end while
    
OK:
    if(recvbuffer)
        free(recvbuffer);
    self.errorHappened = NO;
    return 0;
BAD:
    if(recvbuffer)
        free(recvbuffer);
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (NSString *)ether_ntoa:(const struct ether_addr *)addr {
    return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", addr->octet[0], addr->octet[1], addr->octet[2], addr->octet[3], addr->octet[4], addr->octet[5]];
}

- (u_int64_t)getTotalInjectCount {
    return (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_startIP) + 1;
}

- (u_int64_t)getRemainInjectCount {
    return (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_currentIP) + 1 <= 0 ? 0 : (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_currentIP) + 1;
}

- (NSString *)getStartIpAddress {
    char ntop_buf[256];
    struct in_addr addr = {_startIP};
    
    inet_ntop(AF_INET, &addr, ntop_buf, sizeof(ntop_buf));
    return [NSString stringWithUTF8String:ntop_buf];
}

- (NSString *)getEndIpAddress {
    char ntop_buf[256];
    struct in_addr addr = {_endIP};
    
    inet_ntop(AF_INET, &addr, ntop_buf, sizeof(ntop_buf));
    return [NSString stringWithUTF8String:ntop_buf];
}

- (NSString *)getCurrentIpAddress {
    char ntop_buf[256];
    struct in_addr addr = {_currentIP};
    
    inet_ntop(AF_INET, &addr, ntop_buf, sizeof(ntop_buf));
    return [NSString stringWithUTF8String:ntop_buf];
}
@end
