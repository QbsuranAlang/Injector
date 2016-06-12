//
//  IJTIfconfig.m
//  IJTIfconfig
//
//  Created by 聲華 陳 on 2015/7/5.
//
//

#import "IJTIfconfig.h"
#import <ifaddrs.h>
#import <sys/socket.h>
#import <errno.h>
#import <netinet/ip.h>
#import <arpa/inet.h>
#import <sys/ioctl.h>
#import <string.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <net/ethernet.h>

@interface IJTIfconfig ()

@end

@implementation IJTIfconfig

- (id)init {
    self = [super init];
    if(self) {
        self.errorHappened = NO;
    }
    return self;
}

- (int)getAllInterfaceRegisterTarget: (id)target
                            selector: (SEL)selector
                              object: (id)object {
    
    struct ifaddrs *if_addrs = NULL;
    IfconfigShowCallback ifconfigshowcallback = NULL;
    
    if(target && selector) {
        ifconfigshowcallback = (IfconfigShowCallback)[target methodForSelector:selector];
    }
    
    if(getifaddrs(&if_addrs) != 0)
        goto BAD;
    
    for (struct ifaddrs *if_addr = if_addrs; if_addr ; if_addr = if_addr->ifa_next) {
        char *name = if_addr->ifa_name;
        int family = if_addr->ifa_addr->sa_family;
        char ntop_buf[256];
        char address[INET_ADDRSTRLEN | INET6_ADDRSTRLEN | (6*2+5) + 1];
        char netmask[INET_ADDRSTRLEN | INET6_ADDRSTRLEN + 1];
        char dstAddress[INET_ADDRSTRLEN | INET6_ADDRSTRLEN + 1];
        struct ifreq ifr;
        int mtu = -1;
        unsigned short flags = -1;
        int errorCode = -1;
        unsigned int ifindex = if_nametoindex(name);
        int s;
        
        if(family != AF_INET && family != AF_INET6 && family != AF_LINK)
            continue;
        
        memset(address, 0, sizeof(address));
        memset(netmask, 0, sizeof(netmask));
        memset(dstAddress, 0, sizeof(dstAddress));
        
        if(family == AF_INET) {
            inet_ntop(AF_INET,
                      &((struct sockaddr_in *)if_addr->ifa_addr)->sin_addr,
                      ntop_buf, sizeof(ntop_buf));
            strlcpy(address, ntop_buf, sizeof(address));
        }
        else if(family == AF_INET6) {
            inet_ntop(AF_INET6,
                      &((struct sockaddr_in6 *)if_addr->ifa_addr)->sin6_addr,
                      ntop_buf, sizeof(ntop_buf));
            strlcpy(address, ntop_buf, sizeof(address));
        }
        else if(family == AF_LINK && if_addr->ifa_addr) {
            struct sockaddr_dl* sdl = (struct sockaddr_dl *)if_addr->ifa_addr;
            strlcpy(address, [IJTIfconfig sdl2string:sdl], sizeof(address));
        }
        
        if(if_addr->ifa_netmask) {
            if(family == AF_INET) {
                inet_ntop(AF_INET,
                          &((struct sockaddr_in *)if_addr->ifa_netmask)->sin_addr,
                          ntop_buf, sizeof(ntop_buf));
                strlcpy(netmask, ntop_buf, sizeof(netmask));
            }
            else if(family == AF_INET6) {
                inet_ntop(AF_INET6,
                          &((struct sockaddr_in6 *)if_addr->ifa_netmask)->sin6_addr,
                          ntop_buf, sizeof(ntop_buf));
                strlcpy(netmask, ntop_buf, sizeof(netmask));
            }
        }
        
        if(if_addr->ifa_dstaddr) {
            if(family == AF_INET) {
                inet_ntop(AF_INET,
                          &((struct sockaddr_in *)if_addr->ifa_dstaddr)->sin_addr,
                          ntop_buf, sizeof(ntop_buf));
                strlcpy(dstAddress, ntop_buf, sizeof(dstAddress));
            }
            else if(family == AF_INET6) {
                inet_ntop(AF_INET6,
                          &((struct sockaddr_in6 *)if_addr->ifa_dstaddr)->sin6_addr,
                          ntop_buf, sizeof(ntop_buf));
                strlcpy(dstAddress, ntop_buf, sizeof(dstAddress));
            }
        }
        
        memset(&ifr, 0, sizeof(ifr));
        strlcpy(ifr.ifr_name, name, sizeof(ifr.ifr_name));
        ifr.ifr_addr.sa_family = family == AF_LINK ? AF_INET : family;
        s = socket(ifr.ifr_addr.sa_family, SOCK_DGRAM, 0);
        if(s < 0) {
            errorCode = errno;
            printf("%s\n", strerror(errorCode));
        }
        else {
            if(ioctl(s, SIOCGIFMTU, &ifr) < 0) {
                mtu = -1;
                errorCode = errno;
            }
            else {
                mtu = ifr.ifr_mtu;
            }
            if(ioctl(s, SIOCGIFFLAGS, &ifr) < 0) {
                flags = -1;
                errorCode = errno;
            }
            else {
                flags = ifr.ifr_flags;
            }
        }
        close(s);
        
        if(ifconfigshowcallback) {
            if(errorCode == -1) {
                ifconfigshowcallback(target, selector,
                                     [NSString stringWithUTF8String:name],
                                     ifindex, family,
                                     [NSString stringWithUTF8String:address],
                                     [NSString stringWithUTF8String:netmask],
                                     [NSString stringWithUTF8String:dstAddress],
                                     mtu, flags, NO, 0, object);
            }
            else {
                ifconfigshowcallback(target, selector,
                                     [NSString stringWithUTF8String:name],
                                     ifindex, family,
                                     [NSString stringWithUTF8String:address],
                                     [NSString stringWithUTF8String:netmask],
                                     [NSString stringWithUTF8String:dstAddress],
                                     mtu, flags, YES, errorCode, object);
            }
        }
        else {
            printf("Interface: %s(%d), Type: ", name, ifindex);
            if(family == AF_INET) {
                printf("Internet4");
            }
            else if(family == AF_INET6) {
                printf("Internet6");
            }
            else if(family == AF_LINK) {
                printf("Link");
            }
            printf(", Address: %s, netmask: %s, dstAddress: %s, MTU: %d, ", address, netmask, dstAddress, mtu);
            printf("Flags: (%#x)%s\n", flags, [[IJTIfconfig interfaceFlags2String:flags] UTF8String]);
        }
    }
    
    if(if_addrs)
        freeifaddrs(if_addrs);
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(if_addrs)
        freeifaddrs(if_addrs);
    self.errorHappened = YES;
    return -1;
}

