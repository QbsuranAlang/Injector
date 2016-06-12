//
//  IJTConnect-Scan.m
//  IJTConnect Scan
//
//  Created by 聲華 陳 on 2015/8/23.
//
//

#import "IJTConnect-Scan.h"
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <netdb.h>
#import <arpa/inet.h>
@interface IJTConnect_Scan ()

@property (nonatomic, strong) NSString *hostname;
@property (nonatomic) struct sockaddr_in sin;
@property (nonatomic) struct sockaddr_in dest;
@property (nonatomic) u_int32_t start_port;
@property (nonatomic) u_int32_t end_port;
@property (nonatomic) u_int32_t current_index;

@end

@implementation IJTConnect_Scan

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
    
    memset(&_dest, 0, sizeof(_dest));
    _dest.sin_family = AF_INET;
    _dest.sin_addr.s_addr = _sin.sin_addr.s_addr;
    
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

- (int)connectScanStop: (BOOL *)stop
         randomization: (BOOL)randomization
               timeout: (u_int32_t)timeout
              interval: (useconds_t)interval
                target: (id)target
              selector: (SEL)selector
                object: (id)object {
    
    ConnectScanCallback connectscancallback = NULL;
    int s = -1;
    u_int32_t *port_list = NULL;
    if(target && selector) {
        connectscancallback = (ConnectScanCallback)[target methodForSelector:selector];
    }
    
    u_int32_t total = (u_int32_t)[self getTotalInjectCount];
    port_list = (u_int32_t *)malloc(total * sizeof(u_int32_t));
    if(!port_list)
        goto BAD;
    memset(port_list, 0, total*sizeof(u_int32_t));
    
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
    close(s);
    s = -1;
    
    for(_current_index = 0 ; _current_index < total ; _current_index++) {
        if(stop && *stop)
            break;
        
        s = socket(AF_INET, SOCK_STREAM, 0);
        if(s < 0)
            goto BAD;
        
        _dest.sin_port = htons(port_list[_current_index]);
        
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
                struct servent *se; //server information
                
                se = getservbyport(htons(port_list[_current_index]), "tcp");
                NSString *name = [NSString stringWithUTF8String:se ? se->s_name : "unknown"];
                
                if(connectscancallback) {
                    connectscancallback(target, selector, port_list[_current_index], name, IJTConnect_ScanFlagsClose, object);
                }
                else {
                    printf("%5d %-20s, close\n", port_list[_current_index], [name UTF8String]);
                }
                break;
            }
            if(!FD_ISSET(s, &fd))
                continue;
            
            struct servent *se; //server information
            
            se = getservbyport(htons(port_list[_current_index]), "tcp");
            NSString *name = [NSString stringWithUTF8String:se ? se->s_name : "unknown"];
            
            //disable block
            int oldFlags = fcntl(s, F_GETFL, NULL);
            if(oldFlags < 0)
                goto BAD;
            oldFlags &= ~O_NONBLOCK;
            if(fcntl(s, F_SETFL, oldFlags) < 0)
                goto BAD;
            
            int val;
            socklen_t len;
            getsockopt(s, SOL_SOCKET, SO_ERROR, (void*)&val, &len);
            
            if(val == 0) {
                if(connectscancallback) {
                    connectscancallback(target, selector, port_list[_current_index], name, IJTConnect_ScanFlagsOpen, object);
                }
                else {
                    printf("%5d %-20s, open\n", port_list[_current_index], [name UTF8String]);
                }
            }
            else if(val == ECONNREFUSED) {
                
                if(connectscancallback) {
                    connectscancallback(target, selector, port_list[_current_index], name, IJTConnect_ScanFlagsClose, object);
                }
                else {
                    printf("%5d %-20s, close\n", port_list[_current_index], [name UTF8String]);
                }
            }
            else {
                errno = val;
                goto BAD;
            }
            
            break;
        }//end while
        
        fflush(stdout);
        close(s);
        s = -1;
        usleep(interval);
    }//end for
    
OK:
    if(s >= 0)
        close(s);
    if(port_list)
        free(port_list);
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(s >= 0)
        close(s);
    if(port_list)
        free(port_list);
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

- (u_int64_t)getTotalInjectCount {
    return (u_int64_t)self.end_port - (u_int64_t)self.start_port + 1;
}

- (u_int64_t)getRemainInjectCount {
    u_int64_t count = [self getTotalInjectCount] - self.current_index;
    return count <= 0 ? 0 : count;
}

@end
