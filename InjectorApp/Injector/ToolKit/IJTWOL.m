//
//  IJTWOL.m
//  IJTWOL
//
//  Created by 聲華 陳 on 2015/6/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWOL.h"
#import <sys/socket.h>
#import <netinet/ip.h>
#import <arpa/inet.h>
#import <net/ethernet.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <net/bpf.h>
#define WOL_DEFAULT_PORT 9
struct ijt_wol_header {
    u_int8_t wol_sync_stream[6];
    struct ether_addr wol_ether_addr[16];
    u_int8_t wol_password[6]; //only in layer 2
};
@interface IJTWOL ()

@property (nonatomic) int sockfd;
@property (nonatomic) int bpfd;

@end

@implementation IJTWOL

- (id)init {
    self = [super init];
    if(self) {
        self.sockfd = -1;
        self.bpfd = -1;
        [self open];
    }
    return self;
}

- (void)open {
    if(self.sockfd < 0) {
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
    }
    
    char buf[256];
    struct ifreq ifr; //interface
    int n = 0;
    if(self.bpfd < 0) {
        do {
            snprintf(buf, sizeof(buf), "/dev/bpf%d", n++);
            self.bpfd = open(buf, O_RDWR, 0);
        }//end do
        while (self.bpfd < 0 && (errno == EBUSY || errno == EPERM));
        if(self.bpfd < 0)
            goto BAD;
    }//end if
    
    //set interface name
    snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "en0");
    if(ioctl(self.bpfd, BIOCSETIF, &ifr) < 0)
        goto BAD;
    
    //即時模式
    n = 1;
    if(ioctl(self.bpfd, BIOCIMMEDIATE, &n) < 0)
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
        self.bpfd = -1;
    }
}

- (int)wakeUpMacAddress: (NSString *)macAddress
                 target: (id)target
               selector: (SEL)selector
                 object: (id)object {
    
    NSString *wifibroadcastAddr = nil;
    [self sendto:@"255.255.255.255"
      macAddress:macAddress
            port:WOL_DEFAULT_PORT
          target:target
        selector:selector
          object:object];
    if(self.errorHappened)
        goto BAD;
    
    usleep(100);
    
    wifibroadcastAddr = wifiBroadcastAddress();
    if(wifibroadcastAddr) {
        [self sendto:wifibroadcastAddr
          macAddress:macAddress
                port:WOL_DEFAULT_PORT
              target:target
            selector:selector
              object:object];
        if(self.errorHappened)
            goto BAD;
        
        usleep(100);
    }
    
    [self sendToMacAddress:macAddress
        destinationAddress:macAddress
                    target:target
                  selector:selector
                    object:object];
    
    if(self.errorHappened)
        goto BAD;
    
    usleep(100);
    
    [self sendToMacAddress:macAddress
        destinationAddress:@"ff:ff:ff:ff:ff:ff"
                    target:target
                  selector:selector
                    object:object];
    if(self.errorHappened)
        goto BAD;
    
    usleep(100);
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorHappened = YES;
    return -1;
}

