//
//  IJTDNS.m
//  IJTDNS
//
//  Created by 聲華 陳 on 2015/6/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTDNS.h"
#import <arpa/inet.h>
#import <resolv.h>
#import <netdb.h>
#import <netinet/ip.h>

//
//http://www.binarytides.com/dns-query-code-in-c-with-linux-sockets/
//http://www.software7.com/blog/programmatically-query-specific-dns-servers-on-ios/
//

struct ijt_dns_header
{
    unsigned short dns_id; // identification number
    
    unsigned char dns_rd :1; // recursion desired
    unsigned char dns_tc :1; // truncated message
    unsigned char dns_aa :1; // authoritive answer
    unsigned char dns_opcode :4; // purpose of message
    unsigned char dns_qr :1; // query/response flag
    
    unsigned char dns_rcode :4; // response code
    unsigned char dns_cd :1; // checking disabled
    unsigned char dns_ad :1; // authenticated data
    unsigned char dns_z :1; // its z! reserved
    unsigned char dns_ra :1; // recursion available
    
    unsigned short dns_q_count; // number of question entries
    unsigned short dns_ans_count; // number of answer entries
    unsigned short dns_auth_count; // number of authority entries
    unsigned short dns_add_count; // number of resource entries
};

//Constant sized fields of query structure
struct ijt_dns_question
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
struct ijt_dns_record
{
    unsigned char *name;
    struct R_DATA *resource;
    unsigned char *rdata;
};

@interface IJTDNS ()

@property (nonatomic) int sockfd;
@property (nonatomic) BOOL readUntilTimeout;

@end

@implementation IJTDNS

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

