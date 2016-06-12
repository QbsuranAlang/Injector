//
//  IJTRoutetable.m
//  IJTRoutetable
//
//  Created by 聲華 陳 on 2015/6/6.
//
//

#import "IJTRoutetable.h"
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <net/if_types.h>
#import <net/route.h>
#import <netinet/in.h>
#import <netdb.h>
#import <arpa/inet.h>
#import <ifaddrs.h>

typedef union {
    uint32_t dummy;		/* Helps align structure. */
    struct	sockaddr u_sa;
    u_short	u_data[128];
} sa_u;

union	sockunion {
    struct	sockaddr sa;
    struct	sockaddr_in sin;
    struct	sockaddr_in6 sin6;
    struct	sockaddr_dl sdl;
    struct	sockaddr_storage ss; /* added to avoid memory overrun */
};
typedef union sockunion *sup;

#define ROUNDUP(a) \
((a) > 0 ? (1 + (((a) - 1) | (sizeof(uint32_t) - 1))) : sizeof(uint32_t))
#define ADVANCE(x, n) (x += ROUNDUP((n)->sa_len))

@interface IJTRoutetable ()

@property (nonatomic) int sockfd;
@property (nonatomic)
struct {
    struct	rt_msghdr m_rtm;
    char	m_space[512];
} m_rtmsg;
@property (nonatomic) union sockunion so_dst, so_gate, so_mask, so_genmask, so_ifa, so_ifp;
@property (nonatomic) int rtm_addrs;
@property (nonatomic) struct rt_metrics rt_metrics;
@property (nonatomic) int rtm_inits;
@property (nonatomic) pid_t pid;
@property (nonatomic) int iflag;
@property (nonatomic) int forcenet;
@property (nonatomic) int forcehost;

@end

@implementation IJTRoutetable

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
        self.pid = getpid();
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

static void
domask(char *dst, uint32_t addr, uint32_t mask)
{
    int b, i;
    
    if (!mask || (forgemask(addr) == mask)) {
        *dst = '\0';
        return;
    }
    i = 0;
    for (b = 0; b < 32; b++)
        if (mask & (1 << b)) {
            int bb;
            
            i = b;
            for (bb = b+1; bb < 32; bb++)
                if (!(mask & (1 << bb))) {
                    i = -1;	/* noncontig */
                    break;
                }
            break;
        }
    if (i == -1)
        snprintf(dst, sizeof(dst), "&0x%x", mask);
    else
        snprintf(dst, sizeof(dst), "/%d", 32-i);
}

static void
get_rtaddrs(int addrs, struct sockaddr *sa, struct sockaddr **rti_info)
{
    int i;
    
    for (i = 0; i < RTAX_MAX; i++) {
        if (addrs & (1 << i)) {
            rti_info[i] = sa;
            sa = (struct sockaddr *)(ROUNDUP(sa->sa_len) + (char *)sa);
        } else {
            rti_info[i] = NULL;
        }
    }
}

static uint32_t
forgemask(uint32_t a)
{
    uint32_t m;
    
    if (IN_CLASSA(a))
        m = IN_CLASSA_NET;
    else if (IN_CLASSB(a))
        m = IN_CLASSB_NET;
    else
        m = IN_CLASSC_NET;
    return (m);
}

static char *
routename(uint32_t inaddr, int nflag)
{
    char *cp;
    static char line[MAXHOSTNAMELEN];
    struct hostent *hp;
    
    cp = 0;
    if (!nflag) {
        hp = gethostbyaddr((char *)&inaddr, sizeof (struct in_addr),
                           AF_INET);
        if (hp) {
            cp = hp->h_name;
            //### trimdomain(cp, strlen(cp));
        }
    }
    if (cp) {
        strncpy(line, cp, sizeof(line) - 1);
        line[sizeof(line) - 1] = '\0';
    } else {
#define C(x)	((x) & 0xff)
        inaddr = ntohl(inaddr);
        snprintf(line, sizeof(line), "%u.%u.%u.%u",
                 C(inaddr >> 24), C(inaddr >> 16), C(inaddr >> 8), C(inaddr));
    }
    return (line);
}

/*
 * Return the name of the network whose address is given.
 * The address is assumed to be that of a net or subnet, not a host.
 */
static char *
netname(uint32_t inaddr, uint32_t mask, int nflag)
{
    char *cp = 0;
    static char line[MAXHOSTNAMELEN];
    struct netent *np = 0;
    uint32_t net, omask, dmask;
    uint32_t i;
    
    i = ntohl(inaddr);
    dmask = forgemask(i);
    omask = mask;
    if (!nflag && i) {
        net = i & dmask;
        if (!(np = getnetbyaddr(i, AF_INET)) && net != i)
            np = getnetbyaddr(net, AF_INET);
        if (np) {
            cp = np->n_name;
            //### trimdomain(cp, strlen(cp));
        }
    }
    if (cp)
        strncpy(line, cp, sizeof(line) - 1);
    else {
        switch (dmask) {
            case IN_CLASSA_NET:
                if ((i & IN_CLASSA_HOST) == 0) {
                    snprintf(line, sizeof(line), "%u", C(i >> 24));
                    break;
                }
                /* FALLTHROUGH */
            case IN_CLASSB_NET:
                if ((i & IN_CLASSB_HOST) == 0) {
                    snprintf(line, sizeof(line), "%u.%u",
                             C(i >> 24), C(i >> 16));
                    break;
                }
                /* FALLTHROUGH */
            case IN_CLASSC_NET:
                if ((i & IN_CLASSC_HOST) == 0) {
                    snprintf(line, sizeof(line), "%u.%u.%u",
                             C(i >> 24), C(i >> 16), C(i >> 8));
                    break;
                }
                /* FALLTHROUGH */
            default:
                snprintf(line, sizeof(line), "%u.%u.%u.%u",
                         C(i >> 24), C(i >> 16), C(i >> 8), C(i));
                break;
        }
    }
    domask(line+strlen(line), i, omask);
    return (line);
}

