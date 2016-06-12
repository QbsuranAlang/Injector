//
//  IJTNetbios.m
//  IJTNetbios
//
//  Created by 聲華 陳 on 2015/3/31.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTNetbios.h"
#import <sys/socket.h>
#import <arpa/inet.h>
#import <netinet/ip.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/ioctl.h>
#import <netinet/if_ether.h>
#define NETBIOS_HDR_LEN 12
#define NETBIOS_ANSWER_LEN 45
struct ijt_netbios_answer_header {
    u_int8_t netbios_name[34];
    u_int16_t netbios_type;
    u_int16_t netbios_class;
    u_int32_t netbios_ttl;
    u_int16_t netbios_length;
    u_int8_t netbios_number;
}  __attribute__((packed));

struct ijt_netbios_header {
    u_int16_t netbios_id;
    u_int16_t netbios_flags;
    u_int16_t netbios_questions;
    u_int16_t netbios_answer;
    u_int16_t netbios_authority;
    u_int16_t netbios_additional;
}  __attribute__((packed));

/*netbios type*/
#define NETBIOS_NBSTAT 0x0021
/*netbios class*/
#define NETBIOS_CLASS 0x0001

@interface IJTNetbios ()

@property (nonatomic) int sockfd;
@property (nonatomic) in_addr_t startIP;
@property (nonatomic) in_addr_t endIP;
@property (nonatomic) in_addr_t currentIP;
@property (nonatomic) BOOL readUntilTimeout;

@end

@implementation IJTNetbios

- (id)init {
    self = [super init];
    if(self) {
        self.sockfd = -1;
        [self open];
    }
    return self;
}