- (int)hostname2IpAddress: (NSString *)hostname
                   server: (NSString *)server
                   family: (sa_family_t)family
                  timeout: (u_int32_t)timeout
                   target: (id)target
                 selector: (SEL)selector
                   object: (id)object {
    struct sockaddr_in dst;
    char buffer[IP_MAXPACKET];
    struct ijt_dns_header *dns = (struct ijt_dns_header *)buffer;
    struct ijt_dns_question *dnsquestion = NULL;
    char *nameQuery = (char *)&buffer[sizeof(struct ijt_dns_header)];
    ssize_t sizelen = 0;
    ns_type type = (family == AF_INET ? ns_t_a : (family == AF_INET6 ? ns_t_aaaa : 0));
    DNSCallback dnscallback = NULL;
    int count = 0;
    
    //if need callback
    if(target && selector) {
        dnscallback = (DNSCallback)[target methodForSelector:selector];
    }
    
    memset(&dst, 0, sizeof(dst));
    memset(buffer, 0, sizeof(buffer));
    
    dst.sin_family = AF_INET;
    dst.sin_port = htons(53);
    inet_pton(AF_INET, [server UTF8String], &dst.sin_addr);
    
    dns->dns_id = (unsigned short)htons(arc4random());
    dns->dns_qr = 0; //This is a query
    dns->dns_opcode = 0; //This is a standard query
    dns->dns_aa = 0; //Not Authoritative
    dns->dns_tc = 0; //This message is not truncated
    dns->dns_rd = 1; //Recursion Desired
    dns->dns_ra = 0; //Recursion not available! hey we dont have it (lol)
    dns->dns_z = 0;
    dns->dns_ad = 0;
    dns->dns_cd = 0;
    dns->dns_rcode = 0;
    dns->dns_q_count = htons(1); //we have only 1 question
    dns->dns_ans_count = 0;
    dns->dns_auth_count = 0;
    dns->dns_add_count = 0;
    
    changetoDnsNameFormat((unsigned char *)nameQuery,
                          (const unsigned char *)[hostname UTF8String]);
    
    dnsquestion = (struct ijt_dns_question *)
    &buffer[sizeof(struct ijt_dns_header) + strlen(nameQuery) + 1];
    
    dnsquestion->qtype = htons(type);
    dnsquestion->qclass = htons(1);
    
    if((sizelen = sendto(self.sockfd, buffer,
                         sizeof(struct ijt_dns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_dns_question),
                         0, (struct sockaddr*)&dst,sizeof(dst))) < 0) {
        goto BAD;
    }
    
    if(sizelen != sizeof(struct ijt_dns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_dns_question))
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
                    if(dnscallback) {
                        dnscallback(target, selector, name, ipAddress, AF_INET, object);
                    }
                }
                else if(type == ns_t_aaaa) {
                    struct in6_addr *addr = (struct in6_addr *)ns_rr_rdata(rr);
                    inet_ntop(AF_INET6, addr, ntop_buf, sizeof(ntop_buf));
                    ipAddress = [NSString stringWithUTF8String:ntop_buf];
                    if(dnscallback) {
                        dnscallback(target, selector, name, ipAddress, AF_INET6, object);
                    }
                }
                
                if(!dnscallback) {
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

- (int)ipAddress2Hostname: (NSString *)ipAddress
                   server: (NSString *)server
                  timeout: (u_int32_t)timeout
                   target: (id)target
                 selector: (SEL)selector
                   object: (id)object {
    
    struct sockaddr_in dst;
    char buffer[IP_MAXPACKET];
    struct ijt_dns_header *dns = (struct ijt_dns_header *)buffer;
    struct ijt_dns_question *dnsquestion = NULL;
    char *nameQuery = (char *)&buffer[sizeof(struct ijt_dns_header)];
    ssize_t sizelen = 0;
    ns_type type = ns_t_ptr;
    DNSPTRCallback dnsptrcallback = NULL;
    int count = 0;
    NSArray *arr = nil;
    
    //if need callback
    if(target && selector) {
        dnsptrcallback = (DNSPTRCallback)[target methodForSelector:selector];
    }
    
    memset(&dst, 0, sizeof(dst));
    memset(buffer, 0, sizeof(buffer));
    
    dst.sin_family = AF_INET;
    dst.sin_port = htons(53);
    inet_pton(AF_INET, [server UTF8String], &dst.sin_addr);
    
    dns->dns_id = (unsigned short)htons(arc4random());
    dns->dns_qr = 0; //This is a query
    dns->dns_opcode = 0; //This is a standard query
    dns->dns_aa = 0; //Not Authoritative
    dns->dns_tc = 0; //This message is not truncated
    dns->dns_rd = 1; //Recursion Desired
    dns->dns_ra = 0; //Recursion not available! hey we dont have it (lol)
    dns->dns_z = 0;
    dns->dns_ad = 0;
    dns->dns_cd = 0;
    dns->dns_rcode = 0;
    dns->dns_q_count = htons(1); //we have only 1 question
    dns->dns_ans_count = 0;
    dns->dns_auth_count = 0;
    dns->dns_add_count = 0;
    
    arr = [ipAddress componentsSeparatedByString:@"."];
    if([arr count] != 4) {
        errno = EINVAL;
        goto BAD;
    }
    ipAddress = [NSString stringWithFormat:@"%@.%@.%@.%@.in-addr.arpa",
                 [arr objectAtIndex:3], [arr objectAtIndex:2],
                 [arr objectAtIndex:1], [arr objectAtIndex:0]];

    changetoDnsNameFormat((unsigned char *)nameQuery,
                          (const unsigned char *)[ipAddress UTF8String]);
    
    dnsquestion = (struct ijt_dns_question *)
    &buffer[sizeof(struct ijt_dns_header) + strlen(nameQuery) + 1];
    
    dnsquestion->qtype = htons(type);
    dnsquestion->qclass = htons(1);
    
    if((sizelen = sendto(self.sockfd, buffer,
                         sizeof(struct ijt_dns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_dns_question),
                         0, (struct sockaddr*)&dst,sizeof(dst))) < 0) {
        goto BAD;
    }
    
    if(sizelen != sizeof(struct ijt_dns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_dns_question))
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
        ns_initparse((u_char *)buffer, sizelen, &handle);
        
        for(int i = 0 ; i < ns_msg_count(handle, ns_s_an) ; i++) {
            ns_rr rr;
            if(ns_parserr(&handle, ns_s_an, i, &rr) == 0) {
                NSString *resolvehostname = [self dnsNameToString:(char *)ns_rr_rdata(rr)];
                NSString *name = [NSString stringWithUTF8String:ns_rr_name(rr)];
                if(dnsptrcallback) {
                    dnsptrcallback(target, selector, resolvehostname, ipAddress, name, object);
                }
                else {
                    printf("%s ==> %s\n", [name UTF8String], [resolvehostname UTF8String]);
                }
                count++;
            }
        }
        if(count == 0)
            goto NORESPONSE;
        if(!_readUntilTimeout) {
            break;
        }
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

- (int)injectWithInterval: (useconds_t)interval
                   server: (NSString *)server
                ipAddress: (NSString *)ipAddress {
    struct sockaddr_in dst;
    char buffer[IP_MAXPACKET];
    struct ijt_dns_header *dns = (struct ijt_dns_header *)buffer;
    struct ijt_dns_question *dnsquestion = NULL;
    char *nameQuery = (char *)&buffer[sizeof(struct ijt_dns_header)];
    ssize_t sizelen = 0;
    ns_type type = ns_t_ptr;
    NSArray *arr = nil;
    
    memset(&dst, 0, sizeof(dst));
    memset(buffer, 0, sizeof(buffer));
    
    dst.sin_family = AF_INET;
    dst.sin_port = htons(53);
    inet_pton(AF_INET, [server UTF8String], &dst.sin_addr);
    
    dns->dns_id = (unsigned short)htons(arc4random());
    dns->dns_qr = 0; //This is a query
    dns->dns_opcode = 0; //This is a standard query
    dns->dns_aa = 0; //Not Authoritative
    dns->dns_tc = 0; //This message is not truncated
    dns->dns_rd = 1; //Recursion Desired
    dns->dns_ra = 0; //Recursion not available! hey we dont have it (lol)
    dns->dns_z = 0;
    dns->dns_ad = 0;
    dns->dns_cd = 0;
    dns->dns_rcode = 0;
    dns->dns_q_count = htons(1); //we have only 1 question
    dns->dns_ans_count = 0;
    dns->dns_auth_count = 0;
    dns->dns_add_count = 0;
    
    arr = [ipAddress componentsSeparatedByString:@"."];
    if([arr count] != 4) {
        errno = EINVAL;
        goto BAD;
    }
    ipAddress = [NSString stringWithFormat:@"%@.%@.%@.%@.in-addr.arpa",
                 [arr objectAtIndex:3], [arr objectAtIndex:2],
                 [arr objectAtIndex:1], [arr objectAtIndex:0]];
    
    changetoDnsNameFormat((unsigned char *)nameQuery,
                          (const unsigned char *)[ipAddress UTF8String]);
    
    dnsquestion = (struct ijt_dns_question *)
    &buffer[sizeof(struct ijt_dns_header) + strlen(nameQuery) + 1];
    
    dnsquestion->qtype = htons(type);
    dnsquestion->qclass = htons(1);
    
    if((sizelen = sendto(self.sockfd, buffer,
                         sizeof(struct ijt_dns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_dns_question),
                         0, (struct sockaddr*)&dst,sizeof(dst))) < 0) {
        goto BAD;
    }
    
    if(sizelen != sizeof(struct ijt_dns_header) + (strlen(nameQuery)+1) + sizeof(struct ijt_dns_question))
        goto BAD;
    
    usleep(interval);
    
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
    char buffer[IP_MAXPACKET];
    ssize_t sizelen = 0;
    DNSPTRCallback dnsptrcallback = NULL;
    int count = 0;
    NSArray *arr = nil;
    
    //if need callback
    if(target && selector) {
        dnsptrcallback = (DNSPTRCallback)[target methodForSelector:selector];
    }
    
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
        ns_initparse((u_char *)buffer, sizelen, &handle);
        
        for(int i = 0 ; i < ns_msg_count(handle, ns_s_an) ; i++) {
            ns_rr rr;
            if(ns_parserr(&handle, ns_s_an, i, &rr) == 0) {
                NSString *resolvehostname = [self dnsNameToString:(char *)ns_rr_rdata(rr)];
                NSString *name = [NSString stringWithUTF8String:ns_rr_name(rr)];
                arr = [name componentsSeparatedByString:@"."];
                NSString *ipAddress = [NSString stringWithFormat:@"%@.%@.%@.%@",
                                       [arr objectAtIndex:3], [arr objectAtIndex:2],
                                       [arr objectAtIndex:1], [arr objectAtIndex:0]];
                if(dnsptrcallback) {
                    dnsptrcallback(target, selector, resolvehostname, ipAddress, name, object);
                }
                else {
                    printf("%s ==> %s\n", [name UTF8String], [resolvehostname UTF8String]);
                }
                count++;
            }
        }
        if(count == 0)
            goto NORESPONSE;
        if(!_readUntilTimeout) {
            break;
        }
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

- (NSString *)reverseString:(NSString *)str {
    NSMutableString* reversed = [NSMutableString stringWithCapacity:str.length];
    for (int i = (int)str.length-1; i >= 0; i--){
        [reversed appendFormat:@"%c", [str characterAtIndex:i]];
    }
    return reversed;
}

- (NSString *) leftPadString:(NSString *)s withPadding:(NSString *)padding {
    NSString *padded = [padding stringByAppendingString:s];
    return [padded substringFromIndex:[padded length] - [padding length]];
}

- (NSString *)dnsNameToString: (char *)rawdata {
    NSMutableString *result = [NSMutableString stringWithFormat:@""];
    for(int i = 0 ; ; i++) {
        int length = rawdata[i];
        
        if(length == 0)
            break;
        while(length--) {
            i++;
            [result appendString:[NSString stringWithFormat:@"%c", rawdata[i]]];
        }
        [result appendString:@"."];
    }
    
    return [result substringWithRange:NSMakeRange(0, result.length-1)];
}

- (void)setReadUntilTimeout: (BOOL)enable {
    _readUntilTimeout = enable;
}

+ (int)getDNSListRegisterTarget: (id)target
                       selector: (SEL)selector
                         object: (id)object {
    res_state res = malloc(sizeof(struct __res_state));
    int result = res_ninit(res);
    DNSListCallback dnslistcallback = NULL;
    
    //if need callback
    if(target && selector) {
        dnslistcallback = (DNSListCallback)[target methodForSelector:selector];
    }
    
    if(result != 0)
        goto BAD;
    
    for(int i = 0; i < res->nscount; i++) {
        if(dnslistcallback) {
            dnslistcallback(target, selector, i+1,
                            [NSString stringWithUTF8String:
                             inet_ntoa(res->nsaddr_list[i].sin_addr)],
                            object);
        }
        else
            printf("No. %d: %s\n", i+1, inet_ntoa(res->nsaddr_list[i].sin_addr));
    }
    
    if(res)
        free(res);
    return 0;
BAD:
    if(res)
        free(res);
    return h_errno;
}

+ (NSString *)hostname2IpAddress: (NSString *)hostname family: (sa_family_t)family {
    struct addrinfo hints, *res, *p;
    char ipstr[INET6_ADDRSTRLEN];
    
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC; // AF_INET 或 AF_INET6 可以指定版本
    hints.ai_socktype = SOCK_STREAM;
    if (getaddrinfo([hostname UTF8String], NULL, &hints, &res) != 0) {
        return nil;
    }
    
    for(p = res;p != NULL; p = p->ai_next) {
        void *addr = NULL;
        // 取得本身位址的指標，
        // 在 IPv4 與 IPv6 中的欄位不同：
        if(p->ai_family == AF_INET && family == AF_INET) { // IPv4
            struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
            addr = &(ipv4->sin_addr);
        }
        else if(p->ai_family == AF_INET6 && family == AF_INET6) { // IPv6
            struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)p->ai_addr;
            addr = &(ipv6->sin6_addr);
        }
        
        if(addr) {
            inet_ntop(family, addr, ipstr, sizeof ipstr);
            NSString *ipaddress = [NSString stringWithUTF8String:ipstr];
            freeaddrinfo(res);
            return ipaddress;
        }
    }
    
    freeaddrinfo(res); // 釋放鏈結串列
    return nil;
}

+ (NSString *)ipAddress2Hostname: (NSString *)ipAddress {
    struct hostent *host = NULL;
    struct in_addr ipv4addr;
    
    inet_pton(AF_INET, (const char *)[ipAddress UTF8String], &ipv4addr);
    host = getipnodebyaddr(&ipv4addr, 4, AF_INET, NULL);
    
    if(host) {
        NSString *h_name = [NSString stringWithUTF8String:host->h_name];
        freehostent(host);
        
        return h_name;
    }//end if
    return nil;
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
@end