static char *
netname6(struct sockaddr_in6 *sa6, struct sockaddr *sam, int nflag)
{
    static char line[MAXHOSTNAMELEN];
    u_char *lim;
    int masklen, illegal = 0, flag = NI_WITHSCOPEID;
    struct in6_addr *mask = sam ? &((struct sockaddr_in6 *)sam)->sin6_addr : 0;
    
    if (sam && sam->sa_len == 0) {
        masklen = 0;
    } else if (mask) {
        u_char *p = (u_char *)mask;
        for (masklen = 0, lim = p + 16; p < lim; p++) {
            switch (*p) {
                case 0xff:
                    masklen += 8;
                    break;
                case 0xfe:
                    masklen += 7;
                    break;
                case 0xfc:
                    masklen += 6;
                    break;
                case 0xf8:
                    masklen += 5;
                    break;
                case 0xf0:
                    masklen += 4;
                    break;
                case 0xe0:
                    masklen += 3;
                    break;
                case 0xc0:
                    masklen += 2;
                    break;
                case 0x80:
                    masklen += 1;
                    break;
                case 0x00:
                    break;
                default:
                    illegal ++;
                    break;
            }
        }
        if (illegal)
            fprintf(stderr, "illegal prefixlen\n");
    } else {
        masklen = 128;
    }
    if (masklen == 0 && IN6_IS_ADDR_UNSPECIFIED(&sa6->sin6_addr))
        return("default");
    
    if (nflag)
        flag |= NI_NUMERICHOST;
    getnameinfo((struct sockaddr *)sa6, sa6->sin6_len, line, sizeof(line),
                NULL, 0, flag);
    
    if (nflag)
        snprintf(&line[strlen(line)], sizeof(line) - strlen(line), "/%d", masklen);
    
    return line;
}

static char *
routename6(struct sockaddr_in6 *sa6, int nflag)
{
    static char line[MAXHOSTNAMELEN];
    int flag = NI_WITHSCOPEID;
    /* use local variable for safety */
    struct sockaddr_in6 sa6_local = {sizeof(sa6_local), AF_INET6, };
    
    sa6_local.sin6_addr = sa6->sin6_addr;
    sa6_local.sin6_scope_id = sa6->sin6_scope_id;
    
    if (nflag)
        flag |= NI_NUMERICHOST;
    
    getnameinfo((struct sockaddr *)&sa6_local, sa6_local.sin6_len,
                line, sizeof(line), NULL, 0, flag);
    
    return line;
}

static char *
p_sockaddr(struct sockaddr *sa, struct sockaddr *mask, int flags, int nflag)
{
    static char workbuf[128], *cplim;
    static char *cp = workbuf;
    
    switch(sa->sa_family) {
        case AF_INET: {
            struct sockaddr_in *sin = (struct sockaddr_in *)sa;
            
            if ((sin->sin_addr.s_addr == INADDR_ANY) &&
                mask &&
                (ntohl(((struct sockaddr_in *)mask)->sin_addr.s_addr) == 0L || mask->sa_len == 0)) {
                if(nflag)
                    cp = "0.0.0.0";
                else
                    cp = "default";
            }
            else if (flags & RTF_HOST)
                cp = routename(sin->sin_addr.s_addr, nflag);
            else if (mask)
                cp = netname(sin->sin_addr.s_addr,
                             ntohl(((struct sockaddr_in *)mask)->
                                   sin_addr.s_addr), nflag);
            else
                cp = netname(sin->sin_addr.s_addr, 0L, nflag);
            break;
        }
            
        case AF_INET6: {
            struct sockaddr_in6 *sa6 = (struct sockaddr_in6 *)sa;
            struct in6_addr *in6 = &sa6->sin6_addr;
            
            /*
             * XXX: This is a special workaround for KAME kernels.
             * sin6_scope_id field of SA should be set in the future.
             */
            if (IN6_IS_ADDR_LINKLOCAL(in6) ||
                IN6_IS_ADDR_MC_NODELOCAL(in6) ||
                IN6_IS_ADDR_MC_LINKLOCAL(in6)) {
                /* XXX: override is ok? */
                sa6->sin6_scope_id = (u_int32_t)ntohs(*(u_short *)&in6->s6_addr[2]);
                *(u_short *)&in6->s6_addr[2] = 0;
            }
            
            if (flags & RTF_HOST)
                cp = routename6(sa6, nflag);
            else if (mask)
                cp = netname6(sa6, mask, nflag);
            else
                cp = netname6(sa6, NULL, nflag);
            break;
        }
            
        case AF_LINK: {
            struct sockaddr_dl *sdl = (struct sockaddr_dl *)sa;
            
            if (sdl->sdl_nlen == 0 && sdl->sdl_alen == 0 &&
                sdl->sdl_slen == 0) {
                (void) snprintf(workbuf, sizeof(workbuf), "link#%d", sdl->sdl_index);
            } else {
                switch (sdl->sdl_type) {
                        
                    case IFT_ETHER: {
                        int i;
                        u_char *lla = (u_char *)sdl->sdl_data +
                        sdl->sdl_nlen;
                        
                        cplim = "";
                        for (i = 0; i < sdl->sdl_alen; i++, lla++) {
                            cp += snprintf(cp, sizeof(workbuf) - (cp - workbuf), "%s%x", cplim, *lla);
                            cplim = ":";
                        }
                        cp = workbuf;
                        break;
                    }
                        
                    default:
                        cp = link_ntoa(sdl);
                        break;
                }
            }
            break;
        }
            
        default: {
            u_char *s = (u_char *)sa->sa_data, *slim;
            
            slim =  sa->sa_len + (u_char *) sa;
            cplim = cp + sizeof(workbuf) - 6;
            cp += snprintf(cp, sizeof(workbuf) - (cp - workbuf), "(%d)", sa->sa_family);
            while (s < slim && cp < cplim) {
                cp += snprintf(cp, sizeof(workbuf) - (cp - workbuf), " %02x", *s++);
                if (s < slim)
                    cp += snprintf(cp, sizeof(workbuf) - (cp - workbuf), "%02x", *s++);
            }
            cp = workbuf;
        }
    }
    return cp;
}

