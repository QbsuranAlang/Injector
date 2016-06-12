//
//  IJTWhois.m
//  IJTWhois
//
//  Created by 聲華 陳 on 2015/6/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWhois.h"
#import <sys/socket.h>
#import <netinet/ip.h>
#import <arpa/inet.h>
#import <sys/param.h>
#import <netdb.h>
@interface IJTWhois ()

@property (nonatomic) int sockfd;

@end

@implementation IJTWhois

- (id)init {
    self = [super init];
    if(self) {
        self.sockfd = -1;
    }
    return self;
}

- (void)open {
    if(self.sockfd < 0) {
        self.sockfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if(self.sockfd < 0)
            goto BAD;
    }
    
    int n = 1, len, maxbuf = -1;
    
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
    
    if(fcntl(self.sockfd, F_SETFL, O_NONBLOCK) < 0)
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

- (NSString *)hostname2IpAddress: (NSString *)ip {
    struct in_addr addr;
    
    struct hostent *hp = gethostbyname2([ip UTF8String], AF_INET);
    if (!hp)
        goto HOSTBAD;
    
    memcpy(&addr, hp->h_addr_list[0], sizeof addr);
    
    self.errorHappened = NO;
    return [NSString stringWithUTF8String:inet_ntoa(addr)];
HOSTBAD:
    self.errorCode = h_errno;
    self.errorHappened = YES;
    return nil;
}

- (int)whois: (NSString *)whoistarget
 whoisServer: (NSString *)server
     timeout: (u_int32_t)timeout
      target: (id)target
    selector: (SEL)selector
      object: (id)object {
    
    //char *response = NULL;
    NSString *response = @"";
    WhoisCallback whoiscallback = NULL;
    
    if(target && selector) {
        whoiscallback = (WhoisCallback)[target methodForSelector:selector];
    }
    
    struct sockaddr_in dest;
    char message[256];
    ssize_t read_size;//, total_size = 0;
    char buffer[65535];
    NSString *serverIp = nil;
    NSString *targetIp = nil;
    
    serverIp = [self hostname2IpAddress:server];
    if(serverIp == nil) {
        goto HOSTBAD;
    }
    targetIp = [self hostname2IpAddress:whoistarget];
    if(targetIp == nil) {
        goto HOSTBAD;
    }
    
    memset(&dest, 0, sizeof(dest));
    dest.sin_addr.s_addr = inet_addr([serverIp UTF8String]);
    dest.sin_family = AF_INET;
    dest.sin_port = htons(43);
    dest.sin_len = sizeof(dest);
    
    //ready to connect
    [self open];
    if(self.errorHappened) {
        goto BAD;
    }
    
    int oldFlags = fcntl(_sockfd, F_GETFL, NULL);
    if(oldFlags < 0)
        goto BAD;
    oldFlags |= O_NONBLOCK;
    if(fcntl(_sockfd, F_SETFL, oldFlags) < 0)
        goto BAD;
    connect(self.sockfd, (const struct sockaddr*) &dest , sizeof(dest));
    
    while(1) {
        fd_set fd;
        struct timespec tv = {};
        int n = 0;
        
        FD_ZERO(&fd);
        FD_SET(_sockfd, &fd);
        tv.tv_sec = timeout / 1000;
        tv.tv_nsec = timeout % 1000 * 1000;
        
        if ((n = pselect(_sockfd + 1, NULL, &fd, NULL, &tv, NULL)) < 0) {
            goto BAD;
        }
        if(n == 0) {
            errno = EHOSTDOWN;
            goto BAD;
        }
        
        if(!FD_ISSET(_sockfd, &fd))
            continue;
        
        //disable block
        int oldFlags = fcntl(_sockfd, F_GETFL, NULL);
        if(oldFlags < 0)
            goto BAD;
        oldFlags &= ~O_NONBLOCK;
        if(fcntl(_sockfd, F_SETFL, oldFlags) < 0)
            goto BAD;
        
        int val;
        int len = sizeof(val);
        getsockopt(_sockfd, SOL_SOCKET, SO_ERROR, (void *)&val, (socklen_t *)&len);
        
        if(val == 0) {
            break; //host up
        }
        else {
            errno = val;
            goto BAD;
        }
    }//end while
    
    int n;
    fd_set readfd;
    struct timespec tv = {};
    tv.tv_sec = timeout / 1000;
    tv.tv_nsec = timeout % 1000 * 1000;
    
    FD_ZERO(&readfd);
    FD_SET(self.sockfd, &readfd);
    if((n = pselect(self.sockfd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
        goto BAD;
    if(n == 0) {
        goto TIMEOUT;
    }
    else if(n == 1) {
        //disable nonblock mode
        int oldfl;
        oldfl = fcntl(self.sockfd, F_GETFL);
        if (oldfl == -1) {
            goto BAD;
        }
        fcntl(self.sockfd, F_SETFL, oldfl & ~O_NONBLOCK);
        
        sprintf(message , "%s\r\n" , [targetIp UTF8String]);
        if(send(self.sockfd, message, strlen(message), 0) < 0) {
            goto BAD;
        }
    }//end connect
    
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
        if(n == 0) {
            goto TIMEOUT;
        }
        
        if(!FD_ISSET(self.sockfd, &readfd))
            continue;
        
        while( (read_size = recv(self.sockfd, buffer , sizeof(buffer) , 0) ) ) {
            
            response = [response stringByAppendingString:[NSString stringWithUTF8String:buffer]];
            /*char *tmp = NULL;
            if(response == NULL) {
                response = malloc(read_size);
            }
            else {
                tmp = response;
                response = realloc(response, read_size + total_size);
            }
            
            if(response == NULL) {
                if(tmp) {
                    free(tmp);
                }
                goto BAD;
            }
            memcpy(response + total_size, buffer, read_size);
            total_size += read_size;*/
        }
        break;
    }
    /*
    response = realloc(response, total_size + 1);
    *(response + total_size) = '\0';
    */
    if(whoiscallback) {
        whoiscallback(target, selector, response, server, object);
    }
    else {
        printf("%s\n", [response UTF8String]);
    }
    
    
    /*if(response)
        free(response);*/
    [self close];
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    /*if(response)
        free(response);*/
    [self close];
    self.errorHappened = YES;
    return -1;
HOSTBAD:
    self.errorCode = h_errno;
    /*if(response)
        free(response);*/
    [self close];
    self.errorHappened = YES;
    return -2;
TIMEOUT:
    /*if(response)
        free(response);*/
    [self close];
    self.errorHappened = YES;
    return 1;
}

+ (NSString *)whoisServerList2String: (IJTWhoisServerList)listnumber {
    switch (listnumber) {
        case IJTWhoisServerListAbuse: return @"whois.abuse.net";
        case IJTWhoisServerListNic: return @"whois.crsnic.net";
        case IJTWhoisServerListInic: return @"whois.networksolutions.com";
        case IJTWhoisServerListDnic: return @"whois.nic.mil";
        case IJTWhoisServerListGnic: return @"whois.nic.gov";
        case IJTWhoisServerListAnic: return @"whois.arin.net";
        case IJTWhoisServerListLnic: return @"whois.lacnic.net";
        case IJTWhoisServerListRnic: return @"whois.ripe.net";
        case IJTWhoisServerListPnic: return @"whois.apnic.net";
        case IJTWhoisServerListMnic: return @"whois.ra.net";
        case IJTWhoisServerListQnicTail: return @"whois-servers.net";
        case IJTWhoisServerListSnic: return @"whois.6bone.net";
        case IJTWhoisServerListBnic: return @"whois.registro.br";
        case IJTWhoisServerListNorid: return @"whois.norid.no";
        case IJTWhoisServerListIana: return @"whois.iana.org";
        case IJTWhoisServerListGermnic: return @"de.whois-servers.net";
        default: return nil;
    }
}

+ (NSArray *)whoisServerList {
    NSMutableArray *list = [[NSMutableArray alloc] init];
    for(IJTWhoisServerList i = IJTWhoisServerListAbuse ; i < IJTWhoisServerListGermnic ; i++) {
        [list addObject:[IJTWhois whoisServerList2String:i]];
    }
    return [NSArray arrayWithArray:list];
}

@end
