//
//  IJTNULL-Scan.m
//  IJTNULL Scan
//
//  Created by 聲華 陳 on 2015/9/14.
//
//

#import "IJTNULL-Scan.h"
#import <sys/socket.h>
#import <netinet/ip.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <netinet/tcp.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/ioctl.h>
#import <net/bpf.h>
#import <netinet/ip_icmp.h>
#import "IJTSysctl.h"

#define MAXDATA 1024
struct packet_tcp {
    struct ip ip;
    struct tcphdr tcp;
    unsigned char data[MAXDATA];
};

@interface IJTNULL_Scan ()

@property (nonatomic) int sockfd;
@property (nonatomic) int bpfd;
@property (nonatomic) struct sockaddr_in dest;
@property (nonatomic) u_int32_t start_port;
@property (nonatomic) u_int32_t end_port;
@property (nonatomic) u_int32_t current_index;
@property (nonatomic, strong) NSString *hostname;
@property (nonatomic, strong) NSMutableArray *recvRstArray;
@property (nonatomic, strong) NSMutableArray *recvIcmpArray;
@property (nonatomic) int bpfbufsize;
@property (nonatomic) int data_link_len;

@end

@implementation IJTNULL_Scan

- (id)init {
    self = [super init];
    if(self) {
        self.sockfd = -1;
        self.bpfd = -1;
        self.data_link_len = 0;
        [self open];
    }
    return self;
}

- (void)open {
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
    if(self.bpfd >= 0) {
        close(self.bpfd);
        self.bpfd= -1;
    }
}

- (void)open: (NSString *)interface {
    _bpfbufsize = -1;
    char buf[256];
    struct ifreq ifr; //interface
    int n = 0, maxbuf;
    
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
    if([interface isEqualToString:@"en0"]) {
        
        /* dump tcp RST only */
        // tcpdump -i en0 -dd "tcp[tcpflags] & tcp-rst != 0 or icmp[0:2] = 0x0301 or icmp[0:2] = 0x0302 or icmp[0:2] = 0x0303 or icmp[0:2] = 0x0309 or icmp[0:2] = 0x030a or icmp[0:2] = 0x030d"
        struct bpf_insn insns[] = {
            { 0x28, 0, 0, 0x0000000c },
            { 0x15, 0, 19, 0x00000800 },
            { 0x30, 0, 0, 0x00000017 },
            { 0x15, 0, 5, 0x00000006 },
            { 0x28, 0, 0, 0x00000014 },
            { 0x45, 15, 0, 0x00001fff },
            { 0xb1, 0, 0, 0x0000000e },
            { 0x50, 0, 0, 0x0000001b },
            { 0x45, 11, 12, 0x00000004 },
            { 0x15, 0, 11, 0x00000001 },
            { 0x28, 0, 0, 0x00000014 },
            { 0x45, 9, 0, 0x00001fff },
            { 0xb1, 0, 0, 0x0000000e },
            { 0x48, 0, 0, 0x0000000e },
            { 0x15, 5, 0, 0x00000301 },
            { 0x15, 4, 0, 0x00000302 },
            { 0x15, 3, 0, 0x00000303 },
            { 0x15, 2, 0, 0x00000309 },
            { 0x15, 1, 0, 0x0000030a },
            { 0x15, 0, 1, 0x0000030d },
            { 0x6, 0, 0, 0x00000044 },
            { 0x6, 0, 0, 0x00000000 }
        };
        
        /* Set the filter */
        fcode.bf_len = sizeof(insns) / sizeof(struct bpf_insn);
        fcode.bf_insns = &insns[0];
        
        self.data_link_len = 14;
    }
    else if ([interface isEqualToString:@"pdp_ip0"]) {
        /* dump tcp RST only */
        // tcpdump -i pdp_ip0 -dd "tcp[tcpflags] & tcp-rst != 0 or icmp[0:2] = 0x0301 or icmp[0:2] = 0x0302 or icmp[0:2] = 0x0303 or icmp[0:2] = 0x0309 or icmp[0:2] = 0x030a or icmp[0:2] = 0x030d"
        struct bpf_insn insns[] = {
            { 0x20, 0, 0, 0x00000000 },
            { 0x15, 0, 19, 0x02000000 },
            { 0x30, 0, 0, 0x0000000d },
            { 0x15, 0, 5, 0x00000006 },
            { 0x28, 0, 0, 0x0000000a },
            { 0x45, 15, 0, 0x00001fff },
            { 0xb1, 0, 0, 0x00000004 },
            { 0x50, 0, 0, 0x00000011 },
            { 0x45, 11, 12, 0x00000004 },
            { 0x15, 0, 11, 0x00000001 },
            { 0x28, 0, 0, 0x0000000a },
            { 0x45, 9, 0, 0x00001fff },
            { 0xb1, 0, 0, 0x00000004 },
            { 0x48, 0, 0, 0x00000004 },
            { 0x15, 5, 0, 0x00000301 },
            { 0x15, 4, 0, 0x00000302 },
            { 0x15, 3, 0, 0x00000303 },
            { 0x15, 2, 0, 0x00000309 },
            { 0x15, 1, 0, 0x0000030a },
            { 0x15, 0, 1, 0x0000030d },
            { 0x6, 0, 0, 0x00000044 },
            { 0x6, 0, 0, 0x00000000 }
        };
        
        /* Set the filter */
        fcode.bf_len = sizeof(insns) / sizeof(struct bpf_insn);
        fcode.bf_insns = &insns[0];
        
        self.data_link_len = 4;
    }
    
    if(ioctl(_bpfd, BIOCSETF, &fcode) < 0)
        goto BAD;
    
    self.errorHappened = NO;
    return;
    
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    [self close];
    return;
}