+ (char *)sdl2string: (struct sockaddr_dl *)sdl {
    static char buf[256];
    char *cp;
    int n, bufsize = sizeof (buf), p = 0;
    
    bzero(buf, sizeof (buf));
    cp = (char *)LLADDR(sdl);
    if ((n = sdl->sdl_alen) > 0) {
        while (--n >= 0)
            p += snprintf(buf + p, bufsize - p, "%02x%s",
                          *cp++ & 0xff, n > 0 ? ":" : "");
    }
    return (buf);
}

- (int)getMtuAtInterface: (NSString *)interface {
    struct ifreq ifr;
    sa_family_t type = 0;
    int s = -1;
    
    strlcpy(ifr.ifr_name, [interface UTF8String], sizeof(ifr.ifr_name));
    type = [self getInterfaceFamily:interface];
    
    if(self.errorHappened) {
        errno = self.errorCode;
        goto BAD;
    }
    ifr.ifr_addr.sa_family = type == AF_LINK ? AF_INET : type;
    
    if((s = socket(ifr.ifr_addr.sa_family, SOCK_DGRAM, 0)) < 0) {
        goto BAD;
    }
    
    if(ioctl(s, SIOCGIFMTU, &ifr) < 0) {
        goto BAD;
    }
    
    close(s);
    
    self.errorHappened = NO;
    return ifr.ifr_mtu;
BAD:
    self.errorCode = errno;
    if(s >= 0)
        close(s);
    self.errorHappened = YES;
    return -1;
}

