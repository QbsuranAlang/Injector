//
//  IJTWANScanner.m
//  IJTWANScanner
//
//  Created by 聲華 陳 on 2015/11/16.
//
//

#import "IJTWANScanner.h"
#import <pcap.h>
#import <sys/socket.h>
#import <netinet/ip.h>
#import <arpa/inet.h>
#import <netinet/tcp.h>
#import <netinet/udp.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/ioctl.h>
#import <netinet/in_systm.h>
#import <netinet/ip_icmp.h>

#define TIMEOUT 1000
#define MAXDATA 1024
struct packet_tcp {
    struct ip ip;
    struct tcphdr tcp;
    unsigned char data[MAXDATA];
};
struct packet_udp {
    struct ip ip;
    struct udphdr udp;
    unsigned char data[MAXDATA];
};
struct packet_icmp {
    struct ip ip;
    struct icmp icmp;
    unsigned char data[MAXDATA];
};

@interface IJTWANScanner ()

@property (nonatomic) pcap_t *wifiPcapHandle;
@property (nonatomic) pcap_t *cellularPcapHandle;
@property (nonatomic) int sockfd;
@property (nonatomic) in_addr_t startIP;
@property (nonatomic) in_addr_t endIP;
@property (nonatomic) in_addr_t currentIP;
@property (nonatomic) in_addr_t src_ip;

@end

@implementation IJTWANScanner

- (id)init {
    self = [super init];
    if(self) {
        _wifiPcapHandle = [self openInterface:@"en0"];
        _cellularPcapHandle = [self openInterface:@"pdp_ip0"];
        _sockfd = -1;
        [self openSocket];
    }
    return self;
}

