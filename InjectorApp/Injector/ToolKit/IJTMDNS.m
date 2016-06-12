//
//  IJTMDNS.m
//  IJTMDNS
//
//  Created by 聲華 陳 on 2015/8/15.
//
//

#import "IJTMDNS.h"
#import <netinet/ip.h>
#import <arpa/inet.h>
#import <resolv.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <net/if_dl.h>

struct ijt_mdns_header
{
    unsigned short mdns_id; // identification number
    
    unsigned char mdns_rd :1; // recursion desired
    unsigned char mdns_tc :1; // truncated message
    unsigned char mdns_aa :1; // authoritive answer
    unsigned char mdns_opcode :4; // purpose of message
    unsigned char mdns_qr :1; // query/response flag
    
    unsigned char mdns_rcode :4; // response code
    unsigned char mdns_cd :1; // checking disabled
    unsigned char mdns_ad :1; // authenticated data
    unsigned char mdns_z :1; // its z! reserved
    unsigned char mdns_ra :1; // recursion available
    
    unsigned short mdns_q_count; // number of question entries
    unsigned short mdns_ans_count; // number of answer entries
    unsigned short mdns_auth_count; // number of authority entries
    unsigned short mdns_add_count; // number of resource entries
};

//Constant sized fields of query structure
struct ijt_mdns_question
{
    unsigned short qtype;
    unsigned short qclass;
};

//Constant sized fields of the resource record structure
#pragma pack(push, 1)
struct R_DATA
{
    unsigned short type;
    unsigned short _class;
    unsigned int ttl;
    unsigned short data_len;
};
#pragma pack(pop)

//Pointers to resource record contents
struct ijt_mdns_record
{
    unsigned char *name;
    struct R_DATA *resource;
    unsigned char *rdata;
};

@interface IJTMDNS ()

@property (nonatomic) int sockfd;
@property (nonatomic) in_addr_t startIP;
@property (nonatomic) in_addr_t endIP;
@property (nonatomic) in_addr_t currentIP;
@property (nonatomic) BOOL readUntilTimeout;

@end

