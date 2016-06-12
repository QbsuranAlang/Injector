//
//  IJTArping.m
//  IJTArping
//
//  Created by 聲華 陳 on 2015/4/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArping.h"
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
#import <sys/sysctl.h>
#import "IJTNetowrkStatus.h"
#import "IJTSysctl.h"
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
@interface IJTArping ()

@property (nonatomic) int bpfd;
@property (nonatomic) int bpfbufsize;
@property (nonatomic) NSString *device;
@property (nonatomic) struct ijt_ether_arp_header sendetherarp;

@end

@implementation IJTArping

- (id)initWithInterface: (NSString *)interface {
    self = [super init];
    if(self) {
        self.bpfd = -1;
        [self open: interface];
    }
    return self;
}

- (void)open: (NSString *)interface {
    self.bpfbufsize = -1;
    char buf[256];
    struct ifreq ifr; //interface
    int n = 0, maxbuf;
    
    NSString *currentIP = [IJTNetowrkStatus currentIPAddress:interface];
    NSString *macAddress = [IJTNetowrkStatus wifiMacAddress];
    
    //ether header
    if(macAddress == nil)
        goto BAD;
    if(currentIP == nil)
        goto BAD;
    
    if(self.bpfd < 0) {
        do {
            snprintf(buf, sizeof(buf), "/dev/bpf%d", n++);
            self.bpfd = open(buf, O_RDWR, 0);
        }//end do
        while (self.bpfd < 0 && (errno == EBUSY || errno == EPERM));
        if(self.bpfd < 0)
            goto BAD;
    }//end if
    
    //get BPF buffer size
    if(ioctl(self.bpfd, BIOCGBLEN, &n) < 0)
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
    if(ioctl(self.bpfd, BIOCSETIF, &ifr) < 0)
        goto BAD;
    
    //即時模式
    n = 1;
    if(ioctl(self.bpfd, BIOCIMMEDIATE, &n) < 0)
        goto BAD;
    
    /*
     *  NetBSD and FreeBSD BPF have an ioctl for enabling/disabling
     *  automatic filling of the link level source address.
     */
    n = 0;
    if (ioctl(self.bpfd, BIOCSHDRCMPLT, &n) < 0)
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
    
    if(ioctl(self.bpfd, BIOCSETF, &fcode) < 0)
        goto BAD;
    
    self.device = interface;
    memset(&_sendetherarp, 0, sizeof(_sendetherarp));
    
    memset(_sendetherarp.ether.ether_dhost, 0xff, sizeof(_sendetherarp.senderEther));
    _sendetherarp.ether.ether_type = htons(ETHERTYPE_ARP);
    
    //arp header
    _sendetherarp.ar_hrd = htons(ARPHRD_ETHER);
    _sendetherarp.ar_op = htons(ARPOP_REQUEST);
    _sendetherarp.ar_hln = ETHER_ADDR_LEN;
    _sendetherarp.ar_pln = 4;
    _sendetherarp.ar_pro = htons(ETHERTYPE_IP);
    
    //arp ether header
    if(currentIP == nil || inet_pton(AF_INET, [currentIP UTF8String], &(_sendetherarp.senderIP)) == -1)
        goto BAD;
    memcpy(&_sendetherarp.senderEther, ether_aton([macAddress UTF8String]), sizeof(_sendetherarp.senderEther));
    memset(&_sendetherarp.targetEther, 0, sizeof(_sendetherarp.targetEther));
    
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
    if(self.bpfd >= 0) {
        close(self.bpfd);
        self.bpfd = -1;
    }
}