- (void)open {
    int n = 1, len, maxbuf = -1;
    
    if(self.sockfd < 0) {
        self.sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if(self.sockfd < 0)
            goto BAD;
    }
    
    //enable broadcast
    n = 1;
    if (setsockopt(self.sockfd, SOL_SOCKET, SO_BROADCAST, &n, sizeof(n)) < 0)
        goto BAD;
    
    //send buffer
    len = sizeof(n);
    maxbuf = 1024*1024;
    
    if (getsockopt(self.sockfd, SOL_SOCKET, SO_SNDBUF, &n, (socklen_t *)&len) < 0)
        goto BAD;
    
    for (n += 1024; n <= maxbuf; n += 1024) {
        if (setsockopt(self.sockfd, SOL_SOCKET, SO_SNDBUF, &n, len) < 0) {
            if (errno == ENOBUFS)
                break;
            goto BAD;
        }
    }
    
    //receive buffer
    len = sizeof(n);
    maxbuf = 1024*1024;
    
    if (getsockopt(self.sockfd, SOL_SOCKET, SO_RCVBUF, &n, (socklen_t *)&len) < 0)
        goto BAD;
    
    for (n += 1024; n <= maxbuf; n += 1024) {
        if (setsockopt(self.sockfd, SOL_SOCKET, SO_RCVBUF, &n, len) < 0) {
            if (errno == ENOBUFS)
                break;
            goto BAD;
        }
    }
    
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
    if(self.sockfd >= 0) {
        close(self.sockfd);
        self.sockfd = -1;
    }
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

- (int)injectWithInterval: (useconds_t)interval {
    if(ntohl(_currentIP) > ntohl(_endIP))
        goto OK;
    
    struct sockaddr_in sin;
    char buffer[IP_MAXPACKET];
    struct ijt_netbios_header *netbios;
    struct ijt_netbios_answer_header *netbios_answer;
    ssize_t sizebuffer = 0;

    //clear
    memset(&sin, 0, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_len = sizeof(sin);
    sin.sin_port = htons(137); //netbios
    sin.sin_addr.s_addr = _currentIP;
    
    //clear
    memset(buffer, 0, sizeof(buffer));
    netbios = (struct ijt_netbios_header *)buffer;
    netbios->netbios_id = htons(arc4random());
    netbios->netbios_flags = 0;
    netbios->netbios_questions = htons(1);
    netbios->netbios_answer =
    netbios->netbios_authority =
    netbios->netbios_additional = htons(0);
    netbios_answer = (struct ijt_netbios_answer_header *)(buffer + NETBIOS_HDR_LEN);
    netbios_answer->netbios_name[0] = 0x20;
    netbios_answer->netbios_name[1] = 0x43;
    netbios_answer->netbios_name[2] = 0x4b;
    for(int i = 3 ; i < 33 ; i++) {
        netbios_answer->netbios_name[i] = 0x41;
    }
    
    netbios_answer->netbios_type = htons(NETBIOS_NBSTAT);
    netbios_answer->netbios_class = htons(NETBIOS_CLASS);
    
    sizebuffer = sendto(self.sockfd, buffer, 50, 0, (struct sockaddr *)&sin, (socklen_t)sizeof(sin));
    
    usleep(interval);
    if(sizebuffer != 50)
        goto BAD;
    
    _currentIP = htonl(ntohl(_currentIP) + 1);
    
OK:
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (u_int64_t)getTotalInjectCount {
    return (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_startIP) + 1;
}

- (u_int64_t)getRemainInjectCount {
    return (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_currentIP) + 1 <= 0 ? 0 : (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_currentIP) + 1;
}

- (int)readTimeout: (u_int32_t)timeout
            target: (id)target
          selector: (SEL)selector
            object: (id)object {
    NetbiosCallback netbioscallback = NULL;
    char buffer[IP_MAXPACKET];
    ssize_t sizebuffer = 0;
    //struct ijt_netbios_header *netbios;
    struct ijt_netbios_answer_header *netbios_answer;
    u_int8_t *netbios_data;
    
    //if need callback
    if(target && selector) {
        netbioscallback = (NetbiosCallback)[target methodForSelector:selector];
    }
    
    while(1) {
        int n;
        fd_set readfd;
        struct timespec tv = {};
        tv.tv_sec = timeout / 1000;
        tv.tv_nsec = timeout % 1000 * 1000;
        struct sockaddr_storage from;
        socklen_t addr_len = sizeof(from);
        
        FD_ZERO(&readfd);
        FD_SET(self.sockfd, &readfd);
        if((n = pselect(_sockfd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
            goto BAD;
        if(n == 0)
            break;
        
        if(!FD_ISSET(self.sockfd, &readfd))
            continue;
        
        memset(buffer, 0, sizeof(buffer));
        memset(&from, 0, sizeof(struct sockaddr_storage));
        if((sizebuffer = recvfrom(self.sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&from, &addr_len)) < 0)
            goto BAD;
        
        struct sockaddr_in *addr = (struct sockaddr_in *)&from;
        if(ntohs(addr->sin_port) != 137) {
            continue;
        }
        
        //netbios = (struct ijt_netbios_header *)buffer;
        netbios_answer = (struct ijt_netbios_answer_header *)(buffer + NETBIOS_HDR_LEN);
        //receive
        u_int8_t numberOfNames = netbios_answer->netbios_number;
        NSMutableArray *names = [[NSMutableArray alloc] init];
        NSMutableArray *groupNames = [[NSMutableArray alloc] init];
        NSString *unitID = @"";
        char ntop_buf[256];
        NSString *source = [NSString stringWithUTF8String:
                            inet_ntop(from.ss_family, &addr->sin_addr, ntop_buf, sizeof(ntop_buf))];
        netbios_data = (u_int8_t *)(buffer + NETBIOS_HDR_LEN + NETBIOS_ANSWER_LEN);
        
        for(u_int8_t i = 0 ; i < numberOfNames ; i++) {
            NSString *netbiosName = @"";
            BOOL space = NO;
            for(int j = 0 ; j < 16 ; j++, netbios_data++) {
                if(isgraph(*netbios_data)) {
                    netbiosName = [netbiosName stringByAppendingString:
                                   [NSString stringWithFormat:@"%c", *netbios_data]];
                }
                else if(!isspace(*netbios_data)) {
                    netbiosName = [netbiosName stringByAppendingString:
                                   [NSString stringWithFormat:@"<%02x>", *netbios_data]];
                }
                else if(j == 15 && isspace(*netbios_data)){
                    space = YES;
                }
                
            }
            if(space) {
                netbiosName = [netbiosName stringByAppendingString:@"<20>"];
            }
            netbiosName = [netbiosName stringByAppendingString:@"\0"];
            
            //name flags
            u_int16_t nameFlags = *(u_int16_t *)netbios_data;
            nameFlags = ntohs(nameFlags);
            netbios_data += 2;
            
            if(nameFlags & (1 << 15)) {
                [groupNames addObject:netbiosName];
            }
            else {
                [names addObject:netbiosName];
            }
        }
        
        unitID = [self ether_ntoa:((const struct ether_addr *)netbios_data)];
        if(netbioscallback) {
            netbioscallback(target, selector, names, groupNames, unitID, source, object);
        }
        else {
            //printf("NetbiosName: %s, UnitID: %s\n", [netbiosName UTF8String], [unitID UTF8String]);
            printf("Name:");
            for(NSUInteger i = 0 ; i < names.count ; i++) {
                printf(" %s", [names[i] UTF8String]);
            }
            printf(", Unit ID: %s\n", [unitID UTF8String]);
        }
        if(!_readUntilTimeout) {
            if([self getTotalInjectCount] == 1)
                break;
        }
    }//end while
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (NSString *)ether_ntoa:(const struct ether_addr *)addr {
    return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", addr->octet[0], addr->octet[1], addr->octet[2], addr->octet[3], addr->octet[4], addr->octet[5]];
}

- (void)setReadUntilTimeout: (BOOL)enable {
    _readUntilTimeout = enable;
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