@implementation IJTMDNS

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
    
    if (self.sockfd < 0) {
        self.sockfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if (self.sockfd < 0)
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
    
    struct sockaddr_in dst;
    char buffer[IP_MAXPACKET];
    struct ijt_mdns_header *mdns = (struct ijt_mdns_header *)buffer;
    struct ijt_mdns_question *mdnsquestion = NULL;
    char *nameQuery = (char *)&buffer[sizeof(struct ijt_mdns_header)];
    ssize_t sizelen = 0;
    int mdnsid = arc4random();
    in_addr_t nowIp = ntohl(_currentIP);
    NSString *hostname = @"";
    char ntop_buf[256];
    
    if(ntohl(_currentIP) > ntohl(_endIP))
        goto OK;
    
    memset(&dst, 0, sizeof(dst));
    memset(buffer, 0, sizeof(buffer));
    
    dst.sin_family = AF_INET;
    dst.sin_port = htons(5353);
    inet_pton(AF_INET, [MDNS_MULTICAST_ADDR UTF8String], &dst.sin_addr);
    
    mdns->mdns_id = (unsigned short) htons(mdnsid);
    mdns->mdns_qr = 0; //This is a query
    mdns->mdns_opcode = 0; //This is a standard query
    mdns->mdns_aa = 0; //Not Authoritative
    mdns->mdns_tc = 0; //This message is not truncated
    mdns->mdns_rd = 1; //Recursion Desired
    mdns->mdns_ra = 0; //Recursion not available! hey we dont have it (lol)
    mdns->mdns_z = 0;
    mdns->mdns_ad = 0;
    mdns->mdns_cd = 0;
    mdns->mdns_rcode = 0;
    mdns->mdns_q_count = htons(1); //we have only 1 question
    mdns->mdns_ans_count = 0;
    mdns->mdns_auth_count = 0;
    mdns->mdns_add_count = 0;
    
    inet_ntop(AF_INET, &nowIp, ntop_buf, sizeof(ntop_buf));
    hostname = [NSString stringWithFormat:@"%s.in-addr.arpa", ntop_buf];
    
    changetoDnsNameFormat((unsigned char *)nameQuery, (const unsigned char *)[hostname UTF8String]);
    
    mdnsquestion = (struct ijt_mdns_question *)
    &buffer[sizeof(struct ijt_mdns_header) + strlen(nameQuery) + 1];
    
    mdnsquestion->qtype = htons(ns_t_ptr);
    mdnsquestion->qclass = htons(1);
    
    if((sizelen = sendto(self.sockfd, buffer,
                         sizeof(struct ijt_mdns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_mdns_question),
                         0, (struct sockaddr*)&dst,sizeof(dst))) < 0) {
        goto BAD;
    }
    
    usleep(interval);
    if(sizelen != sizeof(struct ijt_mdns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_mdns_question))
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

- (int)readTimeout: (u_int32_t)timeout
            target: (id)target
          selector: (SEL)selector
            object: (id)object {
    MDNSPTRCallback mdnsptrcallback = NULL;
    char buffer[IP_MAXPACKET];
    ssize_t sizebuffer = 0;
    
    //if need callback
    if(target && selector) {
        mdnsptrcallback = (MDNSPTRCallback)[target methodForSelector:selector];
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
        if(ntohs(addr->sin_port) != 5353) {
            continue;
        }
        
        ns_msg handle;
        ns_initparse((const u_char *)buffer, sizebuffer, &handle);
        
        for(int i = 0 ; i < ns_msg_count(handle, ns_s_an) ; i++) {
            ns_rr rr;
            if(ns_parserr(&handle, ns_s_an, i, &rr) == 0) {
                NSString *resolvehostname = [self dnsNameToString:(char *)ns_rr_rdata(rr)];
                NSString *name = [NSString stringWithUTF8String:ns_rr_name(rr)];
                char ntop_buf[256];
                NSString *source = [NSString stringWithUTF8String:
                                    inet_ntop(from.ss_family, &addr->sin_addr, ntop_buf, sizeof(ntop_buf))];
                if(mdnsptrcallback) {
                    mdnsptrcallback(target, selector, resolvehostname, name, source, object);
                }
                else {
                    printf("%s(%s) ==> %s\n", [name UTF8String], [source UTF8String], [resolvehostname UTF8String]);
                }
            }
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

- (void)setReadUntilTimeout: (BOOL)enable {
    _readUntilTimeout = enable;
}

- (int)hostname2IpAddress: (NSString *)hostname
                   family: (sa_family_t)family
                  timeout: (u_int32_t)timeout
                   target: (id)target
                 selector: (SEL)selector
                   object: (id)object {
    struct sockaddr_in dst;
    char buffer[IP_MAXPACKET];
    struct ijt_mdns_header *mdns = (struct ijt_mdns_header *)buffer;
    struct ijt_mdns_question *mdnsquestion = NULL;
    char *nameQuery = (char *)&buffer[sizeof(struct ijt_mdns_header)];
    ssize_t sizelen = 0;
    ns_type type = (family == AF_INET ? ns_t_a : (family == AF_INET6 ? ns_t_aaaa : 0));
    MDNSCallback mdnscallback = NULL;
    int count = 0;
    
    //if need callback
    if(target && selector) {
        mdnscallback = (MDNSCallback)[target methodForSelector:selector];
    }
    
    memset(&dst, 0, sizeof(dst));
    memset(buffer, 0, sizeof(buffer));
    
    dst.sin_family = AF_INET;
    dst.sin_port = htons(5353);
    dst.sin_addr.s_addr = inet_addr("224.0.0.251");
    
    mdns->mdns_id = (unsigned short)htons(arc4random());
    mdns->mdns_qr = 0; //This is a query
    mdns->mdns_opcode = 0; //This is a standard query
    mdns->mdns_aa = 0; //Not Authoritative
    mdns->mdns_tc = 0; //This message is not truncated
    mdns->mdns_rd = 1; //Recursion Desired
    mdns->mdns_ra = 0; //Recursion not available! hey we dont have it (lol)
    mdns->mdns_z = 0;
    mdns->mdns_ad = 0;
    mdns->mdns_cd = 0;
    mdns->mdns_rcode = 0;
    mdns->mdns_q_count = htons(1); //we have only 1 question
    mdns->mdns_ans_count = 0;
    mdns->mdns_auth_count = 0;
    mdns->mdns_add_count = 0;
    
    changetoDnsNameFormat((unsigned char *)nameQuery,
                          (const unsigned char *)[hostname UTF8String]);
    
    mdnsquestion = (struct ijt_mdns_question *)
    &buffer[sizeof(struct ijt_mdns_header) + strlen(nameQuery) + 1];
    
    mdnsquestion->qtype = htons(type);
    mdnsquestion->qclass = htons(1);
    
    if((sizelen = sendto(self.sockfd, buffer,
                         sizeof(struct ijt_mdns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_mdns_question),
                         0, (struct sockaddr*)&dst,sizeof(dst))) < 0) {
        goto BAD;
    }
    
    if(sizelen != sizeof(struct ijt_mdns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_mdns_question))
        goto BAD;
    
    while(1) {
        int n;
        fd_set readfd;
        struct timespec tv = {};
        tv.tv_sec = timeout / 1000;
        tv.tv_nsec = timeout % 1000 * 1000;
        
        FD_ZERO(&readfd);
        FD_SET(self.sockfd, &readfd);
        if((n = pselect(_sockfd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
            goto BAD;
        if(n == 0) {
            goto TIMEOUT;
        }
        
        if(!FD_ISSET(self.sockfd, &readfd))
            continue;
        
        memset(buffer, 0, sizeof(buffer));
        
        if((sizelen = recvfrom(self.sockfd, buffer, sizeof(buffer), 0, NULL, NULL)) < 0)
            goto BAD;
        
        ns_msg handle;
        ns_initparse((const u_char *)buffer, sizelen, &handle);
        
        if(ns_msg_count(handle, ns_s_an) == 0)
            goto NORESPONSE;
        
        for(int i = 0 ; i < ns_msg_count(handle, ns_s_an) ; i++) {
            ns_rr rr;
            if(ns_parserr(&handle, ns_s_an, i, &rr) == 0) {
                NSString *ipAddress = @"";
                char ntop_buf[256];
                NSString *name = [NSString stringWithUTF8String:ns_rr_name(rr)];
                
                if(type == ns_t_a) {
                    struct in_addr *addr = (struct in_addr *)ns_rr_rdata(rr);
                    inet_ntop(AF_INET, addr, ntop_buf, sizeof(ntop_buf));
                    ipAddress = [NSString stringWithUTF8String:ntop_buf];
                    if(mdnscallback) {
                        mdnscallback(target, selector, name, ipAddress, AF_INET, object);
                    }
                }
                else if(type == ns_t_aaaa) {
                    struct in6_addr *addr = (struct in6_addr *)ns_rr_rdata(rr);
                    inet_ntop(AF_INET6, addr, ntop_buf, sizeof(ntop_buf));
                    ipAddress = [NSString stringWithUTF8String:ntop_buf];
                    if(mdnscallback) {
                        mdnscallback(target, selector, name, ipAddress, AF_INET6, object);
                    }
                }
                
                if(!mdnscallback) {
                    printf("%s ==> %s\n", [name UTF8String], [ipAddress UTF8String]);
                }
                count++;
            }
        }//end for
        break;
    }//end while
    
    if(count == 0)
        goto NORESPONSE;
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
TIMEOUT:
    self.errorHappened = YES;
    return 1;
NORESPONSE:
    self.errorHappened = YES;
    return -2;
}

- (NSString *)dnsNameToString: (char *)rawdata {
    NSString *buffer = [NSString stringWithUTF8String:rawdata];
    NSString *result = @"";
    for(NSUInteger i = 0 ; i < buffer.length ; ) {
        unichar len = [buffer characterAtIndex:i];
        if(len == 0)
            break;
        if(result.length <= 0) {
            result = [buffer substringWithRange:NSMakeRange(i+1, len)];
        }
        else {
            result = [result stringByAppendingString:[NSString stringWithFormat:@".%@",
                                                      [buffer substringWithRange:NSMakeRange(i+1, len)]]];
        }
        i += len + 1;
    }
    
    return result;
}

static void changetoDnsNameFormat(unsigned char *dns, const unsigned char *host)
{
    int lock = 0, i;
    char buffer[256];
    snprintf(buffer, sizeof(buffer), "%s.", host);
    
    for(i = 0 ; i < strlen((char*)buffer) ; i++) {
        if(buffer[i] == '.') {
            *dns++ = i-lock;
            for(; lock < i ; lock++) {
                *dns++ = buffer[lock];
            }
            lock++; //or lock=i+1;
        }
    }
    *dns++='\0';
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

- (u_int64_t)getTotalInjectCount {
    return (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_startIP) + 1;
}

- (u_int64_t)getRemainInjectCount {
    return (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_currentIP) + 1 <= 0 ? 0 : (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_currentIP) + 1;
}
@end