- (int)setMtuAtInterface: (NSString *)interface
                     mtu: (int)mtu {
    struct ifreq ifr;
    sa_family_t type = 0;
    int s = -1;
    
    strlcpy(ifr.ifr_name, [interface UTF8String], sizeof(ifr.ifr_name));
    type = [self getInterfaceFamily:interface];
    
    if(self.errorHappened) {
        errno = self.errorCode;
        goto BAD;
    }
    ifr.ifr_addr.sa_family = type == AF_LINK ? AF_INET : type;
    
    if((s = socket(ifr.ifr_addr.sa_family, SOCK_DGRAM, 0)) < 0) {
        goto BAD;
    }
    
    if(ioctl(s, SIOCGIFMTU, &ifr) < 0) {
        goto BAD;
    }
    
    ifr.ifr_mtu = mtu;
    
    if(ioctl(s, SIOCSIFMTU, &ifr) < 0) {
        goto BAD;
    }
    close(s);
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(s >= 0)
        close(s);
    self.errorHappened = YES;
    return -1;
}

- (IJTIfconfigFlag)getFlagAtInterface: (NSString *)interface {
    struct ifreq ifr;
    sa_family_t type = 0;
    int s = -1;
    
    strlcpy(ifr.ifr_name, [interface UTF8String], sizeof(ifr.ifr_name));
    type = [self getInterfaceFamily:interface];
    
    if(self.errorHappened) {
        errno = self.errorCode;
        goto BAD;
    }
    ifr.ifr_addr.sa_family = type == AF_LINK ? AF_INET : type;
    
    if((s = socket(ifr.ifr_addr.sa_family, SOCK_DGRAM, 0)) < 0) {
        goto BAD;
    }
    
    if(ioctl(s, SIOCGIFFLAGS, &ifr) < 0) {
        goto BAD;
    }
    
    close(s);
    
    self.errorHappened = NO;
    return ifr.ifr_flags;
BAD:
    self.errorCode = errno;
    if(s >= 0)
        close(s);
    self.errorHappened = YES;
    return -1;
}

- (int)enableFlagAtInterface: (NSString *)interface
                       flags: (IJTIfconfigFlag)flags {
    struct ifreq ifr;
    sa_family_t type = 0;
    int s = -1;
    
    strlcpy(ifr.ifr_name, [interface UTF8String], sizeof(ifr.ifr_name));
    type = [self getInterfaceFamily:interface];
    
    if(self.errorHappened) {
        errno = self.errorCode;
        goto BAD;
    }
    ifr.ifr_addr.sa_family = type == AF_LINK ? AF_INET : type;
    
    if((s = socket(ifr.ifr_addr.sa_family, SOCK_DGRAM, 0)) < 0) {
        goto BAD;
    }
    
    if(ioctl(s, SIOCGIFFLAGS, &ifr) < 0) {
        goto BAD;
    }
    
    ifr.ifr_flags |= flags;
    
    if(ioctl(s, SIOCSIFFLAGS, &ifr) < 0) {
        goto BAD;
    }
    close(s);
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(s >= 0)
        close(s);
    self.errorHappened = YES;
    return -1;
}

- (int)disableFlagAtInterface: (NSString *)interface
                        flags: (IJTIfconfigFlag)flags {
    struct ifreq ifr;
    sa_family_t type = 0;
    unsigned short oldflags = 0;
    int s = -1;
    
    strlcpy(ifr.ifr_name, [interface UTF8String], sizeof(ifr.ifr_name));
    type = [self getInterfaceFamily:interface];
    
    if(self.errorHappened) {
        errno = self.errorCode;
        goto BAD;
    }
    ifr.ifr_addr.sa_family = type == AF_LINK ? AF_INET : type;
    
    if((s = socket(ifr.ifr_addr.sa_family, SOCK_DGRAM, 0)) < 0) {
        goto BAD;
    }
    
    if(ioctl(s, SIOCGIFFLAGS, &ifr) < 0) {
        goto BAD;
    }
    
    oldflags = ifr.ifr_flags;
    ifr.ifr_flags ^= flags;
    ifr.ifr_flags &= oldflags;
    
    if(ioctl(s, SIOCSIFFLAGS, &ifr) < 0) {
        goto BAD;
    }
    close(s);
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(s >= 0)
        close(s);
    self.errorHappened = YES;
    return -1;
}