- (int)setTarget: (NSString *)target {
    struct hostent *hp;
    char hnamebuf[MAXHOSTNAMELEN];
    struct sockaddr_in sin;
    
    //clear
    memset(&sin, 0, sizeof(sin));
    sin.sin_family = AF_INET;
    sin.sin_len = sizeof(sin);
    
    //resolve hostname
    if (inet_aton([target UTF8String], &sin.sin_addr) != 0) { //ip address
        self.hostname = target;
    }
    else {//hostname
        hp = gethostbyname2([target UTF8String], AF_INET);
        if (!hp)
            goto HOSTBAD;
        if ((unsigned)hp->h_length > sizeof(sin.sin_addr))
            goto HOSTBAD;
        
        memcpy(&sin.sin_addr, hp->h_addr_list[0], sizeof sin.sin_addr);
        (void)strncpy(hnamebuf, hp->h_name, sizeof(hnamebuf) - 1);
        hnamebuf[sizeof(hnamebuf) - 1] = '\0';
        self.hostname = [NSString stringWithUTF8String:hnamebuf];
    }
    
    memset(&_dest, 0, sizeof(_dest));
    _dest.sin_family = AF_INET;
    _dest.sin_addr.s_addr = sin.sin_addr.s_addr;
    
OK:
    self.errorHappened = NO;
    return 0;
HOSTBAD:
    self.errorCode = h_errno;
    self.errorHappened = YES;
    return -2;
}

- (void)setStartPort: (u_int16_t)startPort endPort: (u_int16_t)endPort {
    //swap
    if(startPort > endPort) {
        u_int16_t temp = startPort;
        startPort = endPort;
        endPort = temp;
    }
    
    self.start_port = startPort;
    self.current_index = 0;
    self.end_port = endPort;
}