struct bits {
    uint32_t	b_mask;
    char	b_val;
} rt_bits[] = {
    { RTF_UP,	'U' },
    { RTF_GATEWAY,	'G' },
    { RTF_HOST,	'H' },
    { RTF_REJECT,	'R' },
    { RTF_DYNAMIC,	'D' },
    { RTF_MODIFIED,	'M' },
    { RTF_MULTICAST,'m' },
    { RTF_DONE,	'd' }, /* Completed -- for routing messages only */
    { RTF_CLONING,	'C' },
    { RTF_XRESOLVE,	'X' },
    { RTF_LLINFO,	'L' },
    { RTF_STATIC,	'S' },
    { RTF_PROTO1,	'1' },
    { RTF_PROTO2,	'2' },
    { RTF_WASCLONED,'W' },
    { RTF_PRCLONING,'c' },
    { RTF_PROTO3,	'3' },
    { RTF_BLACKHOLE,'B' },
    { RTF_BROADCAST,'b' },
    { RTF_IFSCOPE,	'I' },
    { RTF_IFREF,	'i' },
    { RTF_PROXY,	'Y' },
    { RTF_ROUTER,	'r' },
    { 0 }
};

static char *
p_flags(int f)
{
    static char name[33], *flags;
    struct bits *p = rt_bits;
    
    for (flags = name; p->b_mask; p++)
        if (p->b_mask & f)
            *flags++ = p->b_val;
    *flags = '\0';
    return name;
}

- (int)getGatewayByDestinationIpAddress: (NSString *)destination
                                 target: (id)target
                               selector: (SEL)selector
                                 object: (id)object {
    return [self getGatewayByDestinationIpAddress:destination skipHostname:YES target:target selector:selector object:object];
}

