//
//  IJTPing.m
//  IJTPing
//
//  Created by 聲華 陳 on 2015/6/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTPing.h"
#import <sys/socket.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <sys/time.h>
#import <sys/sysctl.h>
#import <netinet/ip.h>
#import <netinet/in.h>
#import <netinet/in_systm.h>
#import <netinet/ip_icmp.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <netdb.h>

#define MAX_IPOPTLEN 40
@interface IJTPing ()

@property (nonatomic) int sockfd;
@property (nonatomic) u_short icmpID;
@property (nonatomic, strong) NSString *hostname;
@property (nonatomic) struct sockaddr_in sin;
@property (nonatomic) BOOL isbroadcast;

@property (nonatomic) int bpfd;

@end

@implementation IJTPing

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
        self.sockfd = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);
        if(self.sockfd < 0)
            goto BAD;
    }
    
    //custom ip header
    if (setsockopt(self.sockfd, IPPROTO_IP, IP_HDRINCL, &n, sizeof(n)) < 0)
        goto BAD;
    
    //send buffer
    len = sizeof(n);
    maxbuf = 1024*1024;
    
    if (getsockopt(self.sockfd, SOL_SOCKET, SO_SNDBUF, &n, (socklen_t *)&len) < 0)
        goto BAD;
    
    for (n += 1024; n < maxbuf; n += 1024) {
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
    
    //enable broadcast
    n = 1;
    if (setsockopt(self.sockfd, SOL_SOCKET, SO_BROADCAST, &n, sizeof(n)) < 0)
        goto BAD;
    
    self.icmpID = 1;
    self.hostname = @"";
    
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

- (int)setTarget: (NSString *)target {
    struct hostent *hp;
    char hnamebuf[MAXHOSTNAMELEN];
    
    //clear
    memset(&_sin, 0, sizeof(_sin));
    _sin.sin_family = AF_INET;
    _sin.sin_len = sizeof(_sin);
    
    //resolve hostname
    if (inet_aton([target UTF8String], &_sin.sin_addr) != 0) { //ip address
        self.hostname = target;
    }
    else {//hostname
        hp = gethostbyname2([target UTF8String], AF_INET);
        if (!hp)
            goto HOSTBAD;
        if ((unsigned)hp->h_length > sizeof(_sin.sin_addr))
            goto HOSTBAD;
        
        memcpy(&_sin.sin_addr, hp->h_addr_list[0], sizeof _sin.sin_addr);
        (void)strncpy(hnamebuf, hp->h_name, sizeof(hnamebuf) - 1);
        hnamebuf[sizeof(hnamebuf) - 1] = '\0';
        self.hostname = [NSString stringWithUTF8String:hnamebuf];
    }
    
    self.isbroadcast = NO;
    
    if([target isEqualToString:@"255.255.255.255"]) {
        self.isbroadcast = YES;
    }
    else {
        //try to get broadcast address
        struct ifreq ifr;
        int s = socket(AF_INET, SOCK_DGRAM, 0);
        int bcast;
        if(s > 0) {
            strlcpy(ifr.ifr_name, "en0", sizeof(ifr.ifr_name));
            if (ioctl(s, SIOCGIFBRDADDR, &ifr) == 0) {
                bcast = ((struct sockaddr_in *)(&ifr.ifr_broadaddr))->sin_addr.s_addr;
                if(bcast == _sin.sin_addr.s_addr)
                    self.isbroadcast = YES;
            }//end if
            close(s);
        }
    }
    
OK:
    self.errorHappened = NO;
    return 0;
HOSTBAD:
    self.errorCode = h_errno;
    self.errorHappened = YES;
    return -2;
}

- (int)pingWithTtl: (u_int8_t)ttl
               tos: (IJTPingTos)tos
          fragment: (BOOL)fragment
           timeout: (u_int32_t)timeout
          sourceIP: (NSString *)sourceIP
              fake: (BOOL)fake
       recordRoute: (BOOL)recordRoute
       payloadSize: (u_int32_t)payloadSize
            target: (id)target
          selector: (SEL)selector
            object: (id)object
      recordTarget: (id)recordTarget
    recordSelector: (SEL)recordSelector
      recordObject: (id)recorObject {
    ssize_t sizelen = 0;
    char buffer[IP_MAXPACKET];
    struct ip *ip;
    struct icmp *icmp;
    struct timeval tvsend;
    struct timeval tvrecv;
    PingCallback pingcallback = NULL;
    PingRecordTypeCallback pingrecordtypecallback = NULL;
    struct in_addr source;
    char rspace[MAX_IPOPTLEN];
    
    //if need callback
    if(target && selector) {
        pingcallback = (PingCallback)[target methodForSelector:selector];
    }
    
    if(recordTarget && recordSelector) {
        pingrecordtypecallback = (PingRecordTypeCallback)[recordTarget methodForSelector:recordSelector];
    }
    
    if(inet_aton([sourceIP UTF8String], &source) == 0)
        goto BAD;
    int mtu = 0;
    
    //get mtu
    int s = socket(AF_INET, SOCK_STREAM, 0);
    struct ifreq ifr;
    if(s > 0) {
        strlcpy(ifr.ifr_name, "en0", sizeof(ifr.ifr_name));
        if (ioctl(s, SIOCGIFADDR, &ifr) == 0) {
            if(ioctl(s, SIOCGIFMTU, &ifr) != 0) {
                goto BAD;
            }
            
            if(fake) {
                mtu = ifr.ifr_mtu;
            }
            else if(source.s_addr == ((struct sockaddr_in *)(&ifr.ifr_addr))->sin_addr.s_addr) {
                mtu = ifr.ifr_mtu;
            }
        }//end if
        else if(errno == EADDRNOTAVAIL) { //wifi not connected
            strlcpy(ifr.ifr_name, "pdp_ip0", sizeof(ifr.ifr_name));
            if (ioctl(s, SIOCGIFADDR, &ifr) == 0) {
                if(ioctl(s, SIOCGIFMTU, &ifr) != 0) {
                    goto BAD;
                }
                
                if(fake) {
                    mtu = ifr.ifr_mtu;
                }
                else if(source.s_addr == ((struct sockaddr_in *)(&ifr.ifr_addr))->sin_addr.s_addr) {
                    mtu = ifr.ifr_mtu;
                }
            }//end if
            else {
                if(errno == ENXIO) //pdp_ip0 doesn't exsit
                    errno = EADDRNOTAVAIL;
                goto BAD;
            }
        }
    }
    else {
        goto BAD;
    }
    close(s);
    s = -1;
    
    //clear
    memset(buffer, 0, sizeof(buffer));
    
    gettimeofday(&tvsend, (struct timezone *)0);
    int ip_id = arc4random();
    int i = 0;
    do {
        char buffer[65535];
        ssize_t sizelen;
        memset(buffer, 0, sizeof(buffer));
        struct ip *ip = (struct ip *)buffer;
        
        ip->ip_v = IPVERSION;
        ip->ip_tos = tos;
        ip->ip_id = ip_id;
        ip->ip_hl = sizeof(struct ip) >> 2;
        ip->ip_ttl = ttl;
        ip->ip_p = IPPROTO_ICMP;
        ip->ip_src.s_addr = source.s_addr;
        ip->ip_dst.s_addr = _sin.sin_addr.s_addr;
        
        if(i + (mtu - sizeof(struct ip)) > payloadSize) { //final one
            ip->ip_len = payloadSize - i + ICMP_MINLEN + sizeof(struct ip);
            ip->ip_off = 0 | (i >> 3);
        }
        else {
            ip->ip_len = mtu;
            ip->ip_off = IP_MF | (i >> 3);
        }
        
        ip->ip_sum = checksum((u_short *)ip, ip->ip_hl << 2);
        
        //icmp header
        struct icmp *icmp = (struct icmp *)(buffer + (ip->ip_hl << 2));
        icmp->icmp_type = ICMP_ECHO;
        icmp->icmp_code = 0;
        icmp->icmp_id = htons(_icmpID);
        icmp->icmp_seq = _icmpID;
        icmp->icmp_cksum = checksum((u_short *)icmp, ip->ip_len - (ip->ip_hl << 2));
        
        if((sizelen = sendto(self.sockfd, buffer, ip->ip_len, 0, (struct sockaddr *)&_sin, (socklen_t)sizeof(_sin))) < 0)
            goto BAD;
        usleep(100);
        i += mtu - sizeof(struct ip);
    } while (i < payloadSize);

    //ip header
    /*
    ip = (struct ip *)buffer;
    ip->ip_v = IPVERSION;
    if(recordRoute) {
        bzero(rspace, sizeof(rspace));
        rspace[IPOPT_OPTVAL] = IPOPT_RR;
        rspace[IPOPT_OLEN] = sizeof(rspace) - 1;
        rspace[IPOPT_OFFSET] = IPOPT_MINOFF;
        rspace[sizeof(rspace) - 1] = IPOPT_EOL;
        memcpy(&buffer[sizeof(struct ip)], rspace, sizeof(rspace));
        ip->ip_hl = (MAX_IPOPTLEN + sizeof(struct ip)) >> 2;
    }
    else {
        ip->ip_hl = sizeof(struct ip) >> 2;
    }
    ip->ip_tos = tos;
    ip->ip_id = 0;
    ip->ip_ttl = ttl;
    ip->ip_p = IPPROTO_ICMP;
    ip->ip_src.s_addr = source.s_addr;
    ip->ip_dst.s_addr = _sin.sin_addr.s_addr;
    */
    /**
     *http://cseweb.ucsd.edu/~braghava/notes/freebsd-sockets.txt
     *FreeBSD bug
     *- ip_len and ip_off must be in host byte order
     */
    /*
    ip->ip_len = (ip->ip_hl << 2) + ICMP_MINLEN + payload;
    ip->ip_off = fragment ? 0 : IP_DF;
    ip->ip_sum = checksum((u_short *)ip, ip->ip_hl << 2);
    sendlen = ip->ip_len;
    //icmp echo header
    icmp = (struct icmp *)(buffer + (ip->ip_hl << 2));
    icmp->icmp_type = ICMP_ECHO;
    icmp->icmp_code = 0;
    icmp->icmp_id = htons(self.icmpID);
    icmp->icmp_seq = self.icmpID;
    icmp->icmp_cksum = checksum((u_short *)icmp, ICMP_MINLEN + payload);

    gettimeofday(&tvsend, (struct timezone *)0);
    if((sizelen = sendto(self.sockfd, buffer, sendlen, 0, (struct sockaddr *)&_sin, (socklen_t)sizeof(_sin))) < 0)
        goto BAD;
    
    if(sizelen != ip->ip_len)
        goto BAD;
    */
    if(fake)
        goto FAKE;
    
    //ready to read
    u_int32_t recvlen = 0;
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
        if((n = pselect(self.sockfd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
            goto BAD;
        if(n == 0) {
            goto TIMEOUT;
        }
        
        if(!FD_ISSET(self.sockfd, &readfd))
            continue;
        
        memset(buffer, 0, sizeof(buffer));
        memset(&from, 0, sizeof(struct sockaddr_storage));
        if((sizelen = recvfrom(self.sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&from, &addr_len)) < 0)
            goto BAD;
        
        //receive
        gettimeofday(&tvrecv, (struct timezone *)0);
        
        ip = (struct ip *)buffer;
        icmp = (struct icmp *)(buffer + (ip->ip_hl << 2));
        
        if(ip->ip_p != IPPROTO_ICMP || ntohs(icmp->icmp_id) != self.icmpID)
            continue;
        if(ip->ip_off & IP_MF) {
            recvlen += sizelen - (ip->ip_hl << 2);
            continue;
        }
        recvlen += sizelen - (ip->ip_hl << 2);
        
        char ntop_buf[256];
        NSString *sourceIpAddress = [NSString stringWithUTF8String:
                            inet_ntop(from.ss_family, &((struct sockaddr_in *)&from)->sin_addr, ntop_buf, sizeof(ntop_buf))];
        struct timeval tvrtt = tvsub(tvrecv, tvsend);
        double RTT = tvrtt.tv_sec * 1000.0 + tvrtt.tv_usec/1000.0;
        
        if(recordRoute) {
            memset(rspace, 0, sizeof(rspace));
            
            memcpy(rspace, &buffer[sizeof(struct ip)],
                   (ip->ip_hl << 2) - sizeof(struct ip));
            if(rspace[IPOPT_OPTVAL] == IPOPT_RR) {
                struct in_addr inaddr;
                NSMutableArray *recordIps = [[NSMutableArray alloc] init];
                for(u_long *addr = (u_long *)(rspace + 3) ; *addr ; addr += 1) {
                    inaddr.s_addr = (in_addr_t)*addr;
                    NSString *recordIp = [NSString stringWithUTF8String:inet_ntoa(inaddr)];
                    [recordIps addObject:recordIp];
                }
                
                if(pingrecordtypecallback) {
                    pingrecordtypecallback(recordTarget, recordSelector, tvrecv,
                                           [NSString stringWithUTF8String:inet_ntoa(ip->ip_src)],
                                           recordIps, object);
                }
                else {
                    printf("%s: ", inet_ntoa(ip->ip_src));
                    for(NSString *ip in recordIps) {
                        printf("%s ", [ip UTF8String]);
                    }
                    printf("\n");
                }
            }
        }
        else {
            if(pingcallback) {
                pingcallback(target, selector, tvrecv, _hostname, sourceIpAddress, RTT, icmp->icmp_type, icmp->icmp_code, recvlen, object);
            }
            else {
                char timestr[16];
                time_t local_tv_sec = tvrecv.tv_sec;
                
                strftime(timestr, sizeof timestr, "%H:%M:%S", localtime(&local_tv_sec));
                
                printf("At: %s.%.6d, IP: %s, Target: %s, RTT: %8.4f ms, len: %zd\n",
                       timestr, tvrecv.tv_usec, [sourceIpAddress UTF8String], [_hostname UTF8String], RTT, recvlen);
                pr_icmph(icmp);
            }
        }
        
        if(self.isbroadcast)
            continue;
        else
            break;
        
    }//end while
    
    _icmpID++;
OK:
    if(s >= 0)
        close(s);
    self.icmpID++;
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(s >= 0)
        close(s);
    self.errorHappened = YES;
    return -1;
TIMEOUT:
    if(self.isbroadcast) {
        goto OK;
    }
    else {
        if(s >= 0)
            close(s);
        self.errorHappened = YES;
        return 1;
    }
FAKE:
    if(s >= 0)
        close(s);
    self.errorHappened = NO;
    return 2;
}

static void pr_icmph(struct icmp *icp) {
    switch(icp->icmp_type) {
        case ICMP_ECHOREPLY:
            (void)printf("Echo Reply\n");
            /* XXX ID + Seq + Data */
            break;
        case ICMP_UNREACH:
            switch(icp->icmp_code) {
                case ICMP_UNREACH_NET:
                    (void)printf("Destination Net Unreachable\n");
                    break;
                case ICMP_UNREACH_HOST:
                    (void)printf("Destination Host Unreachable\n");
                    break;
                case ICMP_UNREACH_PROTOCOL:
                    (void)printf("Destination Protocol Unreachable\n");
                    break;
                case ICMP_UNREACH_PORT:
                    (void)printf("Destination Port Unreachable\n");
                    break;
                case ICMP_UNREACH_NEEDFRAG:
                    (void)printf("frag needed and DF set (MTU %d)\n",
                                 ntohs(icp->icmp_nextmtu));
                    break;
                case ICMP_UNREACH_SRCFAIL:
                    (void)printf("Source Route Failed\n");
                    break;
                case ICMP_UNREACH_FILTER_PROHIB:
                    (void)printf("Communication prohibited by filter\n");
                    break;
                default:
                    (void)printf("Dest Unreachable, Bad Code: %d\n",
                                 icp->icmp_code);
                    break;
            }
            break;
        case ICMP_SOURCEQUENCH:
            (void)printf("Source Quench\n");
            break;
        case ICMP_REDIRECT:
            switch(icp->icmp_code) {
                case ICMP_REDIRECT_NET:
                    (void)printf("Redirect Network");
                    break;
                case ICMP_REDIRECT_HOST:
                    (void)printf("Redirect Host");
                    break;
                case ICMP_REDIRECT_TOSNET:
                    (void)printf("Redirect Type of Service and Network");
                    break;
                case ICMP_REDIRECT_TOSHOST:
                    (void)printf("Redirect Type of Service and Host");
                    break;
                default:
                    (void)printf("Redirect, Bad Code: %d", icp->icmp_code);
                    break;
            }
            (void)printf("(New addr: %s)\n", inet_ntoa(icp->icmp_gwaddr));
            break;
        case ICMP_ECHO:
            (void)printf("Echo Request\n");
            /* XXX ID + Seq + Data */
            break;
        case ICMP_TIMXCEED:
            switch(icp->icmp_code) {
                case ICMP_TIMXCEED_INTRANS:
                    (void)printf("Time to live exceeded\n");
                    break;
                case ICMP_TIMXCEED_REASS:
                    (void)printf("Frag reassembly time exceeded\n");
                    break;
                default:
                    (void)printf("Time exceeded, Bad Code: %d\n",
                                 icp->icmp_code);
                    break;
            }
            break;
        case ICMP_PARAMPROB:
            (void)printf("Parameter problem: pointer = 0x%02x\n",
                         icp->icmp_hun.ih_pptr);
            break;
        case ICMP_TSTAMP:
            (void)printf("Timestamp\n");
            /* XXX ID + Seq + 3 timestamps */
            break;
        case ICMP_TSTAMPREPLY:
            (void)printf("Timestamp Reply\n");
            /* XXX ID + Seq + 3 timestamps */
            break;
        case ICMP_IREQ:
            (void)printf("Information Request\n");
            /* XXX ID + Seq */
            break;
        case ICMP_IREQREPLY:
            (void)printf("Information Reply\n");
            /* XXX ID + Seq */
            break;
        case ICMP_MASKREQ:
            (void)printf("Address Mask Request\n");
            break;
        case ICMP_MASKREPLY:
            (void)printf("Address Mask Reply\n");
            break;
        case ICMP_ROUTERADVERT:
            (void)printf("Router Advertisement\n");
            break;
        case ICMP_ROUTERSOLICIT:
            (void)printf("Router Solicitation\n");
            break;
        default:
            (void)printf("Bad ICMP type: %d\n", icp->icmp_type);
    }
}

static u_int16_t checksum(u_int16_t *data, int len) {
    u_int32_t sum = 0;
    
    for (; len > 1; len -= 2) {
        sum += *data++;
        if (sum & 0x80000000)
            sum = (sum & 0xffff) + (sum >> 16);
    }
    
    if (len == 1) {
        u_int16_t i = 0;
        *(u_char*) (&i) = *(u_char *) data;
        sum += i;
    }
    
    while (sum >> 16)
        sum = (sum & 0xffff) + (sum >> 16);
    
    return ~sum;
}

static struct timeval tvsub(struct timeval time1, struct timeval time2) {
    if ((time1.tv_usec -= time2.tv_usec) < 0) {
        time1.tv_sec--;
        time1.tv_usec += 1000000;
    }
    time1.tv_sec -= time2.tv_sec;
    return time1;
}

- (int)injectWithInterval: (useconds_t)interval {
    ssize_t sizelen = 0;
    char buffer[IP_MAXPACKET];
    struct ip *ip;
    struct icmp *icmp;
    struct timeval tvsend;
    struct in_addr source;
    int sendlen = 0;
    int payload = 10;
    
    
    source.s_addr = INADDR_ANY;
    //clear
    memset(buffer, 0, sizeof(buffer));
    
    //ip header
    ip = (struct ip *)buffer;
    ip->ip_v = IPVERSION;
    ip->ip_hl = sizeof(struct ip) >> 2;
    ip->ip_tos = 0;
    ip->ip_id = arc4random();
    ip->ip_ttl = 255;
    ip->ip_p = IPPROTO_ICMP;
    ip->ip_src.s_addr = source.s_addr;
    ip->ip_dst.s_addr = _sin.sin_addr.s_addr;
    /**
     *http://cseweb.ucsd.edu/~braghava/notes/freebsd-sockets.txt
     *FreeBSD bug
     *- ip_len and ip_off must be in host byte order
     */
    ip->ip_len = (ip->ip_hl << 2) + ICMP_MINLEN + payload;
    ip->ip_off = 0;
    ip->ip_sum = checksum((u_short *)ip, ip->ip_hl << 2);
    sendlen = ip->ip_len;
    //icmp echo header
    icmp = (struct icmp *)(buffer + (ip->ip_hl << 2));
    icmp->icmp_type = ICMP_ECHO;
    icmp->icmp_code = 0;
    icmp->icmp_id = htons(self.icmpID);
    icmp->icmp_seq = self.icmpID;
    icmp->icmp_cksum = checksum((u_short *)icmp, ICMP_MINLEN + payload);
    
    gettimeofday(&tvsend, (struct timezone *)0);
    if((sizelen = sendto(self.sockfd, buffer, sendlen, 0, (struct sockaddr *)&_sin, (socklen_t)sizeof(_sin))) < 0)
        goto BAD;
    
    if(sizelen != ip->ip_len)
        goto BAD;
    
    usleep(interval);
OK:
    self.icmpID++;
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
    ssize_t sizelen = 0;
    char buffer[IP_MAXPACKET];
    struct ip *ip;
    struct icmp *icmp;
    struct timeval tvrecv;
    PingCallback pingcallback = NULL;
    
    //if need callback
    if(target && selector) {
        pingcallback = (PingCallback)[target methodForSelector:selector];
    }
    //ready to read
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
        if((n = pselect(self.sockfd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
            goto BAD;
        if(n == 0) {
            goto TIMEOUT;
        }
        
        if(!FD_ISSET(self.sockfd, &readfd))
            continue;
        
        memset(buffer, 0, sizeof(buffer));
        memset(&from, 0, sizeof(struct sockaddr_storage));
        if((sizelen = recvfrom(self.sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&from, &addr_len)) < 0)
            goto BAD;
        
        //receive
        gettimeofday(&tvrecv, (struct timezone *)0);
        
        ip = (struct ip *)buffer;
        icmp = (struct icmp *)(buffer + (ip->ip_hl << 2));
        
        if(ip->ip_p != IPPROTO_ICMP && (ip->ip_off & IP_MF))
            continue;
        
        char ntop_buf[256];
        NSString *sourceIpAddress = [NSString stringWithUTF8String:
                                     inet_ntop(from.ss_family, &((struct sockaddr_in *)&from)->sin_addr, ntop_buf, sizeof(ntop_buf))];
        
        struct timeval empty = {};
        if(pingcallback) {
            pingcallback(target, selector, empty, _hostname, sourceIpAddress, -1.0, icmp->icmp_type, icmp->icmp_code, ip->ip_len, object);
        }
        else {
            char timestr[16];
            time_t local_tv_sec = tvrecv.tv_sec;
            
            strftime(timestr, sizeof timestr, "%H:%M:%S", localtime(&local_tv_sec));
            
            printf("At: %s.%.6d, IP: %s, Target: %s, RTT: %8.4f ms, len: %zd\n",
                   timestr, tvrecv.tv_usec, [sourceIpAddress UTF8String], [_hostname UTF8String], -1.0f, sizelen);
            pr_icmph(icmp);
        }
        
    }//end while
    
    
OK:
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
TIMEOUT:
    if(self.isbroadcast) {
        goto OK;
    }
    else {
        self.errorHappened = YES;
        return 1;
    }
}
@end