- (int)setFlagAtInterface: (NSString *)interface
                    flags: (IJTIfconfigFlag)flags {
    
    struct ifreq ifr;
    sa_family_t type = 0;
    int s = -1;
    
    strlcpy(ifr.ifr_name, [interface UTF8String], sizeof(ifr.ifr_name));
    type = [self getInterfaceFamily:interface];
    
    if(self.errorHappened) {
        errno = self.errorCode;
        goto BAD;
    }
    ifr.ifr_addr.sa_family = type == AF_LINK ? AF_INET : type;
    
    if((s = socket(ifr.ifr_addr.sa_family, SOCK_DGRAM, 0)) < 0) {
        goto BAD;
    }
    
    if(ioctl(s, SIOCGIFFLAGS, &ifr) < 0) {
        goto BAD;
    }
    
    ifr.ifr_flags = flags;
    
    if(ioctl(s, SIOCSIFFLAGS, &ifr) < 0) {
        goto BAD;
    }
    close(s);
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(s >= 0)
        close(s);
    self.errorHappened = YES;
    return -1;
}

- (sa_family_t)getInterfaceFamily: (NSString *)interface {
    struct ifaddrs *if_addrs = NULL;
    sa_family_t type = 0;
    
    if(getifaddrs(&if_addrs) != 0)
        goto BAD;
    
    for (struct ifaddrs *if_addr = if_addrs; if_addr ; if_addr = if_addr->ifa_next) {
        if(!strcmp(if_addr->ifa_name, [interface UTF8String])) {
            type = if_addr->ifa_addr->sa_family;
            break;
        }
    }
    
    if(type == 0) {
        errno = ENOENT;
        goto BAD;
    }
    
    freeifaddrs(if_addrs);
    self.errorHappened = NO;
    return type;
BAD:
    self.errorCode = errno;
    if(if_addrs)
        freeifaddrs(if_addrs);
    self.errorHappened = YES;
    return -1;
}

- (int)setIpAddressAtInterface: (NSString *)interface
                     ipAddress: (NSString *)address {
    struct ifreq ifr;
    int s = -1;
    struct sockaddr_in sock4;
    
    strlcpy(ifr.ifr_name, [interface UTF8String], sizeof(ifr.ifr_name));
    
    if((s = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        goto BAD;
    }
    
    memset(&sock4, 0, sizeof(sock4));
    sock4.sin_family = AF_INET;
    inet_pton(AF_INET, [address UTF8String], &sock4.sin_addr);
    memcpy((struct sockaddr_in *)&ifr.ifr_addr, &sock4, sizeof(struct sockaddr_in));
    
    if(ioctl(s, SIOCSIFADDR, &ifr) < 0) {
        goto BAD;
    }
    
    close(s);
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(s)
        close(s);
    self.errorHappened = YES;
    return -1;
}

struct t_flags {
    uint16_t	t_mask;
    char	*t_val;
} if_bits[] = {
    {IJTIfconfigFlagUp,	"UP" },
    {IJTIfconfigFlagBroadcast, "BROADCAST" },
    {IJTIfconfigFlagDebug, "DEBUG" },
    {IJTIfconfigFlagLoopback, "LOOPBACK" },
    {IJTIfconfigFlagP2P, "POINTOPOINT" },
    {IJTIfconfigFlagSmart, "SMART" },
    {IJTIfconfigFlagRunning, "RUNNING" },
    {IJTIfconfigFlagNoArp, "NOARP" },
    {IJTIfconfigFlagPromisc, "PROMISC" },
    {IJTIfconfigFlagAllMulticast, "ALLMULTI" },
    {IJTIfconfigFlagOActive, "OACTIVE" },
    {IJTIfconfigFlagSimplex, "SIMPLEX" },
    {IJTIfconfigFlagLink0, "LINK0" },
    {IJTIfconfigFlagLink1, "LINK1" },
    {IJTIfconfigFlagLink2, "LINK2" },
    {IJTIfconfigFlagMulticast, "MULTICAST" },
    { 0 }
};

+ (NSString *)interfaceFlags2String: (IJTIfconfigFlag)f {
    char name[512];
    struct t_flags *p = if_bits;
    memset(name, 0, sizeof(name));
    
    for (int i = 0 ; i < 16 ; p++, i++) {
        if (p->t_mask & f) {
            if(strlen(name) == 0) {
                snprintf(name, sizeof(name), "%s%s", name, p->t_val);
            }
            else {
                snprintf(name, sizeof(name), "%s\n%s", name, p->t_val);
            }
        }
    }
    
    return [NSString stringWithUTF8String:name];
}


@end