- (int)getGatewayByDestinationIpAddress: (NSString *)destination
                           skipHostname: (BOOL)skipHostname
                                 target: (id)target
                               selector: (SEL)selector
                                 object: (id)object {
    size_t needed;
    int mib[6];
    char *buf = NULL, *next, *lim;
    struct rt_msghdr2 *rtm;
    RoutetableShowCallback routetableshowcallback = NULL;
    
    if(target && selector) {
        routetableshowcallback = (RoutetableShowCallback)[target methodForSelector:selector];
    }
    
    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;
    mib[3] = 0;
    mib[4] = NET_RT_DUMP2;
    mib[5] = 0;
    
    if (sysctl(mib, 6, NULL, &needed, NULL, 0) < 0) {
        goto BAD;
    }
    
    if ((buf = malloc(needed)) == 0) {
        goto BAD;
    }
    if (sysctl(mib, 6, buf, &needed, NULL, 0) < 0) {
        goto BAD;
    }
    lim  = buf + needed;
    for (next = buf; next < lim; next += rtm->rtm_msglen) {
        rtm = (struct rt_msghdr2 *)next;
        
        struct sockaddr *sa = (struct sockaddr *)(rtm + 1);
        struct sockaddr *rti_info[RTAX_MAX];
        u_short lastindex = 0xffff;
        static char ifname[IFNAMSIZ + 1];
        sa_u addr, mask;
        char *temp = NULL;
        
        NSString *destinationIpAddress = nil;
        NSString *destinationHostname = nil;
        NSString *gateway = nil;
        NSString *flags = nil;
        int32_t refs = 0;
        u_int32_t use = 0;
        u_int32_t mtu = 0;
        NSString *interface = nil;
        time_t expire_time = 0;
        BOOL dynamic = NO;
        sa_family_t af = sa->sa_family;
        unsigned int ifindex = 0;
        
        if ((rtm->rtm_flags & RTF_WASCLONED) &&
            (rtm->rtm_parentflags & RTF_PRCLONING)) {
#pragma mark all route
            continue; //Don't print protocol-cloned
        }
        
        get_rtaddrs(rtm->rtm_addrs, sa, rti_info);
        bzero(&addr, sizeof(addr));
        if ((rtm->rtm_addrs & RTA_DST))
            bcopy(rti_info[RTAX_DST], &addr, rti_info[RTAX_DST]->sa_len);
        bzero(&mask, sizeof(mask));
        if ((rtm->rtm_addrs & RTA_NETMASK))
            bcopy(rti_info[RTAX_NETMASK], &mask, rti_info[RTAX_NETMASK]->sa_len);
        
        //destination with ip address
        temp = p_sockaddr(&addr.u_sa, &mask.u_sa, rtm->rtm_flags, 1);
        destinationIpAddress = [NSString stringWithUTF8String:temp];
        
        if(destination && ![destination isEqualToString:destinationIpAddress]) {
            continue;
        }
        
        //destination with hostname
        if(skipHostname) {
            destinationHostname = @"";
        }
        else {
            temp = p_sockaddr(&addr.u_sa, &mask.u_sa, rtm->rtm_flags, 0);
            destinationHostname = [NSString stringWithUTF8String:temp];
        }
        
        //getway
        temp = p_sockaddr(rti_info[RTAX_GATEWAY], NULL, RTF_HOST, 1);
        gateway = [NSString stringWithUTF8String:temp];
        
        //flag
        temp = p_flags(rtm->rtm_flags);
        flags = [NSString stringWithUTF8String:temp];
        
        if(addr.u_sa.sa_family == AF_INET) {
            refs = rtm->rtm_refcnt;
            use = (u_int32_t)rtm->rtm_use;
            mtu = rtm->rtm_rmx.rmx_mtu;
        }
        if (rtm->rtm_index != lastindex) {
            if_indextoname(rtm->rtm_index, ifname);
            //lastindex = rtm->rtm_index;
            interface = [NSString stringWithUTF8String:ifname];
            ifindex = rtm->rtm_index;
        }
        
        if (rtm->rtm_rmx.rmx_expire) {
            expire_time = rtm->rtm_rmx.rmx_expire - time((time_t *)0);
            dynamic = YES;
        }
        else
            dynamic = NO;
        
        if(routetableshowcallback) {
            routetableshowcallback(target, selector, af, destinationHostname, destinationIpAddress, gateway, interface, ifindex, flags, refs, use, mtu, expire_time, dynamic, object);
        }
        else {
            char timestr[16] = {};
            strftime(timestr, sizeof(timestr), "%p %H:%M:%S", localtime((time_t *)&expire_time));
            
            printf("Type: %s, ", af == IJTRoutetableTypeInet4 ? "Internet4" :
                   af == IJTRoutetableTypeInet6 ? "Internet6" : "Unknown");
            printf("Destination: %s(%s), ", [destinationHostname UTF8String], [destinationIpAddress UTF8String]);
            printf("Gateway: %s, ", [gateway UTF8String]);
            printf("Flags: %s, ", [flags UTF8String]);
            printf("Refs: %d, Use: %u, MTU: %d, ", refs, use, mtu);
            printf("Interface: %s, ", [interface UTF8String]);
            printf("Expire Time: %s, Dynamic: %s", timestr, dynamic ? "YES" : "NO");
            
            printf("\n");
        }
    }
    
    if(buf)
        free(buf);
    self.errorHappened = NO;
    return 0;
BAD:
    if(buf)
        free(buf);
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (int)getAllEntriesSkipHostname: (BOOL)skipHostname
                          target: (id)target
                        selector: (SEL)selector
                          object: (id)object {
    return [self getGatewayByDestinationIpAddress:nil
                                     skipHostname:skipHostname
                                           target:target
                                         selector:selector
                                           object:object];
}

- (int)deleteAllEntriesRegisterTarget: (id)target
                             selector: (SEL)selector
                               object: (id)object {
    return [self deleteDestination:nil gateway:nil target:target selector:selector object:object];
}

- (int)deleteDestination: (NSString *)destination
                 gateway: (NSString *)gateway
                  target: (id)target
                selector: (SEL)selector
                  object: (id)object {
    size_t needed;
    int mib[6];
    char *buf = NULL, *next, *lim;
    register struct rt_msghdr *rtm;
    int seq = 0;
    int found = 0;
    RoutetableDeleteCallback routetabledeletecallback = NULL;
    if(target && selector) {
        routetabledeletecallback = (RoutetableDeleteCallback)[target methodForSelector:selector];
    }
    
    mib[0] = CTL_NET;
    mib[1] = PF_ROUTE;
    mib[2] = 0;		/* protocol */
    mib[3] = 0;		/* wildcard address family */
    mib[4] = NET_RT_DUMP;
    mib[5] = 0;		/* no flags */
    if (sysctl(mib, 6, NULL, &needed, NULL, 0) < 0)
        goto BAD;
    if ((buf = malloc(needed)) == NULL)
        goto BAD;
    if (sysctl(mib, 6, buf, &needed, NULL, 0) < 0)
        goto BAD;
    lim = buf + needed;
    
    for (next = buf; next < lim; next += rtm->rtm_msglen) {
        rtm = (struct rt_msghdr *)next;
        
        struct sockaddr *rti_info[RTAX_MAX];
        sa_u addr, mask;
        char *temp = NULL;
        struct sockaddr *sa = (struct sockaddr *)(rtm + 1);
        
        get_rtaddrs(rtm->rtm_addrs, sa, rti_info);
        bzero(&addr, sizeof(addr));
        if ((rtm->rtm_addrs & RTA_DST))
            bcopy(rti_info[RTAX_DST], &addr, rti_info[RTAX_DST]->sa_len);
        bzero(&mask, sizeof(mask));
        if ((rtm->rtm_addrs & RTA_NETMASK))
            bcopy(rti_info[RTAX_NETMASK], &mask, rti_info[RTAX_NETMASK]->sa_len);
        
        NSString *destinationIpAddress = nil;
        NSString *destinationHostname = nil;
        NSString *gateway2 = nil;
        
        rtm->rtm_seq = ++seq;
        rtm->rtm_type = RTM_DELETE;
        
        //destination with ip address
        temp = p_sockaddr(&addr.u_sa, &mask.u_sa, rtm->rtm_flags, 1);
        destinationIpAddress = [NSString stringWithUTF8String:temp];
        
        //destination with hostname
        temp = p_sockaddr(&addr.u_sa, &mask.u_sa, rtm->rtm_flags, 0);
        destinationHostname = [NSString stringWithUTF8String:temp];
        
        //getway
        temp = p_sockaddr(rti_info[RTAX_GATEWAY], NULL, RTF_HOST, 1);
        gateway2 = [NSString stringWithUTF8String:temp];
        
        if(destinationIpAddress && gateway &&
           !([destinationIpAddress isEqualToString:destination] && [gateway2 isEqualToString:gateway])) {
            continue;
        }
        else if(destinationIpAddress && gateway && [destinationIpAddress isEqualToString:destination] && [gateway2 isEqualToString:gateway]) {
            found = 1;
        }
        
        int rlen = (int)write(self.sockfd, rtm, rtm->rtm_msglen);
        
        if (rlen < (int)rtm->rtm_msglen) {
            //error
            if(routetabledeletecallback) {
                routetabledeletecallback(target, selector, destinationIpAddress, destinationHostname, gateway, YES, self.errorCode, self.errorMessage, object);
            }
            else {
                printf("Delete fail: %s(%s), gateway: %s\n",
                       [destinationHostname UTF8String], [destinationIpAddress UTF8String], [gateway2 UTF8String]);
                fflush(stdout);
            }
        }
        else {
            if(routetabledeletecallback) {
                routetabledeletecallback(target, selector, destinationIpAddress, destinationHostname, gateway, NO, 0, @"", object);
            }
            else {
                printf("Deleted: %s(%s), gateway: %s\n",
                       [destinationHostname UTF8String], [destinationIpAddress UTF8String],
                       [gateway2 UTF8String]);
                fflush(stdout);
            }
        }
        if(found)
            break;
    }
    
    if(destination && gateway && !found) {
        errno = ENOENT;
        goto BAD;
    }
    
    if(buf)
        free(buf);
    self.errorHappened = NO;
    return 0;
BAD:
    if(buf)
        free(buf);
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

/* States*/
#define VIRGIN	0
#define GOTONE	1
#define GOTTWO	2
/* Inputs */
#define	DIGIT	(4*0)
#define	END	(4*1)
#define DELIM	(4*2)

static void
sockaddr(register char *addr, register struct sockaddr *sa)
{
    register char *cp = (char *)sa;
    int size = sa->sa_len;
    char *cplim = cp + size;
    register int byte = 0, state = VIRGIN, new = 0 /* foil gcc */;
    
    bzero(cp, size);
    cp++;
    do {
        if ((*addr >= '0') && (*addr <= '9')) {
            new = *addr - '0';
        } else if ((*addr >= 'a') && (*addr <= 'f')) {
            new = *addr - 'a' + 10;
        } else if ((*addr >= 'A') && (*addr <= 'F')) {
            new = *addr - 'A' + 10;
        } else if (*addr == 0)
            state |= END;
        else
            state |= DELIM;
        addr++;
        switch (state /* | INPUT */) {
            case GOTTWO | DIGIT:
                *cp++ = byte; /*FALLTHROUGH*/
            case VIRGIN | DIGIT:
                state = GOTONE; byte = new; continue;
            case GOTONE | DIGIT:
                state = GOTTWO; byte = new + (byte << 4); continue;
            default: /* | DELIM */
                state = VIRGIN; *cp++ = byte; byte = 0; continue;
            case GOTONE | END:
            case GOTTWO | END:
                *cp++ = byte; /* FALLTHROUGH */
            case VIRGIN | END:
                break;
        }
        break;
    } while (cp < cplim);
    sa->sa_len = cp - (char *)sa;
}

- (void)inet_makenetandmask: (u_long)net
                        sin: (struct sockaddr_in *)sin
                       bits: (u_long)bits
{
    u_long addr, mask = 0;
    register char *cp;
    
    _rtm_addrs |= RTA_NETMASK;
    if (bits) {
        addr = net;
        mask = 0xffffffff << (32 - bits);
    } else if (net == 0)
        mask = addr = 0;
    else if (net < 128) {
        addr = net << IN_CLASSA_NSHIFT;
        mask = IN_CLASSA_NET;
    } else if (net < 65536) {
        addr = net << IN_CLASSB_NSHIFT;
        mask = IN_CLASSB_NET;
    } else if (net < 16777216L) {
        addr = net << IN_CLASSC_NSHIFT;
        mask = IN_CLASSC_NET;
    } else {
        addr = net;
        if ((addr & IN_CLASSA_HOST) == 0)
            mask =  IN_CLASSA_NET;
        else if ((addr & IN_CLASSB_HOST) == 0)
            mask =  IN_CLASSB_NET;
        else if ((addr & IN_CLASSC_HOST) == 0)
            mask =  IN_CLASSC_NET;
        else
            mask = -1;
    }
    sin->sin_addr.s_addr = htonl(addr);
    sin = &_so_mask.sin;
    sin->sin_addr.s_addr = htonl(mask);
    sin->sin_len = 0;
    sin->sin_family = 0;
    cp = (char *)(&sin->sin_addr + 1);
    while (*--cp == 0 && cp > (char *)sin)
        ;
    sin->sin_len = 1 + cp - (char *)sin;
}

/*
 * Interpret an argument as a network address of some kind,
 * returning 1 if a host address, 0 if a network address.
 */
- (int)getaddr: (int)which
             s: (char *)s
           hpp: (struct hostent **)hpp
            af: (int)af
         aflen: (int)aflen
{
    register sup su = NULL;
    struct hostent *hp;
    struct netent *np;
    u_long val;
    char *q;
    int returnval = 0;
    
    if (af == 0) {
        af = AF_INET;
        aflen = sizeof(struct sockaddr_in);
    }
    _rtm_addrs |= which;
    switch (which) {
        case RTA_DST:
            su = &_so_dst;
            break;
        case RTA_GATEWAY:
            su = &_so_gate;
            if (_iflag) {
                struct ifaddrs *ifap, *ifa;
                struct sockaddr_dl *sdl = NULL;
                
                if (getifaddrs(&ifap)) {
                    goto BAD;
                }
                
                for (ifa = ifap; ifa; ifa = ifa->ifa_next) {
                    if (ifa->ifa_addr->sa_family != AF_LINK)
                        continue;
                    
                    if (strcmp(s, ifa->ifa_name))
                        continue;
                    
                    sdl = (struct sockaddr_dl *)ifa->ifa_addr;
                }
                /* If we found it, then use it */
                if (sdl) {
                    /*
                     * Copy is safe since we have a
                     * sockaddr_storage member in sockunion{}.
                     * Note that we need to copy before calling
                     * freeifaddrs().
                     */
                    memcpy(&su->sdl, sdl, sdl->sdl_len);
                }
                freeifaddrs(ifap);
                if (sdl) {
                    returnval = 1;
                    goto OK;
                }
            }
            break;
        case RTA_NETMASK:
            su = &_so_mask;
            break;
        case RTA_GENMASK:
            su = &_so_genmask;
            break;
        case RTA_IFP:
            su = &_so_ifp;
            af = AF_LINK;
            break;
        case RTA_IFA:
            su = &_so_ifa;
            break;
        default:
            errno = EINVAL;
            goto BAD;
            /*NOTREACHED*/
    }
    su->sa.sa_len = aflen;
    su->sa.sa_family = af; /* cases that don't want it have left already */
    if (strcmp(s, "default") == 0) {
        /*
         * Default is net 0.0.0.0/0
         */
        switch (which) {
            case RTA_DST:
                _forcenet++;
                /* bzero(su, sizeof(*su)); *//* for readability */
                [self getaddr:RTA_NETMASK s:s hpp:0 af:af aflen:aflen];
                break;
            case RTA_NETMASK:
            case RTA_GENMASK:
                /* bzero(su, sizeof(*su)); *//* for readability */
                break;
        }
        return (0);
    }
    switch (af) {
        case AF_INET6:
        {
            struct addrinfo hints, *res;
            
            memset(&hints, 0, sizeof(hints));
            hints.ai_family = af;	/*AF_INET6*/
            hints.ai_flags = AI_NUMERICHOST;
            hints.ai_socktype = SOCK_DGRAM;		/*dummy*/
            if (getaddrinfo(s, "0", &hints, &res) != 0 ||
                res->ai_family != AF_INET6 ||
                res->ai_addrlen != sizeof(su->sin6)) {
                errno = EINVAL;
                goto BAD;
            }
            memcpy(&su->sin6, res->ai_addr, sizeof(su->sin6));

            if ((IN6_IS_ADDR_LINKLOCAL(&su->sin6.sin6_addr) ||
                 IN6_IS_ADDR_LINKLOCAL(&su->sin6.sin6_addr)) &&
                su->sin6.sin6_scope_id) {
                *(u_int16_t *)&su->sin6.sin6_addr.s6_addr[2] =
                htons(su->sin6.sin6_scope_id);
                su->sin6.sin6_scope_id = 0;
            }

            freeaddrinfo(res);
            returnval = 0;
            goto OK;
        }
            
        case AF_LINK:
            link_addr(s, &su->sdl);
            returnval = 1;
            goto OK;
            
            
        case PF_ROUTE:
            su->sa.sa_len = sizeof(*su);
            sockaddr(s, &su->sa);
            returnval = 1;
            goto OK;
            
        case AF_INET:
        default:
            break;
    }
    
    if (hpp == NULL)
        hpp = &hp;
    *hpp = NULL;
    
    q = strchr(s,'/');
    if (q && which == RTA_DST) {
        *q = '\0';
        if ((val = inet_addr(s)) != INADDR_NONE) {
            [self inet_makenetandmask:ntohl(val) sin:&su->sin bits:strtoul(q+1, 0, 0)];
            returnval = 0;
            goto OK;
        }
        *q = '/';
    }
    if ((which != RTA_DST || _forcenet == 0) &&
        (val = inet_addr(s)) != INADDR_NONE) {
        su->sin.sin_addr.s_addr = (in_addr_t)val;
        if (which != RTA_DST ||
            inet_lnaof(su->sin.sin_addr) != INADDR_ANY) {
            returnval = 1;
            goto OK;
        }
        else {
            val = ntohl(val);
            goto netdone;
        }
    }
    if (which == RTA_DST && _forcehost == 0 &&
        ((val = inet_network(s)) != INADDR_NONE ||
         ((np = getnetbyname(s)) != NULL && (val = np->n_net) != 0))) {
        netdone:
            [self inet_makenetandmask:val sin:&su->sin bits:0];
            //returnval = 0;
            goto BAD;
        }
    hp = gethostbyname(s);
    if (hp) {
        *hpp = hp;
        su->sin.sin_family = hp->h_addrtype;
        bcopy(hp->h_addr, (char *)&su->sin.sin_addr, 
              MIN(hp->h_length, sizeof(su->sin.sin_addr)));
        returnval = 1;
        goto OK;
    }
    errno = EFAULT;
    goto BAD;
    
OK:
    self.errorHappened = NO;
    return returnval;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

-(void)mask_addr
{
    int olen = _so_mask.sa.sa_len;
    register char *cp1 = olen + (char *)&_so_mask, *cp2;
    
    for (_so_mask.sa.sa_len = 0; cp1 > (char *)&_so_mask; )
        if (*--cp1 != 0) {
            _so_mask.sa.sa_len = 1 + cp1 - (char *)&_so_mask;
            break;
        }
    if ((_rtm_addrs & RTA_DST) == 0)
        return;
    switch (_so_dst.sa.sa_family) {
        case AF_INET:
        case AF_INET6:
        case AF_APPLETALK:
        case 0:
            return;
    }
    cp1 = _so_mask.sa.sa_len + 1 + (char *)&_so_dst;
    cp2 = _so_dst.sa.sa_len + 1 + (char *)&_so_dst;
    while (cp2 > cp1)
        *--cp2 = 0;
    cp2 = _so_mask.sa.sa_len + 1 + (char *)&_so_mask;
    while (cp1 > _so_dst.sa.sa_data)
        *--cp1 &= *--cp2;
}

- (int)rtmsg: (int)cmd
       flags: (int)flags
{
    static int seq;
    int rlen;
    register char *cp = _m_rtmsg.m_space;
    register int l;
    
#define NEXTADDR(w, u) \
if (_rtm_addrs & (w)) {\
l = ROUNDUP(u.sa.sa_len); bcopy((char *)&(u), cp, l); cp += l;\
}
    
    errno = 0;
    bzero((char *)&_m_rtmsg, sizeof(_m_rtmsg));
    if(cmd == RTM_GET) {
        if (_so_ifp.sa.sa_family == 0) {
            _so_ifp.sa.sa_family = AF_LINK;
            _so_ifp.sa.sa_len = sizeof(struct sockaddr_dl);
            _rtm_addrs |= RTA_IFP;
        }
    }
#define rtm _m_rtmsg.m_rtm
    rtm.rtm_type = cmd;
    rtm.rtm_flags = flags;
    rtm.rtm_version = RTM_VERSION;
    rtm.rtm_seq = ++seq;
    rtm.rtm_addrs = _rtm_addrs;
    rtm.rtm_rmx = _rt_metrics;
    rtm.rtm_inits = _rtm_inits;
    
    if (_rtm_addrs & RTA_NETMASK)
        [self mask_addr];
    NEXTADDR(RTA_DST, _so_dst);
    NEXTADDR(RTA_GATEWAY, _so_gate);
    NEXTADDR(RTA_NETMASK, _so_mask);
    NEXTADDR(RTA_GENMASK, _so_genmask);
    NEXTADDR(RTA_IFP, _so_ifp);
    NEXTADDR(RTA_IFA, _so_ifa);
    rtm.rtm_msglen = l = (int)(cp - (char *)&_m_rtmsg);

    if ((rlen = (int)write(self.sockfd, (char *)&_m_rtmsg, l)) < 0) {
        goto BAD;
    }
    if (cmd == RTM_GET) {
        do {
            l = (int)read(self.sockfd, (char *)&_m_rtmsg, sizeof(_m_rtmsg));
        } while (l > 0 && (rtm.rtm_seq != seq || rtm.rtm_pid != _pid));
        if (l < 0) {
            errno = 0;
            self.errorMessage = @"read from routing socket";
            goto BAD;
        }
    }
#undef rtm
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (void)clearAll {
    self.rtm_addrs = 0;
    self.rtm_inits = 0;
    self.iflag = 0;
    self.forcehost = 0;
    self.forcenet = 0;
    
    bzero(&_m_rtmsg, sizeof(_m_rtmsg));
    bzero(&_rt_metrics, sizeof(_rt_metrics));
    bzero(&_so_dst, sizeof(_so_dst));
    bzero(&_so_gate, sizeof(_so_gate));
    bzero(&_so_mask, sizeof(_so_mask));
    bzero(&_so_genmask, sizeof(_so_genmask));
    bzero(&_so_ifa, sizeof(_so_ifa));
    bzero(&_so_ifp, sizeof(_so_ifp));
}

- (int)addRouteNetwork: (NSString *)network
               netmask: (NSString *)netmask
               gateway: (NSString *)gateway
                  type: (IJTRoutetableType)type
              forcenet: (BOOL)forcenet
             forcehost: (BOOL)forcehost
               dynamic: (BOOL)dynamic {
    
    [self clearAll];
    int ishost = 0, ret, attempts, flags = 0;
    
    struct hostent *hp = 0;
    int aflen = sizeof(struct sockaddr_in);
    
    if(forcenet)
        _forcenet = 1;
    if(forcehost)
        _forcehost = 1;
    
    flags |= dynamic ? RTF_DYNAMIC : RTF_STATIC;
    
    [self getaddr:RTA_NETMASK s:(char *)[netmask UTF8String] hpp:&hp af:type aflen:aflen];
    [self getaddr:RTA_GATEWAY s:(char *)[gateway UTF8String] hpp:&hp af:type aflen:aflen];
    ishost = [self getaddr:RTA_DST s:(char *)[network UTF8String] hpp:&hp af:type aflen:aflen];
    
    if ((_rtm_addrs & RTA_DST) == 0) {
        ishost = [self getaddr:RTA_DST s:(char *)[network UTF8String] hpp:&hp af:type aflen:aflen];
    } else if ((_rtm_addrs & RTA_GATEWAY) == 0) {
        [self getaddr:RTA_GATEWAY s:(char *)[gateway UTF8String] hpp:&hp af:type aflen:aflen];
    } else {
        [self getaddr:RTA_NETMASK s:(char *)[netmask UTF8String] hpp:&hp af:type aflen:aflen];
    }
    
    if (_forcehost) {
        ishost = 1;
        if (type == AF_INET6) {
            _rtm_addrs &= ~RTA_NETMASK;
            memset((void *)&_so_mask, 0, sizeof(_so_mask));
        }
    }
    if (_forcenet)
        ishost = 0;
    
    flags |= RTF_UP;
    if (ishost)
        flags |= RTF_HOST;
    if (_iflag == 0)
        flags |= RTF_GATEWAY;
    if (_so_mask.sin.sin_family == AF_INET) {
        // make sure the mask is contiguous
        long i;
        for (i = 0; i < 32; i++)
            if (((_so_mask.sin.sin_addr.s_addr) & ntohl((1 << i))) != 0)
                break;
        for (; i < 32; i++)
            if (((_so_mask.sin.sin_addr.s_addr) & ntohl((1 << i))) == 0) {
                errno = 0;
                self.errorMessage = [NSString stringWithFormat:@"invalid mask: %s", inet_ntoa(_so_mask.sin.sin_addr)];
            }
    }
    for (attempts = 1; ; attempts++) {
        errno = 0;
        if ((ret = [self rtmsg:RTM_ADD flags:flags]) == 0)
            break;
        if (errno != ENETUNREACH && errno != ESRCH)
            break;
        if (type == AF_INET && hp && hp->h_addr_list[1]) {
            hp->h_addr_list++;
            bcopy(hp->h_addr_list[0], &_so_gate.sin.sin_addr,
                  MIN(hp->h_length, sizeof(_so_gate.sin.sin_addr)));
        } else
            break;
    }
    if(self.errorHappened)
        goto BAD;
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
    
}

- (int)addRouteNetwork: (NSString *)network
               netmask: (NSString *)netmask
               gateway: (NSString *)gateway
               dynamic: (BOOL)dynamic {
    return [self addRouteNetwork:network
                         netmask:netmask
                         gateway:gateway
                            type:IJTRoutetableTypeInet4
                        forcenet:YES
                       forcehost:NO
                         dynamic:dynamic];
}


- (int)addRouteHost: (NSString *)host
            gateway: (NSString *)gateway
            dynamic: (BOOL)dynamic {
    return [self addRouteNetwork:host
                         netmask:@"255.255.255.255"
                         gateway:gateway
                            type:IJTRoutetableTypeInet4
                        forcenet:NO
                       forcehost:YES
                         dynamic:dynamic];
}



@end
