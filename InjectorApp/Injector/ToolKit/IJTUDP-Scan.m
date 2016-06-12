//
//  IJTUDP-Scan.m
//  IJTUDP Scan
//
//  Created by 聲華 陳 on 2015/9/5.
//
//

#import "IJTUDP-Scan.h"
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <netinet/ip.h>
#import <netinet/ip_icmp.h>
#import <netinet/udp.h>

@interface IJTUDP_Scan ()

@property (nonatomic, strong) NSString *hostname;
@property (nonatomic) struct sockaddr_in dest;
@property (nonatomic) u_int32_t start_port;
@property (nonatomic) u_int32_t end_port;
@property (nonatomic) u_int32_t current_index;
@property (nonatomic) int udp_fd;
@property (nonatomic) int icmp_fd;
@property (nonatomic, strong) NSMutableArray *replyStatusArray;

@end

@implementation IJTUDP_Scan

- (id)init {
    self = [super init];
    if(self) {
        self.udp_fd = -1;
        self.icmp_fd = -1;
        [self open];
    }
    return self;
}

- (void)open {
    int n = 1, len, maxbuf;
    
    if(self.udp_fd < 0) {
        self.udp_fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if(self.udp_fd < 0)
            goto BAD;
    }
    
    //send buffer
    len = sizeof(n);
    maxbuf = 1024*1024;
    
    if (getsockopt(self.udp_fd, SOL_SOCKET, SO_SNDBUF, &n, (socklen_t *)&len) < 0)
        goto BAD;
    
    for (n += 1024; n < maxbuf; n += 1024) {
        if (setsockopt(self.udp_fd, SOL_SOCKET, SO_SNDBUF, &n, len) < 0) {
            if (errno == ENOBUFS)
                break;
            goto BAD;
        }
    }
    
    len = sizeof(n);
    maxbuf = 1024*1024;
    if (getsockopt(self.udp_fd, SOL_SOCKET, SO_RCVBUF, &n, (socklen_t *)&len) < 0)
        goto BAD;
    
    for (n += 1024; n <= maxbuf; n += 1024) {
        if (setsockopt(self.udp_fd, SOL_SOCKET, SO_RCVBUF, &n, len) < 0) {
            if (errno == ENOBUFS)
                break;
            goto BAD;
        }
    }
    
    //enable broadcast
    n = 1;
    if (setsockopt(self.udp_fd, SOL_SOCKET, SO_BROADCAST, &n, sizeof(n)) < 0)
        goto BAD;
    
    
    //receive socket
    if(self.icmp_fd < 0) {
        self.icmp_fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
        if(self.icmp_fd < 0)
            goto BAD;
    }
    
    //receive buffer
    len = sizeof(n);
    maxbuf = 1024*1024;
    
    if (getsockopt(self.icmp_fd, SOL_SOCKET, SO_RCVBUF, &n, (socklen_t *)&len) < 0)
        goto BAD;
    
    for (n += 1024; n <= maxbuf; n += 1024) {
        if (setsockopt(self.icmp_fd, SOL_SOCKET, SO_RCVBUF, &n, len) < 0) {
            if (errno == ENOBUFS)
                break;
            goto BAD;
        }
    }
    
    //enable broadcast
    n = 1;
    if (setsockopt(self.icmp_fd, SOL_SOCKET, SO_BROADCAST, &n, sizeof(n)) < 0)
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
    if(self.udp_fd >= 0) {
        close(self.udp_fd);
        self.udp_fd = -1;
    }
    if(self.icmp_fd >= 0) {
        close(self.icmp_fd);
        self.icmp_fd = -1;
    }
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
    UDPScanCallback udpscancallback = NULL;
    self.replyStatusArray = [[NSMutableArray alloc] init];
    NSArray *checkPortArray = nil;
    
    if(target && selector) {
        udpscancallback = (UDPScanCallback)[target methodForSelector:selector];
    }
    
    if(!port_list)
        goto BAD;
    memset(port_list, 0, total);
    for(u_int32_t port = _start_port, i = 0 ; port <= _end_port ; port++, i++) {
        port_list[i] = port;
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
    int s = socket(AF_INET, SOCK_STREAM, 0);
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
    close(s);
    s = -1;
    
    for(_current_index = 0 ; _current_index < total ; _current_index++) {
        if(stop && *stop)
            break;
        ssize_t size;
        u_int16_t current_port = port_list[_current_index];
        _dest.sin_port = htons(current_port);
        int length = 0;
        char *send_buffer = [self udpPortPayload:current_port length:&length];
        int ret;
        size = sendto(_udp_fd, send_buffer, length, 0, (struct sockaddr *)&_dest, sizeof(_dest));
        
        if(size < 0) {
            if(errno == ENOBUFS) {
                sleep(1);
                _current_index--;
            }
            else {
                goto BAD;
            }
        }
        else {
            if(size != length)
                goto BAD;
        }
        
        ret =
        [self readTimeout:timeout current_port:current_port];
        
        if(ret == -1)
            goto BAD;
        
        usleep(interval);
        
    }//end for each port
    
    //check again
    checkPortArray = [NSArray arrayWithArray:self.replyStatusArray];
    for(NSUInteger i = 0 ; i < checkPortArray.count ; i++) {
        
        if(stop && *stop)
            break;
        
        NSDictionary *dict = checkPortArray[i];
        NSNumber *flags = [dict valueForKey:@"Flags"];
        NSNumber *portNumber = [dict valueForKey:@"Port"];
        if([flags unsignedCharValue] & IJTUDP_ScanFlagsOpen) {
            ssize_t size;
            u_int16_t current_port = [portNumber unsignedShortValue];
            _dest.sin_port = htons(current_port);
            int length = 0;
            char *send_buffer = [self udpPortPayload:current_port length:&length];
            int ret;
            
            size = sendto(_udp_fd, send_buffer, length, 0, (struct sockaddr *)&_dest, sizeof(_dest));
            
            if(size < 0) {
                if(errno == ENOBUFS) {
                    i--;
                    sleep(1);
                }
                else {
                    goto BAD;
                }
            }
            else {
                if(size != length)
                    goto BAD;
            }
            
            ret =
            [self readTimeout:timeout current_port:current_port];
            
            if(ret == -1)
                goto BAD;
            
            usleep(interval);
        }
    }
    
    //sort by port
    for(int i = 0 ; i < self.replyStatusArray.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSDictionary *dict1 = [self.replyStatusArray objectAtIndex:i];
            NSDictionary *dict2 = [self.replyStatusArray objectAtIndex:j];
            NSNumber *port1 = [dict1 valueForKey:@"Port"];
            NSNumber *port2 = [dict2 valueForKey:@"Port"];
            if([port1 unsignedShortValue] < [port2 unsignedShortValue]) {
                [self.replyStatusArray exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }//end for
    
    for(NSDictionary *dict in self.replyStatusArray) {
        struct timeval timestamp;
        NSValue *value = [dict valueForKey:@"Timstamp"];
        NSNumber *portNumber = [dict valueForKey:@"Port"];
        NSNumber *flags = [dict valueForKey:@"Flags"];
        [value getValue:&timestamp];
        if(udpscancallback) {
            udpscancallback(target, selector,
                            [portNumber unsignedShortValue], [self portNameByNumber:[portNumber unsignedShortValue]],
                            [flags unsignedCharValue], timestamp, object);
        }
        else {
            printf("%d: ", [portNumber unsignedShortValue]);
            if(flags == IJTUDP_ScanFlagsClose)
                printf("close");
            else {
                if([flags unsignedCharValue] & IJTUDP_ScanFlagsFiltered)
                    printf("filtered");
                if([flags unsignedCharValue] & IJTUDP_ScanFlagsOpen)
                    printf(" open");
            }
            printf("\n");
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

- (int)readTimeout: (u_int32_t)timeout current_port:(u_int16_t)current_port {
    
    IJTUDP_ScanFlags flags = IJTUDP_ScanFlagsClose;
    struct timeval timestamp = {};
    ssize_t size;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    //ready to read
    while(1) {
        int n;
        fd_set readfd;
        struct timespec tv = {};
        tv.tv_sec = timeout / 1000;
        tv.tv_nsec = timeout % 1000 * 1000;
        struct sockaddr_storage from;
        socklen_t addr_len = sizeof(from);
        struct ip *ip;
        struct icmp *icmp;
        struct ip *ip2;
        struct udphdr *udp;
        char recv_buffer[65535];
        
        FD_ZERO(&readfd);
        FD_SET(self.icmp_fd, &readfd);
        FD_SET(self.udp_fd, &readfd);
        
        if((n = pselect(MAX(self.icmp_fd, self.udp_fd) + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
            goto BAD;
        if(n == 0) {
            flags = IJTUDP_ScanFlagsFiltered | IJTUDP_ScanFlagsOpen;
            gettimeofday(&timestamp, (struct timezone *)0);
            break;
        }
        
        memset(recv_buffer, 0, sizeof(recv_buffer));
        memset(&from, 0, sizeof(struct sockaddr_storage));
        
        if(FD_ISSET(self.icmp_fd, &readfd)) {
            if((size = recvfrom(self.icmp_fd, recv_buffer, sizeof(recv_buffer), 0, (struct sockaddr *)&from, &addr_len)) < 0)
                goto BAD;
            
            struct sockaddr_in *addr = (struct sockaddr_in *)&from;
            if(addr->sin_addr.s_addr != _dest.sin_addr.s_addr)
                continue;
            
            ip = (struct ip *)recv_buffer;
            
            if(ip->ip_p == IPPROTO_ICMP) {
                icmp = (struct icmp *)(recv_buffer + (ip->ip_hl << 2));
                ip2 = (struct ip *)icmp->icmp_data;
                udp = (struct udphdr *)((u_char *)ip2 + (ip2->ip_hl << 2));
                
                //receive icmp, type: 3, code: 3
                if(icmp->icmp_type == ICMP_UNREACH &&
                   icmp->icmp_code == ICMP_UNREACH_PORT &&
                   ip2->ip_p == IPPROTO_UDP &&
                   current_port == ntohs(udp->uh_dport)) {
                    flags = IJTUDP_ScanFlagsClose;
                    gettimeofday(&timestamp, (struct timezone *)0);
                }
                //receive icmp, type: 3, code: 1, 2, 9, 10, 13
                else if(icmp->icmp_type == ICMP_UNREACH &&
                        (icmp->icmp_code == ICMP_UNREACH_HOST || icmp->icmp_code == ICMP_UNREACH_PROTOCOL ||
                         icmp->icmp_code == ICMP_UNREACH_NET_PROHIB || icmp->icmp_code == ICMP_UNREACH_HOST_PROHIB ||
                         icmp->icmp_code == ICMP_UNREACH_FILTER_PROHIB) &&
                        ip2->ip_p == IPPROTO_UDP &&
                        current_port == ntohs(udp->uh_dport)) {
                    flags = IJTUDP_ScanFlagsFiltered;
                    gettimeofday(&timestamp, (struct timezone *)0);
                }
                
            }//end if icmp
        }//end if icmp socket set
        else if(FD_ISSET(self.udp_fd, &readfd)) {
            if((size = recvfrom(self.udp_fd, recv_buffer, sizeof(recv_buffer), 0, (struct sockaddr *)&from, &addr_len)) < 0)
                goto BAD;
            
            struct sockaddr_in *addr = (struct sockaddr_in *)&from;
            if(addr->sin_addr.s_addr != _dest.sin_addr.s_addr)
                continue;
            if(ntohs(addr->sin_port) != current_port)
                continue;
            
            flags = IJTUDP_ScanFlagsOpen;
            gettimeofday(&timestamp, (struct timezone *)0);
        }//end if udp socket set
        else {
            continue;
        }//end else
        
        break;
    }//end while pselect
    
    [dict setValue:@(flags) forKey:@"Flags"];
    [dict setValue:[NSValue valueWithBytes:&timestamp objCType:@encode(struct timeval)] forKey:@"Timestamp"];
    [dict setValue:@(current_port) forKey:@"Port"];
    
    //remove previous
    for(NSUInteger i = 0 ; i < self.replyStatusArray.count ; i++) {
        NSDictionary *dup = [self.replyStatusArray objectAtIndex:i];
        NSNumber *portNumber = [dup valueForKey:@"Port"];
        if([portNumber unsignedShortValue] == current_port) {
            [self.replyStatusArray removeObject:dup];
            break;
        }
    }
    
    [self.replyStatusArray addObject:dict];
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (NSString *)portNameByNumber: (u_int16_t)portNumber {
    struct servent *se; //server information
    se = getservbyport(htons(portNumber), "udp");
    NSString *name = [NSString stringWithUTF8String:se ? se->s_name : "unknown"];
    return name;
}

- (char *)udpPortPayload: (u_int16_t)port length: (int *)length {
    //from nmap-payloads
    
    switch (port) {
        case 7: *length = 4; return "\x0D\x0A\x0D\x0A";
        case 53: *length = 12; return "\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00";
        case 111: *length = 40; return "\x72\xFE\x1D\x13\x00\x00\x00\x00\x00\x00\x00\x02\x00\x01\x86\xA0\x00\x01\x97\x7C\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
        case 123: *length = 48; return "\xE3\x00\x04\xFA\x00\x01\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xC5\x4F\x23\x4B\x71\xB1\x52\xF3";
        case 137: *length = 50; return "\x80\xF0\x00\x10\x00\x01\x00\x00\x00\x00\x00\x00\x20""CKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\x00\x00\x21\x00\x01";
        case 161: *length = 60; return "\x30\x3A\x02\x01\x03\x30\x0F\x02\x02\x4A\x69\x02\x03\x00\xFF\xE3"
            "\x04\x01\x04\x02\x01\x03\x04\x10\x30\x0E\x04\x00\x02\x01\x00\x02"
            "\x01\x00\x04\x00\x04\x00\x04\x00\x30\x12\x04\x00\x04\x00\xA0\x0C"
            "\x02\x02\x37\xF0\x02\x01\x00\x02\x01\x00\x30\x00";
        case 1434: *length = 1; return "\x02";
        case 177: *length = 7; return "\x00\x01\x00\x02\x00\x01\x00";
        case 427: *length = 54; return "\x02\x01\x00\x006 \x00\x00\x00\x00\x00\x01\x00\x02en\x00\x00\x00\x15""service:service-agent\x00\x07""default\x00\x00\x00\x00";
        case 500: *length = 192; return "\x00\x11\x22\x33\x44\x55\x66\x77\x00\x00\x00\x00\x00\x00\x00\x00""\x01\x10\x02\x00\x00\x00\x00\x00\x00\x00\x00\xC0""\x00\x00\x00\xA4\x00\x00\x00\x01\x00\x00\x00\x01""\x00\x00\x00\x98\x01\x01\x00\x04""\x03\x00\x00\x24\x01\x01\x00\x00\x80\x01\x00\x05\x80\x02\x00\x02"
            "\x80\x03\x00\x01\x80\x04\x00\x02""\x80\x0B\x00\x01\x00\x0C\x00\x04\x00\x00\x00\x01""\x03\x00\x00\x24\x02\x01\x00\x00\x80\x01\x00\x05\x80\x02\x00\x01"
            "\x80\x03\x00\x01\x80\x04\x00\x02"
            "\x80\x0B\x00\x01\x00\x0C\x00\x04\x00\x00\x00\x01""\x03\x00\x00\x24\x03\x01\x00\x00\x80\x01\x00\x01\x80\x02\x00\x02"
            "\x80\x03\x00\x01\x80\x04\x00\x02"
            "\x80\x0B\x00\x01\x00\x0C\x00\x04\x00\x00\x00\x01""\x00\x00\x00\x24\x04\x01\x00\x00\x80\x01\x00\x01\x80\x02\x00\x01"
            "\x80\x03\x00\x01\x80\x04\x00\x02"
            "\x80\x0B\x00\x01\x00\x0C\x00\x04\x00\x00\x00\x01";
        case 520: *length = 24; return "\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
            "\x00\x00\x00\x00\x00\x00\x00\x10";
        case 626: *length = 30; return "SNQUERY: 127.0.0.1:AAAAAA:xsvr";
        case 1604: *length = 30; return "\x1e\x00\x01\x30\x02\xfd\xa8\xe3\x00\x00\x00\x00\x00\x00\x00\x00"
            "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
        case 1645:
        case 1812:
            *length = 20; return "\x01\x00\x00\x14"
            "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
        case 2049: *length = 40; return "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x01\x86\xA3"
            "\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
            "\x00\x00\x00\x00\x00\x00\x00\x00";
        case 2302: *length = 21; return "\x00\x02\xf1\x26\x01\x26\xf0\x90\xa6\xf0\x26\x57\x4e\xac\xa0\xec\xf8\x68\xe4\x8d\x21";
        case 6481: *length = 12; return "[PROBE] 0000";
        case 5351: *length = 2; return "\x00\x00";
        case 5353: *length = 46; return "\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00"
            "\x09_services\x07_dns-sd\x04_udp\x05local\x00\x00\x0C\x00\x01";
        case 10080: *length = 54; return "Amanda 2.6 REQ HANDLE 000-00000000 SEQ 0\n"
            "SERVICE noop\n";
        case 17185: *length = 64; return "\x00\x00\x00\x00""\x00\x00\x00\x00\x00\x00\x00\x02""\x55\x55\x55\x55\x00\x00\x00\x01""\x00\x00\x00\x00""\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00""\xff\xff\x55\x13""\x00\x00\x00\x30\x00\x00\x00\x01""\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00";
        case 26000:
        case 26001:
        case 26002:
        case 26003:
        case 26004:
        case 27960:
        case 27961:
        case 27962:
        case 27963:
        case 27964:
        case 30720:
        case 30721:
        case 30722:
        case 30723:
        case 30724:
        case 44400:
            *length = 13; return "\xff\xff\xff\xffgetstatus";
        case 64738: *length = 12; return "\x00\x00\x00\x00""abcdefgh";
        case 3784: *length = 36; return "\x01\xe7\xe5\x75\x31\xa3\x17\x0b\x21\xcf\xbf\x2b\x99\x4e\xdd\x19\xac\xde\x08\x5f\x8b\x24\x0a\x11\x19\xb6\x73\x6f\xad\x28\x13\xd2\x0a\xb9\x12\x75";
        case 8767: *length = 180; return "\xf4\xbe\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x002x\xba\x85\tTeamSpeak\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\nWindows XP\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00 \x00<\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08nickname\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
        case 9987: *length = 162; return "\x05\xca\x7f\x16\x9c\x11\xf9\x89\x00\x00\x00\x00\x02\x9d\x74\x8b\x45\xaa\x7b\xef\xb9\x9e\xfe\xad\x08\x19\xba\xcf\x41\xe0\x16\xa2\x32\x6c\xf3\xcf\xf4\x8e\x3c\x44\x83\xc8\x8d\x51\x45\x6f\x90\x95\x23\x3e\x00\x97\x2b\x1c\x71\xb2\x4e\xc0\x61\xf1\xd7\x6f\xc5\x7e\xf6\x48\x52\xbf\x82\x6a\xa2\x3b\x65\xaa\x18\x7a\x17\x38\xc3\x81\x27\xc3\x47\xfc\xa7\x35\xba\xfc\x0f\x9d\x9d\x72\x24\x9d\xfc\x02\x17\x6d\x6b\xb1\x2d\x72\xc6\xe3\x17\x1c\x95\xd9\x69\x99\x57\xce\xdd\xdf\x05\xdc\x03\x94\x56\x04\x3a\x14\xe5\xad\x9a\x2b\x14\x30\x3a\x23\xa3\x25\xad\xe8\xe6\x39\x8a\x85\x2a\xc6\xdf\xe5\x5d\x2d\xa0\x2f\x5d\x9c\xd7\x2b\x24\xfb\xb0\x9c\xc2\xba\x89\xb4\x1b\x17\xa2\xb6";
        default: *length = 0; return "";
    }
}

- (u_int64_t)getTotalInjectCount {
    return (u_int64_t)self.end_port - (u_int64_t)self.start_port + 1;
}

- (u_int64_t)getRemainInjectCount {
    u_int64_t count = [self getTotalInjectCount] - self.current_index;
    return count <= 0 ? 0 : count;
}

@end
