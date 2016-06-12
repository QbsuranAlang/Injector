//
//  IJTSSDP.m
//  IJTSSDP
//
//  Created by 聲華 陳 on 2015/8/31.
//
//

#import "IJTSSDP.h"
#import <sys/socket.h>
#import <arpa/inet.h>
#import <netinet/ip.h>
#import <net/if.h>
#import <sys/ioctl.h>

@interface IJTSSDP ()

@property (nonatomic) int sockfd;

@end
@implementation IJTSSDP

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

- (int)injectTargetIpAddress: (NSString *)ipAddress
                     timeout: (u_int32_t)timeout
                      target: (id)target
                    selector: (SEL)selector
                      object: (id)object {
    
    struct sockaddr_in dst;
    memset(&dst, 0, sizeof(dst));
    dst.sin_family = AF_INET;
    dst.sin_port = htons(1900);
    if(inet_pton(AF_INET, [ipAddress UTF8String], &dst.sin_addr) == -1)
        goto BAD;
    
    char buffer[65535] = "";
    snprintf(buffer, sizeof(buffer),
             "M-SEARCH * HTTP/1.1\r\n"
             "HOST: %s\r\n"
             "MAN: \"ssdp:discover\"\r\n"
             "MX: 3\r\n"
             "ST: upnp:rootdevice\r\n\r\n", [ipAddress UTF8String]);

    int length = 101;
    ssize_t sizelen = 0;
    SSDPCallback ssdpcallback = NULL;
    
    //if need callback
    if(target && selector) {
        ssdpcallback = (SSDPCallback)[target methodForSelector:selector];
    }
    
    if((sizelen = sendto(self.sockfd, buffer, length, 0, (struct sockaddr*)&dst,sizeof(dst))) < 0) {
        goto BAD;
    }
    
    if(sizelen != length)
        goto BAD;
    
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
        if((sizelen = recvfrom(self.sockfd, buffer, sizeof(buffer), 0, (struct sockaddr *)&from, &addr_len)) < 0)
            goto BAD;
        
        struct sockaddr_in *addr = (struct sockaddr_in *)&from;
        if(ntohs(addr->sin_port) != 1900) {
            continue;
        }
        
        char ntop_buf[256];
        NSString *source = [NSString stringWithUTF8String:
                            inet_ntop(from.ss_family, &addr->sin_addr, ntop_buf, sizeof(ntop_buf))];
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:
                                 [[NSString stringWithUTF8String:buffer] componentsSeparatedByString:@"\r\n"]];
        NSString *location = nil;
        NSString *server = nil;
        for(NSString *field in array) {
            if([field hasPrefix:@"LOCATION: "]) {
                location = [field substringWithRange:NSMakeRange(@"LOCATION: ".length, field.length - @"LOCATION: ".length)];
            }
            if([field hasPrefix:@"SERVER: "]) {
                server = [field substringWithRange:NSMakeRange(@"SERVER: ".length, field.length - @"SERVER: ".length)];
            }
        }
        
        /*
        //get locaiton server
        NSRange range = [location rangeOfString:@"http://"];
        if (range.location != NSNotFound) {
            location = [location substringWithRange:NSMakeRange(range.length, location.length - range.length)];
            range = [location rangeOfString:@":"];
            if(range.location != NSNotFound) {
                location = [location substringWithRange:NSMakeRange(0, range.location)];
            }
        }//end if*/
        
        //get names
        array = [NSMutableArray arrayWithArray:[server componentsSeparatedByString:@" "]];
        if(array.count != 3)
            continue;
        NSString *os = array[0];
        NSString *osVersion = nil;
        NSString *upnp = array[1];
        NSString *upnpVersion = nil;
        NSString *product = array[2];
        NSString *productVersion = nil;
        
        NSRange range = [os rangeOfString:@"/"];
        if (range.location != NSNotFound) {
            osVersion = [os substringWithRange:NSMakeRange(range.location + 1, os.length - range.location - 1)];
            os = [os substringWithRange:NSMakeRange(0, range.location)];
        }//end if
        
        range = [upnp rangeOfString:@"/"];
        if (range.location != NSNotFound) {
            upnpVersion = [upnp substringWithRange:NSMakeRange(range.location + 1, upnp.length - range.location - 1)];
            upnp = [upnp substringWithRange:NSMakeRange(0, range.location)];
        }//end if
        
        range = [product rangeOfString:@"/"];
        if (range.location != NSNotFound) {
            productVersion = [product substringWithRange:NSMakeRange(range.location + 1, product.length - range.location - 1)];
            product = [product substringWithRange:NSMakeRange(0, range.location)];
        }//end if
        
        if(ssdpcallback) {
            ssdpcallback(target, selector, source, location, os, osVersion, upnp, upnpVersion, product, productVersion, object);
        }
        else {
            NSLog(@"%@ %@", source, location);
            NSLog(@"%@ %@", os, osVersion);
            NSLog(@"%@ %@", upnp, upnpVersion);
            NSLog(@"%@ %@", product, productVersion);
        }
    }//end while
    
    
OK:
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}


@end