- (void)openSocket {
    int n = 1, len, maxbuf;
    
    if(self.sockfd < 0) {
        self.sockfd = socket(AF_INET, SOCK_RAW, IPPROTO_IP);
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
    if(_wifiPcapHandle) {
        pcap_close(_wifiPcapHandle);
        _wifiPcapHandle = NULL;
    }
    if(_cellularPcapHandle) {
        pcap_close(_cellularPcapHandle);
        _cellularPcapHandle = NULL;
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

- (int)setFilterExpression {
    int s = -1;
    char ntop_buf[256];
    struct ifreq ifr;
    
    //get my ip address
    s = socket(AF_INET, SOCK_STREAM, 0);
    if(s > 0) {
        strlcpy(ifr.ifr_name, "en0", sizeof(ifr.ifr_name));
        if (ioctl(s, SIOCGIFADDR, &ifr) == 0) {
            _src_ip = ((struct sockaddr_in *)(&ifr.ifr_addr))->sin_addr.s_addr;
            if(self.errorHappened)
                goto BAD;
        }//end if
        else if(errno == EADDRNOTAVAIL) { //wifi not connected
            strlcpy(ifr.ifr_name, "pdp_ip0", sizeof(ifr.ifr_name));
            if (ioctl(s, SIOCGIFADDR, &ifr) == 0) {
                _src_ip = ((struct sockaddr_in *)(&ifr.ifr_addr))->sin_addr.s_addr;
                if(self.errorHappened)
                    goto BAD;
            }//end if
            else {
                if(errno == ENXIO) //pdp_ip0 doesn't exsit
                    errno = EADDRNOTAVAIL;
                goto BAD;
            }
        }
        close(s);
    }
    else {
        goto BAD;
    }
    
    inet_ntop(AF_INET, &_src_ip, ntop_buf, sizeof(ntop_buf));
    //not arp && src host not 192.168.1.100
    [self setFilterExpression:[NSString stringWithFormat:@"not arp && src host not %s", ntop_buf]
                         pcap:_wifiPcapHandle
                    interface:@"en0"];
    [self setFilterExpression:[NSString stringWithFormat:@"not arp && src host not %s", ntop_buf]
                         pcap:_cellularPcapHandle
                    interface:@"pdp_ip0"];
OK:
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(s >= 0) {
        close(s);
    }
    self.errorHappened = YES;
    return -1;
}

- (int)injectWithInterval: (useconds_t)interval {
    struct packet_icmp send_icmp_packet;
    struct sockaddr_in dest;
    int icmp_data_len = 10;
    int iplen = 0;
    
    if(ntohl(_currentIP) > ntohl(_endIP))
        goto OK;
    
    
    memset(&dest, 0, sizeof(dest));
    dest.sin_family = AF_INET;
    dest.sin_addr.s_addr = _currentIP;
    
    //send tcp
    [self sendTCP_SYN_ACKPort:80 dest:dest];
    [self sendTCP_SYN_ACKPort:22 dest:dest];
    [self sendTCP_SYN_ACKPort:443 dest:dest];
    for(int i = 0 ; i < 10 ; i++) {
        [self sendTCP_SYN_ACKPort:arc4random()%UINT16_MAX dest:dest];
    }
    
    //send udp
    [self sendUDPPort:53 dest:dest payload:"\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00" udp_data_len:12];
    [self sendUDPPort:137 dest:dest payload:"\x80\xF0\x00\x10\x00\x01\x00\x00\x00\x00\x00\x00\x20""CKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\x00\x00\x21\x00\x01" udp_data_len:50];
    [self sendUDPPort:7 dest:dest payload:"\x0D\x0A\x0D\x0A" udp_data_len:4];
    
    //send icmp ping
    iplen = icmp_data_len + (sizeof send_icmp_packet.ip) + (ICMP_MINLEN);
    make_icmp_header(&send_icmp_packet, icmp_data_len);
    make_ip_header(&(send_icmp_packet.ip), _src_ip, _currentIP, IPPROTO_ICMP, iplen);
    for(int i = 0 ; i < 3 ; i++) {
        sendto(_sockfd, (char *)&send_icmp_packet, iplen, 0, (struct sockaddr *)&dest, sizeof(dest));
    }
    
    _currentIP = htonl(ntohl(_currentIP) + 1);
    usleep(interval);
    
OK:
    self.errorHappened = NO;
    return 0;
}

- (void)sendTCP_SYN_ACKPort: (u_int16_t)port dest: (struct sockaddr_in)dest {
    
    int tcp_headear_option = 4;
    struct packet_tcp send_tcp_packet;
    int iplen = 0;
    
    //send syn
    memset(&send_tcp_packet, 0, sizeof(send_tcp_packet));
    memcpy(send_tcp_packet.data, "\x02\x04\x05\xb4", 4);
    iplen = tcp_headear_option + (sizeof send_tcp_packet.ip) + (sizeof send_tcp_packet.tcp);
    make_tcp_header(&send_tcp_packet,
                    _src_ip, arc4random()%(65535-49152+1)+(49152),
                    _currentIP, port, //http
                    0, 0, TH_SYN, tcp_headear_option);
    make_ip_header(&(send_tcp_packet.ip), _src_ip, _currentIP, IPPROTO_TCP, iplen);
    
    sendto(_sockfd, (char *)&send_tcp_packet, iplen, 0, (struct sockaddr *)&dest, sizeof(dest));
    
    //send ack
    iplen = 0 + (sizeof send_tcp_packet.ip) + (sizeof send_tcp_packet.tcp);
    memset(&send_tcp_packet, 0, sizeof(send_tcp_packet));
    make_tcp_header(&send_tcp_packet,
                    _src_ip, arc4random()%(65535-49152+1)+(49152),
                    dest.sin_addr.s_addr, port, //http
                    1, 1, TH_ACK, 0);
    make_ip_header(&(send_tcp_packet.ip), _src_ip, dest.sin_addr.s_addr, IPPROTO_TCP, iplen);
    sendto(_sockfd, (char *)&send_tcp_packet, iplen, 0, (struct sockaddr *) &dest, sizeof(dest));
}

- (void)sendUDPPort: (u_int16_t)port dest: (struct sockaddr_in)dest payload: (char *)payload udp_data_len: (int)udp_data_len {
    struct packet_udp send_udp_packet;
    int iplen = udp_data_len + (sizeof send_udp_packet.ip) + (sizeof send_udp_packet.udp);
    
    memset(&send_udp_packet, 0, sizeof(send_udp_packet));
    memcpy(&send_udp_packet.data, payload, udp_data_len);
    make_udp_header(&send_udp_packet,
                    arc4random()%(65535-49152+1)+(49152), port,
                    udp_data_len);
    make_ip_header(&(send_udp_packet.ip), _src_ip, _currentIP, IPPROTO_UDP, iplen);
    sendto(_sockfd, (char *)&send_udp_packet, iplen, 0, (struct sockaddr *)&dest, sizeof(dest));
}

- (NSArray *)read {
    NSMutableArray *onlineList = [[NSMutableArray alloc] init];
    
    //read
    [self readPcap:_wifiPcapHandle onlineList:onlineList data_linkLength:14];
    [self readPcap:_cellularPcapHandle onlineList:onlineList data_linkLength:4];
    
    NSSet *set = [NSSet setWithArray:onlineList];
    onlineList = [[set allObjects] mutableCopy];
    
    for(int i = 0 ; i < [onlineList count] ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSDictionary *dict1 = [onlineList objectAtIndex:i];
            NSDictionary *dict2 = [onlineList objectAtIndex:j];
            NSString *ipAddress1 = [dict1 valueForKey:@"IpAddress"];
            NSString *ipAddress2 = [dict2 valueForKey:@"IpAddress"];
            in_addr_t ip1, ip2;
            inet_pton(AF_INET, [ipAddress1 UTF8String], &ip1);
            inet_pton(AF_INET, [ipAddress2 UTF8String], &ip2);
            if(ntohl(ip1) < ntohl(ip2)) {
                [onlineList exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }
    
    return onlineList;
}

- (void)readPcap: (pcap_t *)pcap onlineList: (NSMutableArray *)onlineList data_linkLength: (int)length {
    
    struct pcap_pkthdr *header;
    const u_char *content;
    char ntop_buf[256];
    if(!pcap)
        return;
    
    while(pcap_next_ex(pcap, &header, &content) == 1) {
        struct ip *ip = (struct ip *)(content + length);
        in_addr_t addr = ip->ip_src.s_addr;
        if(ntohl(_startIP) <= ntohl(addr) && ntohl(addr) <= ntohl(_endIP)) {
            inet_ntop(AF_INET, &ip->ip_src, ntop_buf, sizeof(ntop_buf));
            NSString *ipAddress = [NSString stringWithUTF8String:ntop_buf];
            
            
            NSNumber *flags = @(IJTWANStatusFlagsFirewalled);
            NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
            BOOL found = NO;
            //search
            for(int i = 0 ; i < [onlineList count] ; i++) {
                NSMutableDictionary *dict = [onlineList objectAtIndex:i];
                if([[dict valueForKey:@"IpAddress"] isEqualToString:ipAddress]) {
                    flags = [dict valueForKey:@"Flags"];
                    newDict = dict;
                    found = YES;
                    break;
                }
            }
            
            //if it is a icmp echo reply
            if(ip->ip_p == IPPROTO_ICMP) {
                struct icmp *icmp = (struct icmp *)(content + length + (ip->ip_hl << 2));
                if(icmp->icmp_type == ICMP_ECHOREPLY) {
                    flags = @([flags unsignedShortValue] | IJTWANStatusFlagsPing); //enable ping
                }
            }
            else if(ip->ip_p == IPPROTO_TCP) {
                struct tcphdr *tcp = (struct tcphdr *)(content + length + (ip->ip_hl << 2));
                if((tcp->th_flags & TH_RST) && ntohs(tcp->th_sport) == 22) {
                    flags = @([flags unsignedIntegerValue] & ~IJTWANStatusFlagsFirewalled); //disable firewalled
                }
            }
            //update flags
            [newDict setValue:flags forKey:@"Flags"];
            
            //not found mean need insert new one
            if(!found) {
                [newDict setValue:ipAddress forKey:@"IpAddress"];
                [onlineList addObject:newDict];
            }
        }//end if match
    }//end while read
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

static void make_icmp_header(struct packet_icmp *packet, int datalen) {
    int icmpid = arc4random();
    packet->icmp.icmp_type = ICMP_ECHO;
    packet->icmp.icmp_code = 0;
    packet->icmp.icmp_id = htons(icmpid);
    packet->icmp.icmp_seq = icmpid;
    packet->icmp.icmp_cksum = checksum((u_short *)&packet->icmp, ICMP_MINLEN + datalen);
}

static void make_udp_header(struct packet_udp *packet, int src_port, int dst_port, int datalen) {
    packet->udp.uh_sport = htons(src_port);
    packet->udp.uh_dport = htons(dst_port);
    packet->udp.uh_sum = 0;
    packet->udp.uh_ulen = htons(sizeof(struct udphdr) + datalen);
}

static void make_tcp_header(struct packet_tcp *packet, int src_ip, int src_port,
                            int dst_ip, int dst_port, int seq, int ack, u_int8_t flags, int datalen) {
    packet->tcp.th_seq   = htonl(seq);
    packet->tcp.th_ack   = htonl(ack);
    packet->tcp.th_sport = htons(src_port);
    packet->tcp.th_dport = htons(dst_port);
    packet->tcp.th_off   = (sizeof(struct tcphdr) + datalen) >> 2;
    packet->tcp.th_flags = flags;
    packet->tcp.th_win   = htons(1024);
    packet->tcp.th_urp   = htons(0);
    
    packet->ip.ip_ttl    = 0;
    packet->ip.ip_p      = IPPROTO_TCP;
    packet->ip.ip_src.s_addr = src_ip;
    packet->ip.ip_dst.s_addr = dst_ip;
    packet->ip.ip_sum    = htons((sizeof packet->tcp) + datalen);
    
#define PSEUDO_HEADER_LEN 12
    packet->tcp.th_sum = 0;
    packet->tcp.th_sum = checksum((u_int16_t *) &(packet->ip.ip_ttl),
                                  PSEUDO_HEADER_LEN + (sizeof packet->tcp)
                                  + datalen);
}

static void make_ip_header(struct ip *ip, int src_ip, int dst_ip, u_char protocol, int iplen) {
    ip->ip_v   = IPVERSION;
    ip->ip_hl  = sizeof (struct ip) >> 2;
    ip->ip_id  = arc4random();
    ip->ip_len = iplen;
    ip->ip_off = 0;
    ip->ip_ttl = 255;
    ip->ip_p   = protocol;
    ip->ip_src.s_addr = src_ip;
    ip->ip_dst.s_addr = dst_ip;
    
    ip->ip_sum = 0;
    ip->ip_sum = checksum((u_int16_t *) ip, sizeof ip);
}

- (u_int64_t)getTotalInjectCount {
    return (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_startIP) + 1;
}

- (u_int64_t)getRemainInjectCount {
    return (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_currentIP) + 1 <= 0 ? 0 : (u_int64_t)ntohl(_endIP) - (u_int64_t)ntohl(_currentIP) + 1;
}

- (pcap_t *)openInterface: (NSString *)interface {
    pcap_t *handle = NULL;
    char errbuf[PCAP_ERRBUF_SIZE];
    
    handle = pcap_open_live([interface UTF8String], 65535, 1, TIMEOUT, errbuf);
    return handle;
}

- (void)setFilterExpression: (NSString *)expression pcap:(pcap_t *)pcap interface:(NSString *)interface {
    if(!pcap) {
        return;
    }
    
    char errbuf[PCAP_ERRBUF_SIZE];
    struct bpf_program bpf_filter;
    bpf_u_int32 net_mask;
    bpf_u_int32 net_ip;
    
    //set bpf filter
    if(0 != pcap_lookupnet((const char *)[interface UTF8String], &net_ip, &net_mask, errbuf)) {
        return;
    }//end if
    if(0 != pcap_compile(pcap, &bpf_filter, (const char *)[expression UTF8String], 0, net_ip)) {
        return;
    }//end if
    if(0 != pcap_setfilter(pcap, &bpf_filter)) {
        pcap_freecode(&bpf_filter);
        return;
    }//end if
    
    pcap_freecode(&bpf_filter);
}

@end