- (int)sendto: (NSString *)targetIp
   macAddress: (NSString *)macAddress
         port: (u_int16_t)port
       target: (id)target
     selector: (SEL)selector
       object: (id)object {
    
    struct sockaddr_in dest;
    struct ether_addr *ether;
    WOLCallback wolcallback = NULL;
    char buffer[256];
    struct ijt_wol_header *wolheader;
    
    memset(&dest, 0, sizeof(dest));
    dest.sin_addr.s_addr = inet_addr([targetIp UTF8String]);
    dest.sin_family = AF_INET;
    dest.sin_port = htons(port);
    dest.sin_len = sizeof(struct sockaddr_in);
    
    if(target && selector) {
        wolcallback = (WOLCallback)[target methodForSelector:selector];
    }
    
    ether = ether_aton([macAddress UTF8String]);
    wolheader = (struct ijt_wol_header *)buffer;
    //0xff => 6 times
    for(int i = 0 ; i < 6 ; i++)
        wolheader->wol_sync_stream[i] = 0xff;
    //xx:xx:xx:xx:xx:xx => 16 times after 6 0xff
    for(int i = 0 ; i < 16 ; i++) {
        memcpy(&wolheader->wol_ether_addr[i], ether, sizeof(wolheader->wol_ether_addr));
    }
    
    if((sendto(self.sockfd, buffer, 6+16*6, 0, (struct sockaddr *)&dest, sizeof(dest))) < 0)
        goto BAD;
    
    if(wolcallback) {
        struct timeval timestamp;
        gettimeofday(&timestamp, (struct timezone *)0);
        wolcallback(target, selector, timestamp, macAddress, targetIp, object);
    }
    else {
        printf("Wake up: %s send to %s\n", [macAddress UTF8String],
               [targetIp UTF8String]);
    }
    
    self.errorHappened = NO;
    return 0;
    
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (int)sendToMacAddress: (NSString *)macAddress
     destinationAddress: (NSString *)desntiaonAddress
                 target: (id)target
               selector: (SEL)selector
                 object: (id)object {
    struct ether_addr *ether;
    struct ether_header *ether_header;
    char buffer[256];
    struct ijt_wol_header *wolheader;
    WOLCallback wolcallback = NULL;
    
    if(target && selector) {
        wolcallback = (WOLCallback)[target methodForSelector:selector];
    }
    
    memset(buffer, 0, sizeof(buffer));
    ether_header = (struct ether_header *)buffer;
    ether = ether_aton([desntiaonAddress UTF8String]);
    memcpy(ether_header->ether_dhost, ether, sizeof(ether_header->ether_dhost));
    ether_header->ether_type = htons(0x0842);
    
    wolheader = (struct ijt_wol_header *)(buffer + 14);
    //0xff => 6 times
    for(int i = 0 ; i < 6 ; i++)
        wolheader->wol_sync_stream[i] = 0xff;
    //xx:xx:xx:xx:xx:xx => 16 times after 6 0xff
    ether = ether_aton([macAddress UTF8String]);
    for(int i = 0 ; i < 16 ; i++) {
        memcpy(&wolheader->wol_ether_addr[i], ether, sizeof(wolheader->wol_ether_addr));
    }
    //0x00 => 6 times
    for(int i = 0 ; i < 6 ; i++)
        wolheader->wol_password[i] = 0x00;
    
    if(write(self.bpfd, &buffer, sizeof(buffer)) < 0) {
        goto BAD;
    }
    if(wolcallback) {
        struct timeval timestamp;
        gettimeofday(&timestamp, (struct timezone *)0);
        wolcallback(target, selector, timestamp, macAddress, desntiaonAddress, object);
    }
    else {
        printf("Wake up: %s send to %s\n", [macAddress UTF8String],
               [desntiaonAddress UTF8String]);
    }
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

static NSString *wifiBroadcastAddress() {
    int fd = -1;
    struct ifreq ifr;
    struct in_addr bcast;
    NSString *addr = nil;
    
    if((fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
        return nil;
    
    strlcpy(ifr.ifr_name, "en0", sizeof(ifr.ifr_name));
    
    if (ioctl(fd, SIOCGIFBRDADDR, &ifr) == 0) {
        bcast = ((struct sockaddr_in *)(&ifr.ifr_broadaddr))->sin_addr;
        addr = [NSString stringWithUTF8String:inet_ntoa(bcast)];
    }
    
    close(fd);
    
    return addr;
}

- (int)wakeUpIpAddress: (NSString *)ipAddress
            macAddress: (NSString *)macAddress
                  port: (u_int16_t)port
                target: (id)target
              selector: (SEL)selector
                object: (id)object
{
    return [self sendto:ipAddress
             macAddress:macAddress
                   port:port
                 target:target
               selector:selector
                 object:object];
}

@end