- (int)arpingTargetIP: (NSString *)whereto
              timeout: (u_int32_t)timeout
               target: (id)target
             selector: (SEL)selector
               object: (id)object {
    
    char *recvbuffer = NULL;
    struct ijt_ether_arp_header *recvetherarp = NULL;
    ssize_t sizebuffer = 0;
    struct timeval tvsend;
    struct timeval tvrecv;
    ssize_t bpf_len = 0; //bpf receive len
    ArpingCallback arpingcallback = NULL;
    struct ijt_ether_arp_header sendetherarp;
    
    //if need callback
    if(target && selector) {
        arpingcallback = (ArpingCallback)[target methodForSelector:selector];
    }
    
    memcpy(&sendetherarp, &_sendetherarp, sizeof(sendetherarp));
    
    if(inet_pton(AF_INET, [whereto UTF8String], &sendetherarp.targetIP) == -1)
        goto BAD;
    
    //send
    gettimeofday(&tvsend, (struct timezone *)0);
    if((sizebuffer = write(self.bpfd, &sendetherarp, sizeof(sendetherarp))) < 0)
        goto BAD;
    
    if(sizebuffer != sizeof(sendetherarp))
        goto BAD;
    
    recvbuffer = malloc(_bpfbufsize);
    if(!recvbuffer)
        goto BAD;
    
    while(1) {
        struct timespec tv = {};
        tv.tv_sec = timeout / 1000;
        tv.tv_nsec = timeout % 1000 * 1000;
        struct bpf_hdr *bp = NULL; //bpf header
        char *p = NULL; //pointer to packet header start position
        int n = 0;
        fd_set readfd = {};
        
        FD_ZERO(&readfd);
        FD_SET(self.bpfd, &readfd);
        if((n = pselect(_bpfd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
            goto BAD;
        if(n == 0)
            goto TIMEOUT;
        
        if(!FD_ISSET(self.bpfd, &readfd))
            continue;
        
        memset(recvbuffer, 0, sizeof(_bpfbufsize));
        if((bpf_len = read(_bpfd, recvbuffer, _bpfbufsize)) < 0)
            goto BAD;
        bp = (struct bpf_hdr *)recvbuffer;
        
        //analyze each packet
        while(bpf_len > 0) {
            p = (char *)bp + bp->bh_hdrlen;
            
            gettimeofday(&tvrecv, (struct timezone *)0);
            //receive
            recvetherarp = (struct ijt_ether_arp_header *)p;
            
            if(recvetherarp->ether.ether_type == htons(ETHERTYPE_ARP) &&
               recvetherarp->ar_op == htons(ARPOP_REPLY) &&
               sendetherarp.targetIP.s_addr == recvetherarp->senderIP.s_addr &&
               sendetherarp.senderIP.s_addr == recvetherarp->targetIP.s_addr) {
                NSString *targetMac = [self ether_ntoa:&recvetherarp->senderEther];
                NSString *targetIp = [NSString stringWithUTF8String:inet_ntoa(recvetherarp->senderIP)];
                NSString *etherSource = [self ether_ntoa:((struct ether_addr *)recvetherarp->ether.ether_shost)];
                struct timeval tvrtt = tvsub(tvrecv, tvsend);
                double RTT = tvrtt.tv_sec * 1000.0 + tvrtt.tv_usec/1000.0;
                
                if(arpingcallback) {
                    arpingcallback(target, selector, tvrecv, RTT, targetIp, targetMac, etherSource, object);
                }
                else {
                    char timestr[16];
                    time_t local_tv_sec = tvrecv.tv_sec;
                    
                    strftime(timestr, sizeof timestr, "%H:%M:%S", localtime(&local_tv_sec));
                    
                    printf("At: %s.%.6d, IP: %s, MAC: %s, RTT: %8.4f ms\n",
                           timestr, tvrecv.tv_usec, [targetIp UTF8String], [targetMac UTF8String], RTT);
                }
                goto OK;
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
TIMEOUT:
    if(recvbuffer)
        free(recvbuffer);
    self.errorHappened = YES;
    return 1;
}

- (NSString *)ether_ntoa:(const struct ether_addr *)addr {
    return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", addr->octet[0], addr->octet[1], addr->octet[2], addr->octet[3], addr->octet[4], addr->octet[5]];
}

static struct timeval tvsub(struct timeval time1, struct timeval time2) {
    if ((time1.tv_usec -= time2.tv_usec) < 0)
    {
        time1.tv_sec--;
        time1.tv_usec += 1000000;
    }
    time1.tv_sec -= time2.tv_sec;
    return time1;
}
@end
