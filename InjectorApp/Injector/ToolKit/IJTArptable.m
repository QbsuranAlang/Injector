//
//  IJTArptable.m
//  IJTArptable
//
//  Created by 聲華 陳 on 2015/4/11.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArptable.h"
#import <net/route.h>
#import <netinet/in.h>
#import <if_ether.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/sysctl.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <if_types.h>
#import <sys/ioctl.h>
typedef enum {
    GETALL = 0,
    DELETEALL = 1
} Action;

#define ROUNDUP(a) \
((a) > 0 ? (1 + (((a) - 1) | (sizeof(long) - 1))) : sizeof(long))

@interface IJTArptable ()

@property (nonatomic) int sockfd;
@property (nonatomic) pid_t pid;
@property (nonatomic) struct sockaddr_in so_mask;
@property (nonatomic) struct sockaddr_inarp blank_sin, sin_m;
@property (nonatomic) struct sockaddr_dl blank_sdl, sdl_m;
@property (nonatomic)
struct {
    struct rt_msghdr m_rtm;
    char m_space[512];
} m_rtmsg;
@property (nonatomic) int flags, expire_time, doing_proxy, proxy_only;

@end

@implementation IJTArptable

- (id)init {
    self = [super init];
    if(self) {
        self.sockfd = -1;
        [self open];
    }
    return self;
}

- (void)open {
    if (self.sockfd < 0) {
        self.sockfd = socket(PF_ROUTE, SOCK_RAW, 0);
        if (self.sockfd < 0)
            goto BAD;
    }
    
    self.pid = getpid();
    [self clearAll];
    
    
    self.errorHappened = NO;
    return;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    [self close];
    return;
}