- (int)injectWithInterval: (useconds_t)interval
            randomization: (BOOL)randomization
                     stop: (BOOL *)stop
                  timeout: (u_int32_t)timeout
                   target: (id)target
                 selector: (SEL)selector
                   object: (id)object {
    u_int32_t *port_list = NULL;
    u_int32_t total = (u_int32_t)[self getTotalInjectCount];
    port_list = (u_int32_t *)malloc(total * sizeof(u_int32_t));
    self.recvRstArray = [[NSMutableArray alloc] init];
    self.recvIcmpArray = [[NSMutableArray alloc] init];
    ssize_t size;
    struct packet_tcp send_packet;
    int s = -1;
    NULLScanCallback nullscancallback = NULL;
    
    if(!port_list)
        goto BAD;
    memset(port_list, 0, total);
    for(u_int32_t port = _start_port, i = 0 ; port <= _end_port ; port++, i++) {
        port_list[i] = port;
    }
    
    if(target && selector) {
        nullscancallback = (NULLScanCallback)[target methodForSelector:selector];
    }
    
    if(randomization) {
        for(u_int32_t i = 0 ; i < total ; i++) {
            u_int32_t index1 = arc4random() % total;
            u_int32_t index2 = arc4random() % total;
            u_int32_t temp = port_list[index1];
            port_list[index1] = port_list[index2];
            port_list[index2] = temp;
        }
    }//end if randomization
    
    //try to connect
    s = socket(AF_INET, SOCK_STREAM, 0);
    if(s < 0)
        goto BAD;
    _dest.sin_port = htons(80);
    int oldFlags = fcntl(s, F_GETFL, NULL);
    if(oldFlags < 0)
        goto BAD;
    oldFlags |= O_NONBLOCK;
    if(fcntl(s, F_SETFL, oldFlags) < 0)
        goto BAD;
    
    connect(s, (struct sockaddr *)&_dest, sizeof(_dest));
    
    while(1) {
        fd_set fd;
        struct timespec tv = {};
        int n = 0;
        
        FD_ZERO(&fd);
        FD_SET(s, &fd);
        tv.tv_sec = timeout / 1000;
        tv.tv_nsec = timeout % 1000 * 1000;
        
        if ((n = pselect(s + 1, NULL, &fd, NULL, &tv, NULL)) < 0) {
            goto BAD;
        }
        if(n == 0) {
            goto HOSTDOWN;
        }
        
        if(!FD_ISSET(s, &fd))
            continue;
        
        //disable block
        int oldFlags = fcntl(s, F_GETFL, NULL);
        if(oldFlags < 0)
            goto BAD;
        oldFlags &= ~O_NONBLOCK;
        if(fcntl(s, F_SETFL, oldFlags) < 0)
            goto BAD;
        
        int val;
        int len = sizeof(val);
        getsockopt(s, SOL_SOCKET, SO_ERROR, (void *)&val, (socklen_t *)&len);
        
        if(val == 0 || val == ECONNREFUSED) {
            break; //host up
        }
        else {
            errno = val;
            goto BAD;
        }
    }//end while
    
    //get my ip address
    struct ifreq ifr;
    in_addr_t src_ip = 0;
    if(s > 0) {
        strlcpy(ifr.ifr_name, "en0", sizeof(ifr.ifr_name));
        if (ioctl(s, SIOCGIFADDR, &ifr) == 0) {
            src_ip = ((struct sockaddr_in *)(&ifr.ifr_addr))->sin_addr.s_addr;
            [self open:@"en0"];
            if(self.errorHappened)
                goto BAD;
        }//end if
        else if(errno == EADDRNOTAVAIL) { //wifi not connected
            strlcpy(ifr.ifr_name, "pdp_ip0", sizeof(ifr.ifr_name));
            if (ioctl(s, SIOCGIFADDR, &ifr) == 0) {
                src_ip = ((struct sockaddr_in *)(&ifr.ifr_addr))->sin_addr.s_addr;
                [self open:@"pdp_ip0"];
                if(self.errorHappened)
                    goto BAD;
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
    
    for(_current_index = 0 ; _current_index < total ; _current_index++) {
        if(stop && *stop)
            break;
        u_int16_t current_port = port_list[_current_index];
        _dest.sin_port = htons(current_port);
        int datalen = 0;
        int iplen = datalen + (sizeof send_packet.ip) + (sizeof send_packet.tcp);
        
        memset(&send_packet, 0, sizeof(send_packet));
        make_tcp_header(&send_packet,
                        src_ip, arc4random()%(65535-49152+1)+(49152),
                        _dest.sin_addr.s_addr, current_port,
                        1, 0, 0, datalen);
        make_ip_header(&(send_packet.ip), src_ip, _dest.sin_addr.s_addr, iplen);
        
        if ((size = sendto(_sockfd, (char *)&send_packet, iplen, 0, (struct sockaddr *) &_dest, sizeof(_dest))) < 0) {
            goto BAD;
        }
        if(size != iplen)
            goto BAD;
        
        if(_current_index != 0 && (_current_index % 100) == 0) {
            if([self readTimeout:timeout] == -1)
                goto BAD;
        }
        
        usleep(interval);
    }//end for each port
    
    if([self readTimeout:timeout] == -1)
        goto BAD;
    
    self.recvRstArray = [NSMutableArray arrayWithArray:[self.recvRstArray sortedArrayUsingSelector:@selector(compare:)]];
    self.recvIcmpArray = [NSMutableArray arrayWithArray:[self.recvIcmpArray sortedArrayUsingSelector:@selector(compare:)]];
    
    
    for(u_int16_t port = _start_port ; port <= _end_port ; port++) {
        IJTNULL_ScanFlags flags = IJTNULL_ScanFlagsFiltered | IJTNULL_ScanFlagsOpen;
        for(NSNumber *openPort in self.recvIcmpArray) {
            if([openPort unsignedShortValue] == port) {
                flags = IJTNULL_ScanFlagsFiltered;
                break;
            }
        }
        for(NSNumber *closePort in self.recvRstArray) {
            if([closePort unsignedShortValue] == port) {
                flags = IJTNULL_ScanFlagsClose;
                break;
            }
        }
        if(nullscancallback) {
            nullscancallback(target, selector, port, [self portName:port], flags, object);
        }
        else {
            NSLog(@"%d %@ %d", port, [self portName:port], flags);
        }
    }
    
    
    if(port_list)
        free(port_list);
    if(s >= 0)
        close(s);
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(port_list)
        free(port_list);
    if(s >= 0)
        close(s);
    self.errorHappened = YES;
    return -1;
HOSTDOWN:
    if(s >= 0)
        close(s);
    if(port_list)
        free(port_list);
    self.errorHappened = YES;
    return -2;
}

- (int)readTimeout: (u_int32_t)timeout {
    //ready to read
    char *recvbuffer = NULL;
    recvbuffer = malloc(_bpfbufsize);
    if(!recvbuffer)
        goto BAD;
    
    while(1) {
        int n = 0;
        fd_set readfd = {};
        struct timespec tv = {};
        tv.tv_sec = timeout / 1000;
        tv.tv_nsec = timeout % 1000 * 1000;
        struct bpf_hdr *bp = NULL; //bpf header
        char *p = NULL; //pointer to packet header start position
        ssize_t bpf_len = 0; //bpf receive len
        
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
        
        //analyze packet
        while(bpf_len > 0) {
            p = (char *)bp + bp->bh_hdrlen;
            
            struct ip *ip = (struct ip *)((char *)p + self.data_link_len);
            
            if(ip->ip_src.s_addr == _dest.sin_addr.s_addr) {
                if(ip->ip_p == IPPROTO_TCP) {
                    struct tcphdr *tcp = (struct tcphdr *)((char *)ip + (ip->ip_hl << 2));
                    if(tcp->th_flags & TH_RST) {
                        [self.recvRstArray addObject:@(htons(tcp->th_sport))];
                    }
                }
                else if(ip->ip_p == IPPROTO_ICMP) {
                    struct icmp *icmp;
                    struct ip *ip2;
                    struct tcphdr *tcp;
                    
                    icmp = (struct icmp *)((char *)ip + (ip->ip_hl << 2));
                    ip2 = (struct ip *)icmp->icmp_data;
                    if(ip2->ip_p == IPPROTO_TCP) {
                        tcp = (struct tcphdr *)((u_char *)ip2 + (ip2->ip_hl << 2));
                        if(ip2->ip_dst.s_addr == _dest.sin_addr.s_addr) {
                            [self.recvIcmpArray addObject:@(htons(tcp->th_dport))];
                        }
                    }
                }
            }
            
            //next packet
            bpf_len -= BPF_WORDALIGN(bp->bh_hdrlen + bp->bh_caplen);
            if(bpf_len > 0) {
                bp = (struct bpf_hdr *) ((char *)bp + BPF_WORDALIGN(bp->bh_hdrlen + bp->bh_caplen));
            }
        }//end while bpf_len > 0
    }//end while
    
    if(recvbuffer)
        free(recvbuffer);
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(recvbuffer)
        free(recvbuffer);
    self.errorHappened = YES;
    return -1;
}

- (u_int64_t)getTotalInjectCount {
    return (u_int64_t)self.end_port - (u_int64_t)self.start_port + 1;
}

- (u_int64_t)getRemainInjectCount {
    u_int64_t count = [self getTotalInjectCount] - self.current_index;
    return count <= 0 ? 0 : count;
}

- (NSString *)portName: (u_int16_t)portNumber {
    struct servent *se; //server information
    se = getservbyport(htons(portNumber), "tcp");
    NSString *name = [NSString stringWithUTF8String:se ? se->s_name : "unknown"];
    return name;
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
                            int dst_ip, int dst_port, int seq, int ack, u_int8_t flags, int datalen) {
    packet->tcp.th_seq   = htonl(seq);
    packet->tcp.th_ack   = htonl(ack);
    packet->tcp.th_sport = htons(src_port);
    packet->tcp.th_dport = htons(dst_port);
    packet->tcp.th_off   = sizeof(struct tcphdr) >> 2;
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

static void make_ip_header(struct ip *ip, int src_ip, int dst_ip, int iplen) {
    ip->ip_v   = IPVERSION;
    ip->ip_hl  = sizeof (struct ip) >> 2;
    ip->ip_id  = arc4random();
    ip->ip_len = iplen;
    ip->ip_off = 0;
    ip->ip_ttl = 255;
    ip->ip_p   = IPPROTO_TCP;
    ip->ip_src.s_addr = src_ip;
    ip->ip_dst.s_addr = dst_ip;
    
    ip->ip_sum = 0;
    ip->ip_sum = checksum((u_int16_t *) ip, sizeof ip);
}

@end
