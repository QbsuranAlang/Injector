//
//  IJTTracepath.m
//  IJTTracepath
//
//  Created by 聲華 陳 on 2015/4/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTTracepath.h"
#import <sys/socket.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <netinet/udp.h>
#import <sys/sysctl.h>
#import <netinet/ip.h>
#import <netinet/ip_icmp.h>
@interface IJTTracepath ()

@property (nonatomic) int sockfd;
@property (nonatomic) u_short destport;
@property (nonatomic, strong) NSString *hostname;
@property (nonatomic) struct sockaddr_in sin;
@property (nonatomic) u_int32_t start_port;
@property (nonatomic) u_int32_t end_port;

@end

@implementation IJTTracepath

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
    self.end_port = endPort;
    self.destport = startPort;
}

- (int)traceStartTTL: (u_int8_t)startTTL
              maxTTL: (u_int8_t)maxTTL
                 tos: (u_int8_t)tos
             timeout: (u_int32_t)timeout
            sourceIP: (NSString *)sourceIP
         payloadSize: (u_int32_t)payload
                stop: (BOOL *)stop
        skipHostname: (BOOL)skipHostname
          targetRecv: (id)targetRecv
        selectorRecv: (SEL)selectorRecv
          objectRecv: (id)objectRecv
       targetTimeout: (id)targetTimeout
     selectorTimeout: (SEL)selectorTimeout
       objectTimeout: (id)objectTimeout {
    char sendbuffer[IP_MAXPACKET];
    char recvbuffer[IP_MAXPACKET];
    struct ip *sendip = NULL;
    struct udphdr *sendudp = NULL;
    struct ip *recvip1 = NULL;
    struct icmp *recvicmp = NULL;
    struct ip *recvip2 = NULL;
    struct udphdr *recvudp = NULL;
    ssize_t sizebuffer = 0;
    struct timeval tvsend;
    struct timeval tvrecv;
    TracepathTimeoutCallback tracepathtimeoutcallback = NULL;
    TracepathCallback tracepathcallback = NULL;
    int found = 0;
    
    //check payload length
    if(payload > TRACEPATH_MAXSIZE) {
        errno = EMSGSIZE;
        goto BAD;
    }
    
    struct in_addr source;
    
    if(targetTimeout && selectorTimeout) {
        tracepathtimeoutcallback = (TracepathTimeoutCallback)[targetTimeout methodForSelector:selectorTimeout];
    }
    
    if(targetRecv && selectorRecv) {
        tracepathcallback = (TracepathCallback)[targetRecv methodForSelector:selectorRecv];
    }
    
    if(sourceIP) {
        if(inet_aton([sourceIP UTF8String], &source) == 0)
            goto BAD;
    }
    else {
        source.s_addr = INADDR_ANY;
    }
    
    memset(sendbuffer, 0, sizeof(*sendbuffer));
    
    //ip header
    sendip = (struct ip *)sendbuffer;
    sendip->ip_v = IPVERSION;
    sendip->ip_hl = sizeof(struct ip) >> 2;
    sendip->ip_tos = tos;
    sendip->ip_id = 0;
    sendip->ip_p = IPPROTO_UDP;
    sendip->ip_src.s_addr = source.s_addr;
    sendip->ip_dst.s_addr = _sin.sin_addr.s_addr;
    /**
     *http://cseweb.ucsd.edu/~braghava/notes/freebsd-sockets.txt
     *FreeBSD bug
     *- ip_len and ip_off must be in host byte order
     */
    sendip->ip_len = sizeof(struct ip) + sizeof(struct udphdr) + payload;
    sendip->ip_off = 0;
    
    //udp header
    sendudp = (struct udphdr *)(sendbuffer + sizeof(struct ip));
    sendudp->uh_ulen = htons(sizeof(struct udphdr) + payload);
    sendudp->uh_sport = htons(arc4random() % 16384 + 49152);
    sendudp->uh_sum = 0;
    
    for(int ttl = startTTL ; ttl <= maxTTL ;ttl++) {
        //ip header
        sendip->ip_ttl = ttl;
        sendip->ip_sum = checksum((u_short *)sendip, sendip->ip_hl << 2);

        //send 3 udp packet
        for(int i = 0 ; i < 3 ; i++) {
            
            if(stop && *stop)
                goto OK;
            usleep(400000);
            
            //udp header
            sendudp->uh_dport = htons(self.destport);
            
            gettimeofday(&tvsend, (struct timezone *)0);
            if((sizebuffer = sendto(self.sockfd, sendbuffer, sendip->ip_len,
                      0, (struct sockaddr *)&_sin, (socklen_t)sizeof(_sin))) < 0)
                goto BAD;
            
            if(sizebuffer != sendip->ip_len)
                goto BAD;
            
            //ready to read
            while(1) {
                int n;
                fd_set readfd;
                struct timespec tv = {};
                tv.tv_sec = timeout / 1000;
                tv.tv_nsec = timeout % 1000 * 1000;
                
                FD_ZERO(&readfd);
                FD_SET(self.sockfd, &readfd);
                if((n = pselect(self.sockfd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
                    goto BAD;
                
                if(n == 0) { //timeout
                    struct timeval timestamp;
                    gettimeofday(&timestamp, (struct timezone *)0);
                    
                    if(tracepathtimeoutcallback) {
                        tracepathtimeoutcallback(targetTimeout, selectorTimeout, i+1, ttl, timestamp, objectTimeout);
                    }
                    else {
                        printf("%3d *\n", ttl);
                        fflush(stdout);
                    }
                    break;
                }
                
                if(!FD_ISSET(self.sockfd, &readfd))
                    continue;
                
                memset(recvbuffer, 0, sizeof(recvbuffer));
                if((sizebuffer = recvfrom(self.sockfd, recvbuffer, sizeof(recvbuffer), 0, NULL, NULL)) < 0)
                    goto BAD;
                
                gettimeofday(&tvrecv, (struct timezone *)0);
                
                recvip1 = (struct ip *)recvbuffer;
                
                if(recvip1->ip_p != IPPROTO_ICMP)
                    continue;
                
                recvicmp = (struct icmp *)(recvbuffer + (recvip1->ip_hl << 2));
                recvip2 = (struct ip *)(recvbuffer + (recvip1->ip_hl << 2) + ICMP_MINLEN);
                recvudp = (struct udphdr *)(recvbuffer + (recvip1->ip_hl << 2) + ICMP_MINLEN + (recvip2->ip_hl << 2));
                
                if(recvip2->ip_dst.s_addr == _sin.sin_addr.s_addr && recvudp->uh_sport == sendudp->uh_sport && recvudp->uh_dport == sendudp->uh_dport) {
                    struct timeval tvrtt = tvsub(tvrecv, tvsend);
                    double RTT = tvrtt.tv_sec * 1000.0 + tvrtt.tv_usec/1000.0;
                    NSString *ipAddress = [NSString stringWithUTF8String:inet_ntoa(recvip1->ip_src)];
                    NSString *hostname = @"";
                    if(!skipHostname)
                        hostname = [NSString stringWithUTF8String:inetname(recvip1->ip_src)];
                    
                    if(recvip1->ip_src.s_addr == _sin.sin_addr.s_addr)
                        found = 1;
                    
                    if(tracepathcallback) {
                        tracepathcallback(targetRecv, selectorRecv, i+1, found, ipAddress, hostname, RTT, ttl, recvicmp->icmp_type, recvicmp->icmp_code, (int)sizebuffer, objectRecv);
                    }
                    else {
                        printf("%3d %s(%s) %8.4f ms, len: %zd\n", ttl, inetname(recvip1->ip_src), inet_ntoa(recvip1->ip_src), RTT, sizebuffer);
                    
                        fflush(stdout);
                    }//end else
                    break;
                }//end if recv
            }//end while recv
            self.destport = self.destport > self.end_port ? self.start_port : self.destport + 1;
        }//end 3 udp packet
        
        //got destination
        if(found)
            break;
        if(!tracepathtimeoutcallback || !tracepathcallback)
            printf("\n");
    }//end while
    
OK:
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

static char * inetname(struct in_addr inaddr) {
    register char *cp;
    register struct hostent *hp;
    static char domain[MAXHOSTNAMELEN + 1], line[MAXHOSTNAMELEN + 1];
    
    if (gethostname(domain, sizeof(domain) - 1) < 0)
        domain[0] = '\0';
    else {
        cp = strchr(domain, '.');
        if (cp == NULL) {
            hp = gethostbyname(domain);
            if (hp != NULL)
                cp = strchr(hp->h_name, '.');
        }
        if (cp == NULL)
            domain[0] = '\0';
        else {
            ++cp;
            (void)strncpy(domain, cp, sizeof(domain) - 1);
            domain[sizeof(domain) - 1] = '\0';
        }
    }
    
    if (inaddr.s_addr != INADDR_ANY) {
        hp = gethostbyaddr((char *)&inaddr, sizeof(inaddr), AF_INET);
        if (hp != NULL) {
            if ((cp = strchr(hp->h_name, '.')) != NULL &&
                strcmp(cp + 1, domain) == 0)
                *cp = '\0';
            (void)strncpy(line, hp->h_name, sizeof(line) - 1);
            line[sizeof(line) - 1] = '\0';
            return (line);
        }
    }
    return (inet_ntoa(inaddr));
}

static struct timeval tvsub(struct timeval time1, struct timeval time2) {
    if ((time1.tv_usec -= time2.tv_usec) < 0) {
        time1.tv_sec--;
        time1.tv_usec += 1000000;
    }
    time1.tv_sec -= time2.tv_sec;
    return time1;
}

@end