- (void)clearAll {
    bzero(&_so_mask, sizeof(_so_mask));
    _so_mask.sin_len = 8;
    _so_mask.sin_addr.s_addr = 0xffffffff;
    bzero(&_blank_sin, sizeof(_blank_sin));
    _blank_sin.sin_len = sizeof(_blank_sin);
    _blank_sin.sin_family = AF_INET;
    bzero(&_blank_sdl, sizeof(_blank_sdl));
    _blank_sdl.sdl_len = sizeof(_blank_sdl);
    _blank_sdl.sdl_family = AF_LINK;
    
    bzero(&_sin_m, sizeof(_sin_m));
    bzero(&_sdl_m, sizeof(_sdl_m));
    bzero(&_m_rtmsg, sizeof(_m_rtmsg));
    self.flags = self.expire_time = self.proxy_only = self.doing_proxy = 0;
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

- (int)getAllEntriesSkipHostname: (BOOL)skipHostname
                          target: (id)target
                        selector: (SEL)selector
                          object: (id)object {
    return [self search:0 action:GETALL skipHostname:skipHostname target:target selector:selector object:object];
}

- (NSString *)getMacAddressByIpAddress: (NSString *)ipAddress {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    struct in_addr addr;
    inet_pton(AF_INET, [ipAddress UTF8String], &addr);
    
    int ret = [self search:addr.s_addr
                    action:GETALL
              skipHostname:YES
                    target:self
                  selector:ARPTABLE_SHOW_CALLBACK_SEL
                    object:array];
    if(ret == -1 || [array count] != 1) {
        self.errorHappened = YES;
        return nil;
    }
    else {
        NSMutableArray *temp = [array objectAtIndex:0];
        return (NSString *)[temp objectAtIndex:1];
    }
}

- (NSString *)getIpAddressByMacAddress: (NSString *)macAddress {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    int ret = [self search:0
                    action:GETALL
              skipHostname:YES
                    target:self
                  selector:ARPTABLE_SHOW_CALLBACK_SEL
                    object:array];
    if(ret == -1) {
        self.errorHappened = YES;
        return nil;
    }
    else {
        for(NSArray *arr in array) {
            if([[arr objectAtIndex:1] isEqualToString:macAddress]) {
                self.errorHappened = NO;
                return [arr objectAtIndex:0];
            }
        }
    }
    self.errorCode = ENOENT;
    self.errorHappened = YES;
    return nil;
}

ARPTABLE_SHOW_CALLBACK_METHOD {
    NSMutableArray *array = (NSMutableArray *)object;
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    [temp addObject:ipAddress];
    [temp addObject:macAddress];
    [array addObject:temp];
}


- (int)deleteAllEntriesRegisterTarget: (id)target
                             selector: (SEL)selector
                               object: (id)object {
    return [self search:0 action:DELETEALL skipHostname:YES target:target selector:selector object:object];
}

- (int)search: (u_long)addr
       action: (Action)action
 skipHostname: (BOOL)skipHostname
       target: (id)target
     selector: (SEL)selector
       object: (id)object {
    int ret = -1;
    int mib[6];
    size_t needed;
    char *lim, *buf, *next;
    struct rt_msghdr *rtm;
    struct sockaddr_inarp *sin2;
    struct sockaddr_dl *sdl;
    
    [self clearAll];
    buf = NULL;
    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_INET;
    mib[4] = NET_RT_FLAGS;
    mib[5] = RTF_LLINFO;
    if (sysctl(mib, 6, NULL, &needed, NULL, 0) < 0)
        goto BAD;
    if ((buf = malloc(needed)) == NULL)
        goto BAD;
    if (sysctl(mib, 6, buf, &needed, NULL, 0) < 0)
        goto BAD;
    lim = buf + needed;
    for (next = buf; next < lim; next += rtm->rtm_msglen) {
        rtm = (struct rt_msghdr *)next;
        sin2 = (struct sockaddr_inarp *)(rtm + 1);
        sdl = (struct sockaddr_dl*)((char*)sin2 + ROUNDUP(sin2->sin_len));
        if (addr) {
            if (addr != sin2->sin_addr.s_addr)
                continue;
        }
        switch (action) {
            case GETALL:
                ret = [self listentry:sdl
                                 addr:sin2
                                  rtm:rtm
                         skipHostname:skipHostname
                               target:target
                             selector:selector
                               object:object];
                break;
                
            case DELETEALL:
                ret = [self deleteentry:sin2->sin_addr
                                 target:target
                               selector:selector
                                 object:object];
                break;
                
            default:
                printf("Error action\n");
                break;
        }
    }
    if(ret != 0)
        goto BAD;
    
    free(buf);
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    if(buf)
        free(buf);
    return -1;
}

- (int)listentry: (struct sockaddr_dl *)sdl
            addr: (struct sockaddr_inarp *)addr
             rtm: (struct rt_msghdr *)rtm
    skipHostname: (BOOL)skipHostname
          target: (id)target
        selector: (SEL)selector
          object: (id)object {
    ArptableShowCallback arptableshowcallback = NULL;
    struct hostent *hp = NULL;
    NSString *hostname = nil;
    NSString *ipAddress = nil;
    NSString *macAddress = nil;
    NSString *interface = nil;
    char ifname[IF_NAMESIZE];
    int32_t *expire;
    BOOL isproxy;
    BOOL isifscope;
    NSString *netmask = @"";
    IJTArptableSockType sdl_type;
    
    if(target && selector) {
        arptableshowcallback = (ArptableShowCallback)[target methodForSelector:selector];
    }
    
    if(sdl->sdl_alen)
        macAddress = [NSString stringWithUTF8String:[IJTArptable sdl2string:sdl]];
    else {
        //macAddress = @"incomplete";
        return 0;
    }
    
    ipAddress = [NSString stringWithUTF8String:inet_ntoa(addr->sin_addr)];
    
    if(skipHostname) {
        hostname = @"";
    }
    else {
        hp = gethostbyaddr((caddr_t)&(addr->sin_addr),
                           sizeof addr->sin_addr, AF_INET);
        if(hp)
            hostname = [NSString stringWithUTF8String:hp->h_name];
        else
            hostname = @"?";
    }
    
    if (if_indextoname(sdl->sdl_index, ifname) != NULL)
        interface = [NSString stringWithUTF8String:ifname];
    else
        interface = @"";
    expire = &rtm->rtm_rmx.rmx_expire;
    isproxy = addr->sin_other & SIN_PROXY ? YES : NO;
    isifscope = rtm->rtm_flags & RTF_IFSCOPE ? YES : NO;
    if (rtm->rtm_addrs & RTA_NETMASK) {
        addr = (struct sockaddr_inarp *)
        (ROUNDUP(sdl->sdl_len) + (char *)sdl);
        if (addr->sin_addr.s_addr == 0xffffffff)
            netmask = @"published";
        else if (addr->sin_len != 8)
            netmask = @"weird";
    }
    sdl_type = sdl->sdl_type;
    
    if(arptableshowcallback) {
        arptableshowcallback(target, selector, hostname, ipAddress, macAddress, interface, *expire, *expire == 0 ? NO : YES, isproxy, isifscope, netmask, sdl_type, object);
    }
    else {
        char timestr[16] = {};
        strftime( timestr, sizeof(timestr), "%p %H:%M:%S", localtime((time_t *)expire));
        
        printf("%s (%s) at %s on %s, "
               "proxy: %s, ifscope: %s, "
               "expire: %s, dynamic: %s, "
               "netmask: %s, sdl type: %d, sdl: %s\n",
               [hostname UTF8String],
               [ipAddress UTF8String],
               [macAddress UTF8String],
               [interface UTF8String],
               isproxy ? "YES": "NO",
               isifscope ? "YES" : "NO",
               timestr,
               *expire == 0 ? "NO" : "YES",
               [netmask UTF8String],
               (int)sdl_type,
               [[IJTArptable sdltype2string:sdl_type] UTF8String]);
    }
    return 0;
}

- (int)deleteentry: (struct in_addr)ip
            target: (id)target
          selector: (SEL)selector
            object: (id)object {
    ArptableDeleteCallback arptabledeletecallback = NULL;
    register struct sockaddr_inarp *addr = &_sin_m;
    register struct rt_msghdr *rtm = &_m_rtmsg.m_rtm;
    struct sockaddr_dl *sdl;
    
    if(target && selector) {
        arptabledeletecallback = (ArptableDeleteCallback)[target methodForSelector:selector];
    }
    
    _sin_m = _blank_sin;
    
    addr->sin_addr.s_addr = ip.s_addr;
    
tryagain:
    if ([self rtmsg:RTM_GET] < 0) {
        goto BAD;
    }
    addr = (struct sockaddr_inarp *)(rtm + 1);
    sdl = (struct sockaddr_dl *)(ROUNDUP(addr->sin_len) + (char *)addr);
    if (addr->sin_addr.s_addr == _sin_m.sin_addr.s_addr) {
        if (sdl->sdl_family == AF_LINK &&
            (rtm->rtm_flags & RTF_LLINFO) &&
            !(rtm->rtm_flags & RTF_GATEWAY)) switch (sdl->sdl_type) {
            case IFT_ETHER: case IFT_FDDI: case IFT_ISO88023:
            case IFT_ISO88024: case IFT_ISO88025: case IFT_L2VLAN:
                goto delete;
        }
    }
    if (_sin_m.sin_other & SIN_PROXY) {
        self.errorMessage = [NSString stringWithFormat:@"delete: can't locate %s", inet_ntoa(addr->sin_addr)];
        errno = 0;
        goto BAD;
    } else {
        _sin_m.sin_other = SIN_PROXY;
        goto tryagain;
    }
delete:
    if (sdl->sdl_family != AF_LINK) {
        self.errorMessage = [NSString stringWithFormat:@"cannot locate %s", inet_ntoa(addr->sin_addr)];
        errno = 0;
        goto BAD;
    }
    if ([self rtmsg:RTM_DELETE] == 0) {
        if(arptabledeletecallback) {
            arptabledeletecallback(target, selector, [NSString stringWithUTF8String:inet_ntoa(addr->sin_addr)], NO, 0, @"", object);
        }
        else
            printf("%s deleted\n", inet_ntoa(addr->sin_addr));
        
        self.errorHappened = NO;
        return 0;
    }
    
BAD:
    if(arptabledeletecallback) {
        arptabledeletecallback(target, selector, [NSString stringWithUTF8String:inet_ntoa(addr->sin_addr)], YES, errno, self.errorMessage, object);
    }
    else
        printf("%s delete fail: %s\n", inet_ntoa(addr->sin_addr), strerror(errno));
    
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (int)deleteIpAddress: (NSString *)ipAddress {
    struct in_addr addr;
    inet_pton(AF_INET, [ipAddress UTF8String], &addr);
    
    return [self search:addr.s_addr action:DELETEALL skipHostname:YES target:nil selector:nil object:nil];
}

- (int)rtmsg: (int) cmd {
    static int seq;
    int rlen;
    register struct rt_msghdr *rtm = &_m_rtmsg.m_rtm;
    register char *cp = _m_rtmsg.m_space;
    register int l;
    
    errno = 0;
    if (cmd == RTM_DELETE)
        goto doit;
    bzero((char *)&_m_rtmsg, sizeof(_m_rtmsg));
    rtm->rtm_flags = _flags;
    rtm->rtm_version = RTM_VERSION;
    
    switch (cmd) {
        default:
            self.errorMessage = @"internal wrong cmd";
            errno = 0;
            goto BAD;
        case RTM_ADD:
            rtm->rtm_addrs |= RTA_GATEWAY;
            rtm->rtm_rmx.rmx_expire = _expire_time;
            rtm->rtm_inits = RTV_EXPIRE;
            rtm->rtm_flags |= (RTF_HOST | RTF_STATIC);
            _sin_m.sin_other = 0;
            if (_doing_proxy) {
                if (_proxy_only)
                    _sin_m.sin_other = SIN_PROXY;
                else {
                    rtm->rtm_addrs |= RTA_NETMASK;
                    rtm->rtm_flags &= ~RTF_HOST;
                }
            }
            /* FALLTHROUGH */
        case RTM_GET:
            rtm->rtm_addrs |= RTA_DST;
    }
#define NEXTADDR(w, s) \
if (rtm->rtm_addrs & (w)) { \
bcopy((char *)&s, cp, sizeof(s)); cp += ROUNDUP(sizeof(s));}
    
    NEXTADDR(RTA_DST, _sin_m);
    NEXTADDR(RTA_GATEWAY, _sdl_m);
    NEXTADDR(RTA_NETMASK, _so_mask);
    
    rtm->rtm_msglen = cp - (char *)&_m_rtmsg;
doit:
    l = rtm->rtm_msglen;
    rtm->rtm_seq = ++seq;
    rtm->rtm_type = cmd;
    if ((rlen = (int)write(self.sockfd, (char *)&_m_rtmsg, l)) < 0) {
        if (errno == ESRCH || cmd != RTM_DELETE) {
            goto BAD;
        }
    }
    do {
        l = (int)read(self.sockfd, (char *)&_m_rtmsg, sizeof(_m_rtmsg));
    } while (l > 0 && (rtm->rtm_seq != seq || rtm->rtm_pid != _pid));
    
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

/*
 * get_ether_addr - get the hardware address of an interface on the
 * the same subnet as ipaddr.
 */
#define MAX_IFS		32

static int get_ether_addr(u_int32_t ipaddr, struct ether_addr *hwaddr) {
    struct ifreq *ifr, *ifend, *ifp;
    u_int32_t ina, mask;
    struct sockaddr_dl *dla;
    struct ifreq ifreq;
    struct ifconf ifc;
    struct ifreq ifs[MAX_IFS];
    int sock;
    
    sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0)
        return -1;
    
    ifc.ifc_len = sizeof(ifs);
    ifc.ifc_req = ifs;
    if (ioctl(sock, SIOCGIFCONF, &ifc) < 0) {
        close(sock);
        return 0;
    }
    
    /*
     * Scan through looking for an interface with an Internet
     * address on the same subnet as `ipaddr'.
     */
    ifend = (struct ifreq *) (ifc.ifc_buf + ifc.ifc_len);
    for (ifr = ifc.ifc_req; ifr < ifend; ) {
        if (ifr->ifr_addr.sa_family == AF_INET) {
            ina = ((struct sockaddr_in *)
                   &ifr->ifr_addr)->sin_addr.s_addr;
            strncpy(ifreq.ifr_name, ifr->ifr_name,
                    sizeof(ifreq.ifr_name));
            /*
             * Check that the interface is up,
             * and not point-to-point or loopback.
             */
            if (ioctl(sock, SIOCGIFFLAGS, &ifreq) < 0)
                continue;
            if ((ifreq.ifr_flags &
                 (IFF_UP|IFF_BROADCAST|IFF_POINTOPOINT|
                  IFF_LOOPBACK|IFF_NOARP))
                != (IFF_UP|IFF_BROADCAST))
                goto nextif;
            /*
             * Get its netmask and check that it's on
             * the right subnet.
             */
            if (ioctl(sock, SIOCGIFNETMASK, &ifreq) < 0)
                continue;
            mask = ((struct sockaddr_in *)
                    &ifreq.ifr_addr)->sin_addr.s_addr;
            if ((ipaddr & mask) != (ina & mask))
                goto nextif;
            break;
        }
    nextif:
        ifr = (struct ifreq *) ((char *)&ifr->ifr_addr
                                + MAX(ifr->ifr_addr.sa_len, sizeof(ifr->ifr_addr)));
    }
    
    if (ifr >= ifend) {
        close(sock);
        return 0;
    }
    
    /*
     * Now scan through again looking for a link-level address
     * for this interface.
     */
    ifp = ifr;
    for (ifr = ifc.ifc_req; ifr < ifend; ) {
        if (strcmp(ifp->ifr_name, ifr->ifr_name) == 0
            && ifr->ifr_addr.sa_family == AF_LINK) {
            /*
             * Found the link-level address - copy it out
             */
            dla = (struct sockaddr_dl *) &ifr->ifr_addr;
            close (sock);
            return dla->sdl_alen;
        }
        ifr = (struct ifreq *) ((char *)&ifr->ifr_addr
                                + MAX(ifr->ifr_addr.sa_len, sizeof(ifr->ifr_addr)));
    }
    return 0;
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

static int my_ether_aton(char *a, struct ether_addr *n) {
    struct ether_addr *ea;
    
    if ((ea = ether_aton(a)) == NULL) {
        return (1);
    }
    *n = *ea;
    return (0);
}

+ (NSString *)sdltype2string: (IJTArptableSockType)type {
    switch (type) {
        case IJTArptableSockTypeEther: return @"Ethernet";
        case IJTArptableSockTypeTokenRing: return @"Token Ring";
        case IJTArptableSockTypeVLAN: return @"VLAN";
        case IJTArptableSockTypeFirewall: return @"Firewire";
        case IJTArptableSockTypeFddi: return @"Fddi";
        case IJTArptableSockTypeATM: return @"ATM";
        case IJTArptableSockTypeBridge: return @"Bridge";
        default: return @"Unknown Type";
    }
}

- (int)addIpAddress: (NSString *)ipAddress
         macAddress: (NSString *)macAddress
           isstatic: (BOOL)isstatic
        ispublished: (BOOL)ispublished
             isonly: (BOOL)isonly {
    register struct sockaddr_inarp *addr = &_sin_m;
    register struct sockaddr_dl *sdl;
    register struct rt_msghdr *rtm = &(_m_rtmsg.m_rtm);
    struct ether_addr *ea;
    char *host = (char *)[ipAddress UTF8String], *eaddr = (char *)[macAddress UTF8String];
    
    [self clearAll];
    _sdl_m = _blank_sdl;
    _sin_m = _blank_sin;
    addr->sin_addr.s_addr = inet_addr(host);
    
    _doing_proxy = _flags = _proxy_only = _expire_time = 0;
    if(!isstatic) {
        struct timeval tv;
        gettimeofday(&tv, 0);
        _expire_time = (int)tv.tv_sec + 20 * 60; //20min
    }
    if(ispublished) {
        _flags |= RTF_ANNOUNCE;
        _doing_proxy = 1;
    }
    if(isonly) {
        _proxy_only = 1;
        _sin_m.sin_other = SIN_PROXY;
    }
    ea = (struct ether_addr *)LLADDR(&_sdl_m);
    if (_doing_proxy && !strcmp(eaddr, "auto")) {
        if (!get_ether_addr(addr->sin_addr.s_addr, ea)) {
            self.errorMessage = [NSString stringWithFormat:@"no interface found for %s", inet_ntoa(addr->sin_addr)];
            errno = 0;
            goto BAD;
        }
        _sdl_m.sdl_alen = ETHER_ADDR_LEN;
    } else {
        if (my_ether_aton(eaddr, ea) == 0)
            _sdl_m.sdl_alen = ETHER_ADDR_LEN;
    }
tryagain:
    if ([self rtmsg:RTM_GET] < 0) {
        goto BAD;
    }
    addr = (struct sockaddr_inarp *)(rtm + 1);
    sdl = (struct sockaddr_dl *)(ROUNDUP(addr->sin_len) + (char *)addr);
    if (addr->sin_addr.s_addr == _sin_m.sin_addr.s_addr) {
        if (sdl->sdl_family == AF_LINK &&
            (rtm->rtm_flags & RTF_LLINFO) &&
            !(rtm->rtm_flags & RTF_GATEWAY)) switch (sdl->sdl_type) {
            case IFT_ETHER: case IFT_FDDI: case IFT_ISO88023:
            case IFT_ISO88024: case IFT_ISO88025: case IFT_L2VLAN:
                goto overwrite;
        }
        if (_doing_proxy == 0) {
            self.errorMessage = [NSString stringWithFormat:@"set: can only proxy for %s", host];
            errno = 0;
            goto BAD;
        }
        if (_sin_m.sin_other & SIN_PROXY) {
            self.errorMessage = [NSString stringWithFormat:@"set: proxy entry exists for non 802 device"];
            errno = 0;
            goto BAD;
        }
        _sin_m.sin_other = SIN_PROXY;
        _proxy_only = 1;
        goto tryagain;
    }
overwrite:
    if (sdl->sdl_family != AF_LINK) {
        self.errorMessage = [NSString stringWithFormat:@"cannot intuit interface index and type for %s", host];
        errno = 0;
        goto BAD;
    }
    _sdl_m.sdl_type = sdl->sdl_type;
    _sdl_m.sdl_index = sdl->sdl_index;
    
    if([self rtmsg:RTM_ADD] < 0)
        goto BAD;
    
    self.errorHappened = NO;
    return 0;
    
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

@end
