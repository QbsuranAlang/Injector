//
//  IJTFirewall.m
//  InjectorFirewall
//
//  Created by 聲華 陳 on 2015/5/25.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTFirewall.h"
#define PRIVATE
#import <net/if.h>
#import <net/pfvar.h>
#import <fcntl.h>
#import <unistd.h>
#import <string.h>
#import <sys/ioctl.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/stat.h>

@interface IJTFirewall ()

@property (nonatomic) int fd;

@end

@implementation IJTFirewall

- (id)init {
    self = [super init];
    if(self) {
        self.fd = -1;
        [self open];
    }
    return self;
}

- (void)open {
    if(self.fd < 0) {
        self.fd = open("/dev/pf", O_RDWR);
        if(self.fd < 0)
            goto  BAD;
    }
    
    struct stat st = {0};
    //create dir
    if (stat("/var/root/Injector/", &st) == -1) {
        mkdir("/var/root/Injector/", 0755);
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
    if(self.fd >= 0) {
        close(self.fd);
        self.fd = -1;
    }
}


- (int)getAllRulesRegisterTarget: (id)target
                        selector: (SEL)selector
                          object: (id)object {
    struct pfioc_rule pr;
    FirewallShowCallback firewallshowcallback = NULL;
    
    if(target && selector) {
        firewallshowcallback = (FirewallShowCallback)[target methodForSelector:selector];
    }
    
    memset(&pr, 0, sizeof(pr));
    if(ioctl(self.fd, DIOCGETRULES, &pr) < 0)
        goto BAD;
    
    for(int n = 0, max = pr.nr ; n < max ; n++) {
        pr.nr = n;
        if(ioctl(self.fd, DIOCGETRULE, &pr) < 0)
            goto BAD;
        
        if(firewallshowcallback) {
            char *device = pr.rule.ifname;
            sa_family_t af = pr.rule.af;
            u_int8_t action = pr.rule.action;
            u_int8_t dir = pr.rule.direction;
            u_int8_t proto = pr.rule.proto;
            struct in_addr src = pr.rule.src.addr.v.a.addr.v4;
            struct in_addr dst = pr.rule.dst.addr.v.a.addr.v4;
            struct in_addr srcmask = pr.rule.src.addr.v.a.mask.v4;
            struct in_addr dstmask = pr.rule.dst.addr.v.a.mask.v4;
            u_int16_t srcport1 = ntohs(pr.rule.src.xport.range.port[0]);
            u_int16_t srcport2 = ntohs(pr.rule.src.xport.range.port[1]);
            u_int16_t dstport1 = ntohs(pr.rule.dst.xport.range.port[0]);
            u_int16_t dstport2 = ntohs(pr.rule.dst.xport.range.port[1]);
            IJTFirewallTCPFlag tcpFlags = pr.rule.flags;
            IJTFirewallTCPFlag tcpFlagsMask = pr.rule.flagset;
            u_int8_t type = pr.rule.type - 1;
            u_int8_t code = pr.rule.code - 1;
            BOOL keepstatue = pr.rule.keep_state;
            BOOL quick = pr.rule.quick;
            
            if(pr.rule.src.xport.range.op == PF_OP_EQ)
                srcport2 = srcport1;
            if(pr.rule.dst.xport.range.op == PF_OP_EQ)
                dstport2 = dstport1;
            
            firewallshowcallback(target, selector,
                                 [NSString stringWithUTF8String:device],
                                 af, action, dir, proto,
                                 [NSString stringWithUTF8String:inet_ntoa(src)],
                                 [NSString stringWithUTF8String:inet_ntoa(dst)],
                                 [NSString stringWithUTF8String:inet_ntoa(srcmask)],
                                 [NSString stringWithUTF8String:inet_ntoa(dstmask)],
                                 srcport1, srcport2, dstport1, dstport2,
                                 tcpFlags, tcpFlagsMask,
                                 type, code,
                                 keepstatue, quick, object);
            
            continue;
        }
        [IJTFirewall dumpRule:pr];
    }
    
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

#pragma mark delete
- (int)deleteAllRulesRegisterTarget: (id)target
                           selector: (SEL)selector
                             object: (id)object {
    struct pfioc_rule pdr;
    memset(&pdr, 0, sizeof(pdr));
    
    //get all rules
    if (ioctl(self.fd, DIOCGETRULES, &pdr) < 0) {
        goto BAD;
    }
    //delete one by one
    for(int n = 0, max = pdr.nr ; n < max ; n++) {
        pdr.nr = 0;
        if(ioctl(self.fd, DIOCGETRULE, &pdr) < 0)
            goto BAD;
        [self deleteRule:pdr target:target selector:selector object:object];
        
        //get again
        if (ioctl(self.fd, DIOCGETRULES, &pdr) < 0) {
            goto BAD;
        }
    }
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
    
}

- (int)deleteRuleAtInterface: (NSString *)interface
                          op: (IJTFirewallOperator)op
                         dir: (IJTFirewallDirection)dir
                       proto: (IJTFirewallProtocol)proto
                      family: (sa_family_t)family
                     srcAddr: (NSString *)srcAddr
                     dstAddr: (NSString *)dstAddr
                     srcMask: (NSString *)srcMask
                     dstMask: (NSString *)dstMask
                srcStartPort: (u_int16_t)srcStartPort
                  srcEndPort: (u_int16_t)srcEndPort
                dstStartPort: (u_int16_t)dstStartPort
                  dstEndPort: (u_int16_t)dstEndPort
                    tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                    icmpType: (u_int8_t)icmpType
                    icmpCode: (u_int8_t)icmpCode
                   keepState: (BOOL)keepState
                       quick: (BOOL)quick {
    struct pfioc_rule pdr; //need to delete
    pdr = [self
           searchRuleAtInterface:interface
           op:op dir:dir
           proto:proto
           family:AF_INET
           srcAddr:srcAddr
           dstAddr:dstAddr
           srcMask:srcMask
           dstMask:dstMask
           srcStartPort:srcStartPort
           srcEndPort:srcEndPort
           dstStartPort:dstStartPort
           dstEndPort:dstEndPort
           tcpFlags:tcpFlags
           tcpFlagsMask:tcpFlagsMask
           icmpType:icmpType
           icmpCode:icmpCode
           keepState:keepState
           quick:quick];
    if(self.errorCode != EEXIST) {
        errno = ENOENT;
        goto BAD;
    }
    
    return [self deleteRule:pdr target:nil selector:nil object:nil];
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}


- (int)deleteTCPOrUDPRuleAtInterface: (NSString *)interface
                                  op: (IJTFirewallOperator)op
                                 dir: (IJTFirewallDirection)dir
                               proto: (IJTFirewallProtocol)proto
                              family: (sa_family_t)family
                             srcAddr: (NSString *)srcAddr
                             dstAddr: (NSString *)dstAddr
                             srcMask: (NSString *)srcMask
                             dstMask: (NSString *)dstMask
                        srcStartPort: (u_int16_t)srcStartPort
                          srcEndPort: (u_int16_t)srcEndPort
                        dstStartPort: (u_int16_t)dstStartPort
                          dstEndPort: (u_int16_t)dstEndPort
                            tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                        tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                           keepState: (BOOL)keepState
                               quick: (BOOL)quick {
    if(proto != IJTFirewallProtocolTCP && proto != IJTFirewallProtocolUDP) {
        self.errorCode = EINVAL;
        self.errorHappened = YES;
        return -1;
    }
    return [self deleteRuleAtInterface:interface
                                    op:op
                                   dir:dir
                                 proto:proto
                                family:family
                               srcAddr:srcAddr
                               dstAddr:dstAddr
                               srcMask:srcMask
                               dstMask:dstMask
                          srcStartPort:srcStartPort
                            srcEndPort:srcEndPort
                          dstStartPort:dstStartPort
                            dstEndPort:dstEndPort
                              tcpFlags:tcpFlags
                          tcpFlagsMask:tcpFlagsMask
                              icmpType:0
                              icmpCode:0
                             keepState:keepState
                                 quick:quick];
}

- (int)deleteTCPOrUDPRuleAtInterface: (NSString *)interface
                                  op: (IJTFirewallOperator)op
                                 dir: (IJTFirewallDirection)dir
                               proto: (IJTFirewallProtocol)proto
                              family: (sa_family_t)family
                             srcAddr: (NSString *)srcAddr
                             dstAddr: (NSString *)dstAddr
                             srcMask: (NSString *)srcMask
                             dstMask: (NSString *)dstMask
                             srcPort: (u_int16_t)srcPort
                             dstPort: (u_int16_t)dstPort
                            tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                        tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                           keepState: (BOOL)keepState
                               quick: (BOOL)quick {
    if(proto != IJTFirewallProtocolTCP && proto != IJTFirewallProtocolUDP) {
        self.errorCode = EINVAL;
        self.errorHappened = YES;
        return -1;
    }
    u_int16_t srcEndPort = srcPort;
    u_int16_t dstEndPort = dstPort;
    if(family == 0)
        srcEndPort = dstEndPort = 0;
    
    return [self deleteRuleAtInterface:interface
                                    op:op
                                   dir:dir
                                 proto:proto
                                family:family
                               srcAddr:srcAddr
                               dstAddr:dstAddr
                               srcMask:srcMask
                               dstMask:dstMask
                          srcStartPort:srcPort
                            srcEndPort:srcEndPort
                          dstStartPort:dstPort
                            dstEndPort:dstEndPort
                              tcpFlags:tcpFlags
                          tcpFlagsMask:tcpFlagsMask
                              icmpType:0
                              icmpCode:0
                             keepState:keepState
                                 quick:quick];
}

- (int)deleteTCPOrUDPRuleAtInterface: (NSString *)interface
                                  op: (IJTFirewallOperator)op
                                 dir: (IJTFirewallDirection)dir
                               proto: (IJTFirewallProtocol)proto
                              family: (sa_family_t)family
                             srcAddr: (NSString *)srcAddr
                             dstAddr: (NSString *)dstAddr
                             srcMask: (NSString *)srcMask
                             dstMask: (NSString *)dstMask
                        srcStartPort: (u_int16_t)srcStartPort
                          srcEndPort: (u_int16_t)srcEndPort
                             dstPort: (u_int16_t)dstPort
                            tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                        tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                           keepState: (BOOL)keepState
                               quick: (BOOL)quick {
    if(proto != IJTFirewallProtocolTCP && proto != IJTFirewallProtocolUDP) {
        self.errorCode = EINVAL;
        self.errorHappened = YES;
        return -1;
    }
    return [self deleteRuleAtInterface:interface
                                    op:op
                                   dir:dir
                                 proto:proto
                                family:family
                               srcAddr:srcAddr
                               dstAddr:dstAddr
                               srcMask:srcMask
                               dstMask:dstMask
                          srcStartPort:srcStartPort
                            srcEndPort:srcEndPort
                          dstStartPort:dstPort
                            dstEndPort:dstPort
                              tcpFlags:tcpFlags
                          tcpFlagsMask:tcpFlagsMask
                              icmpType:0
                              icmpCode:0
                             keepState:keepState
                                 quick:quick];
}

- (int)deleteTCPOrUDPRuleAtInterface: (NSString *)interface
                                  op: (IJTFirewallOperator)op
                                 dir: (IJTFirewallDirection)dir
                               proto: (IJTFirewallProtocol)proto
                              family: (sa_family_t)family
                             srcAddr: (NSString *)srcAddr
                             dstAddr: (NSString *)dstAddr
                             srcMask: (NSString *)srcMask
                             dstMask: (NSString *)dstMask
                             srcPort: (u_int16_t)srcPort
                        dstStartPort: (u_int16_t)dstStartPort
                          dstEndPort: (u_int16_t)dstEndPort
                            tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                        tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                           keepState: (BOOL)keepState
                               quick: (BOOL)quick {
    if(proto != IJTFirewallProtocolTCP && proto != IJTFirewallProtocolUDP) {
        self.errorCode = EINVAL;
        self.errorHappened = YES;
        return -1;
    }
    return [self deleteRuleAtInterface:interface
                                    op:op
                                   dir:dir
                                 proto:proto
                                family:family
                               srcAddr:srcAddr
                               dstAddr:dstAddr
                               srcMask:srcMask
                               dstMask:dstMask
                          srcStartPort:srcPort
                            srcEndPort:srcPort
                          dstStartPort:dstStartPort
                            dstEndPort:dstEndPort
                              tcpFlags:tcpFlags
                          tcpFlagsMask:tcpFlagsMask
                              icmpType:0
                              icmpCode:0
                             keepState:keepState
                                 quick:quick];
}

- (int)deleteICMPRuleAtInterface: (NSString *)interface
                              op: (IJTFirewallOperator)op
                             dir: (IJTFirewallDirection)dir
                         srcAddr: (NSString *)srcAddr
                         dstAddr: (NSString *)dstAddr
                         srcMask: (NSString *)srcMask
                         dstMask: (NSString *)dstMask
                        icmpType: (u_int8_t)icmpType
                        icmpCode: (u_int8_t)icmpCode
                       keepState: (BOOL)keepState
                           quick: (BOOL)quick {
    return [self deleteRuleAtInterface:interface
                                    op:op
                                   dir:dir
                                 proto:IJTFirewallProtocolICMP
                                family:AF_INET
                               srcAddr:srcAddr
                               dstAddr:dstAddr
                               srcMask:srcMask
                               dstMask:dstMask
                          srcStartPort:0
                            srcEndPort:0
                          dstStartPort:0
                            dstEndPort:0
                              tcpFlags:0
                          tcpFlagsMask:0
                              icmpType:icmpType
                              icmpCode:icmpCode
                             keepState:keepState
                                 quick:quick];
}

- (int)deleteRuleAtInterface: (NSString *)interface
                          op: (IJTFirewallOperator)op
                         dir: (IJTFirewallDirection)dir
                      family: (sa_family_t)family
                     srcAddr: (NSString *)srcAddr
                     dstAddr: (NSString *)dstAddr
                     srcMask: (NSString *)srcMask
                     dstMask: (NSString *)dstMask
                   keepState: (BOOL)keepState
                       quick: (BOOL)quick {
    return [self deleteRuleAtInterface:interface
                                    op:op
                                   dir:dir
                                 proto:IJTFirewallProtocolIP
                                family:family
                               srcAddr:srcAddr
                               dstAddr:dstAddr
                               srcMask:srcMask
                               dstMask:dstMask
                          srcStartPort:0
                            srcEndPort:0
                          dstStartPort:0
                            dstEndPort:0
                              tcpFlags:0
                          tcpFlagsMask:0
                              icmpType:0
                              icmpCode:0
                             keepState:keepState
                                 quick:quick];

}


- (int)deleteRule: (struct pfioc_rule)pdr
           target: (id)target
         selector: (SEL)selector
           object: (id)object {
    FirewallDeleteCallback firewalldeletecallback = NULL;
    char *device = NULL;
    sa_family_t af = AF_UNSPEC;
    u_int8_t action = 0, dir = 0, proto = 0, type = 0, code = 0;
    struct in_addr src = {}, dst = {}, srcmask = {}, dstmask = {};
    u_int16_t srcport1 = 0, srcport2 = 0, dstport1 = 0, dstport2 = 0;
    IJTFirewallTCPFlag tcpFlags = 0, tcpFlagsMask = 0;
    BOOL keepstatue = NO, quick = NO;
    
    if(target && selector) {
        firewalldeletecallback = (FirewallDeleteCallback)[target methodForSelector:selector];
    }
    
    //get specified rule
    struct pfioc_pooladdr ppa;
    
    if (ioctl(self.fd, DIOCBEGINADDRS, &ppa) < 0)
        goto BAD;
    pdr.pool_ticket = ppa.ticket;
    
    //need to delete
    pdr.action = PF_CHANGE_REMOVE;
    if(ioctl(self.fd, DIOCCHANGERULE, &pdr) < 0)
        goto BAD;
    
    device = pdr.rule.ifname;
    af = pdr.rule.af;
    action = pdr.rule.action;
    dir = pdr.rule.direction;
    proto = pdr.rule.proto;
    src = pdr.rule.src.addr.v.a.addr.v4;
    dst = pdr.rule.dst.addr.v.a.addr.v4;
    srcmask = pdr.rule.src.addr.v.a.mask.v4;
    dstmask = pdr.rule.dst.addr.v.a.mask.v4;
    srcport1 = ntohs(pdr.rule.src.xport.range.port[0]);
    srcport2 = ntohs(pdr.rule.src.xport.range.port[1]);
    dstport1 = ntohs(pdr.rule.dst.xport.range.port[0]);
    dstport2 = ntohs(pdr.rule.dst.xport.range.port[1]);
    tcpFlags = pdr.rule.flags;
    tcpFlagsMask = pdr.rule.flagset;
    type = pdr.rule.type - 1;
    code = pdr.rule.code - 1;
    keepstatue = pdr.rule.keep_state;
    quick = pdr.rule.quick;
    
    if(pdr.rule.src.xport.range.op == PF_OP_EQ)
        srcport2 = srcport1;
    if(pdr.rule.dst.xport.range.op == PF_OP_EQ)
        dstport2 = dstport1;
    
    if(firewalldeletecallback) {
        firewalldeletecallback(target, selector,
                               [NSString stringWithUTF8String:device],
                               af, action, dir, proto,
                               [NSString stringWithUTF8String:inet_ntoa(src)],
                               [NSString stringWithUTF8String:inet_ntoa(dst)],
                               [NSString stringWithUTF8String:inet_ntoa(srcmask)],
                               [NSString stringWithUTF8String:inet_ntoa(dstmask)],
                               srcport1, srcport2, dstport1, dstport2,
                               tcpFlags, tcpFlagsMask,
                               type, code,
                               keepstatue, quick, 0, object);
    }
    else {
        printf("Deleted: ");
        [IJTFirewall dumpRule:pdr];
    }
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(firewalldeletecallback) {
        firewalldeletecallback(target, selector,
                               [NSString stringWithUTF8String:device],
                               af, action, dir, proto,
                               [NSString stringWithUTF8String:inet_ntoa(src)],
                               [NSString stringWithUTF8String:inet_ntoa(dst)],
                               [NSString stringWithUTF8String:inet_ntoa(srcmask)],
                               [NSString stringWithUTF8String:inet_ntoa(dstmask)],
                               srcport1, srcport2, dstport1, dstport2,
                               tcpFlags, tcpFlagsMask,
                               type, code,
                               keepstatue, quick, self.errorCode, object);
    }
    else {
        printf("Fail to delete: ");
        [IJTFirewall dumpRule:pdr];
    }
    
    self.errorHappened = YES;
    return -1;
}

- (BOOL)ipAddreess: (in_addr_t)addr1 equal: (NSString *)addr2 {
    in_addr_t temp;
    inet_pton(AF_INET, [addr2 UTF8String], &temp);
    return temp == addr1 ? YES : NO;
}

- (struct pfioc_rule)searchRuleAtInterface: (NSString *)interface
                                        op: (IJTFirewallOperator)op
                                       dir: (IJTFirewallDirection)dir
                                     proto: (IJTFirewallProtocol)proto
                                    family: (sa_family_t)family
                                   srcAddr: (NSString *)srcAddr
                                   dstAddr: (NSString *)dstAddr
                                   srcMask: (NSString *)srcMask
                                   dstMask: (NSString *)dstMask
                              srcStartPort: (u_int16_t)srcStartPort
                                srcEndPort: (u_int16_t)srcEndPort
                              dstStartPort: (u_int16_t)dstStartPort
                                dstEndPort: (u_int16_t)dstEndPort
                                  tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                              tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                                  icmpType: (u_int8_t)icmpType
                                  icmpCode: (u_int8_t)icmpCode
                                 keepState: (BOOL)keepState
                                     quick: (BOOL)quick {
    struct pfioc_rule pr;
    
    memset(&pr, 0, sizeof(pr));
    
    //get all rules
    if (ioctl(self.fd, DIOCGETRULES, &pr) < 0) {
        goto BAD;
    }
    //find rule
    while ((int)--pr.nr >= 0) {
        if (ioctl(self.fd, DIOCGETRULE, &pr) < 0)
            goto BAD;
        
        if(pr.rule.action == op && pr.rule.direction == dir &&
           !strcmp([interface UTF8String], pr.rule.ifname) && pr.rule.proto == proto &&
           [self ipAddreess:pr.rule.src.addr.v.a.addr.v4.s_addr equal:srcAddr] &&
           [self ipAddreess:pr.rule.src.addr.v.a.mask.v4.s_addr equal:srcMask] &&
           [self ipAddreess:pr.rule.dst.addr.v.a.addr.v4.s_addr equal:dstAddr] &&
           [self ipAddreess:pr.rule.dst.addr.v.a.mask.v4.s_addr equal:dstMask] &&
           pr.rule.keep_state == keepState) {
            
            //what the hell
            switch (proto) {
                case IJTFirewallProtocolIP:
                    goto FOUND;
                    
                case IJTFirewallProtocolTCP:
                case IJTFirewallProtocolUDP:
                    if(pr.rule.src.xport.range.port[0] == htons(srcStartPort) &&
                       pr.rule.src.xport.range.port[1] == htons(srcEndPort) &&
                       pr.rule.dst.xport.range.port[0] == htons(dstStartPort) &&
                       pr.rule.dst.xport.range.port[1] == htons(dstEndPort)) {
                        if(proto == IJTFirewallProtocolTCP) {
                            if(pr.rule.flags == tcpFlags &&
                               pr.rule.flagset == tcpFlagsMask) {
                                goto FOUND;
                            }
                            else
                                break;
                        }
                        else {
                            goto FOUND;
                        }
                    }
                    break;
                case IJTFirewallProtocolICMP:
                    if(icmpType  == pr.rule.type - 1 && icmpCode == pr.rule.code - 1) {
                        goto FOUND;
                    }
                    break;
                    
                default:
                    errno = EINVAL;
                    goto BAD;
            }
            continue;
        }//end try
    }//end while
    //not found
    errno = ENOENT;
    
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return pr;
FOUND:
    self.errorCode = EEXIST;
    self.errorHappened = NO;
    return pr;
}

- (in_addr_t)ipaddress_pton: (NSString *)ipAddress {
    in_addr_t temp;
    inet_pton(AF_INET, [ipAddress UTF8String], &temp);
    return temp;
}

#pragma mark add rule
- (int)addRuleAtInterface: (NSString *)interface
                       op: (IJTFirewallOperator)op
                      dir: (IJTFirewallDirection)dir
                    proto: (IJTFirewallProtocol)proto
                   family: (sa_family_t)family
                  srcAddr: (NSString *)srcAddr
                  dstAddr: (NSString *)dstAddr
                  srcMask: (NSString *)srcMask
                  dstMask: (NSString *)dstMask
             srcStartPort: (u_int16_t)srcStartPort
               srcEndPort: (u_int16_t)srcEndPort
             dstStartPort: (u_int16_t)dstStartPort
               dstEndPort: (u_int16_t)dstEndPort
                 tcpFlags: (IJTFirewallTCPFlag)tcpFlags
             tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                 icmpType: (u_int8_t)icmpType
                 icmpCode: (u_int8_t)icmpCode
                keepState: (BOOL)keepState
                    quick: (BOOL)quick {
    
    struct pfioc_rule par;
    
    par = [self
           searchRuleAtInterface:interface
           op:op dir:dir
           proto:proto
           family:AF_INET
           srcAddr:srcAddr
           dstAddr:dstAddr
           srcMask:srcMask
           dstMask:dstMask
           srcStartPort:srcStartPort
           srcEndPort:srcEndPort
           dstStartPort:dstStartPort
           dstEndPort:dstEndPort
           tcpFlags:tcpFlags
           tcpFlagsMask:tcpFlagsMask
           icmpType:icmpType
           icmpCode:icmpCode
           keepState:keepState
           quick:quick];
    if(self.errorCode == EEXIST) {
        errno = EEXIST;
        goto BAD;
    }
    
    strlcpy(par.rule.ifname, [interface UTF8String], sizeof(par.rule.ifname));
    par.rule.af = AF_INET;
    par.rule.action = op;
    par.rule.direction = dir;
    par.rule.proto = proto;
    par.rule.src.addr.v.a.addr.v4.s_addr = [self ipaddress_pton:srcAddr];
    par.rule.src.addr.v.a.mask.v4.s_addr = [self ipaddress_pton:srcMask];
    par.rule.dst.addr.v.a.addr.v4.s_addr = [self ipaddress_pton:dstAddr];
    par.rule.dst.addr.v.a.mask.v4.s_addr = [self ipaddress_pton:dstMask];
    par.rule.keep_state = keepState ? 1 : 0;
    par.rule.quick = quick ? 1 : 0;
    if(proto == IJTFirewallProtocolTCP) {
        par.rule.flags = tcpFlags;
        par.rule.flagset = tcpFlagsMask;
    }
    
    switch (proto) {
        case IJTFirewallProtocolTCP:
        case IJTFirewallProtocolUDP:
        case IJTFirewallProtocolIP:
            par.rule.src.xport.range.port[0] = htons(srcStartPort);
            par.rule.src.xport.range.port[1] = htons(srcEndPort);
            if(par.rule.src.xport.range.port[0] == 0 && par.rule.src.xport.range.port[1] == 0)
                par.rule.src.xport.range.op = PF_OP_NONE;
            else if(par.rule.src.xport.range.port[0] == par.rule.src.xport.range.port[1])
                par.rule.src.xport.range.op = PF_OP_EQ;
            else
                par.rule.src.xport.range.op = PF_OP_IRG;
            
            par.rule.dst.xport.range.port[0] = htons(dstStartPort);
            par.rule.dst.xport.range.port[1] = htons(dstEndPort);
            if(par.rule.dst.xport.range.port[0] == 0 && par.rule.dst.xport.range.port[1] == 0)
                par.rule.dst.xport.range.op = PF_OP_NONE;
            else if(par.rule.dst.xport.range.port[0] == par.rule.dst.xport.range.port[1])
                par.rule.dst.xport.range.op = PF_OP_EQ;
            else
                par.rule.dst.xport.range.op = PF_OP_IRG;
            
            break;
            
        case IJTFirewallProtocolICMP:
            par.rule.type = icmpType + 1;
            par.rule.code = icmpCode + 1;
            par.rule.keep_state = 1;
        default:
            break;
    }
    
    struct pfioc_pooladdr ppa;
    
    if (ioctl(self.fd, DIOCBEGINADDRS, &ppa) < 0)
        goto BAD;
    par.pool_ticket = ppa.ticket;
    
    par.action = PF_CHANGE_ADD_TAIL;
    
    if(ioctl(self.fd, DIOCCHANGERULE, &par) < 0)
        goto BAD;
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

+ (void)dumpRule: (struct pfioc_rule)pr {
    char *device = pr.rule.ifname;
    sa_family_t af = pr.rule.af;
    u_int8_t action = pr.rule.action;
    u_int8_t dir = pr.rule.direction;
    u_int8_t proto = pr.rule.proto;
    struct in_addr src = pr.rule.src.addr.v.a.addr.v4;
    struct in_addr dst = pr.rule.dst.addr.v.a.addr.v4;
    struct in_addr srcmask = pr.rule.src.addr.v.a.mask.v4;
    struct in_addr dstmask = pr.rule.dst.addr.v.a.mask.v4;
    u_int16_t srcport1 = ntohs(pr.rule.src.xport.range.port[0]);
    u_int16_t srcport2 = ntohs(pr.rule.src.xport.range.port[1]);
    u_int16_t dstport1 = ntohs(pr.rule.dst.xport.range.port[0]);
    u_int16_t dstport2 = ntohs(pr.rule.dst.xport.range.port[1]);
    IJTFirewallTCPFlag tcpFlags = pr.rule.flags;
    IJTFirewallTCPFlag tcpFlagsMask = pr.rule.flagset;
    u_int8_t type = pr.rule.type - 1;
    u_int8_t code = pr.rule.code - 1;
    BOOL quick = pr.rule.quick ? YES : NO;
    BOOL keep_state = pr.rule.keep_state ? YES : NO;
    
    printf("Family: ");
    switch (af) {
        case AF_INET: printf("Internet4"); break;
        case 0: printf("0"); break;
        case AF_INET6: printf("Internet6, I don\'t dump it\n"); return;
        default: printf("%d, I don\'t dump it\n", af); return;
    }
    
    printf(", Action: ");
    switch (action) {
        case PF_DROP: printf("Block"); break;
        case PF_PASS: printf("Allow"); break;
        default: printf("Unknown: %d, check net/pfvar.h", action); break;
    }
    
    printf(", Direction: ");
    switch (dir) {
        case PF_INOUT: printf("IN/OUT"); break;
        case PF_IN: printf("IN"); break;
        case PF_OUT: printf("OUT"); break;
        default: printf("impossible direction"); break;
    }
    
    if(quick)
        printf(", Quick");
    
    printf(", Device: %s", device);
    
    printf(", Protocol: ");
    switch (proto) {
        case IPPROTO_ICMP: printf("ICMP"); break;
        case IPPROTO_TCP: printf("TCP"); break;
        case IPPROTO_UDP: printf("UDP"); break;
        default: printf("%d", proto); break;
    }
    
    if(src.s_addr != 0)
        printf(", Src: %s", inet_ntoa(src));
    if(srcmask.s_addr != 0)
        printf(", Src mask: %s", inet_ntoa(srcmask));
    if(dst.s_addr != 0)
        printf(", Dst: %s", inet_ntoa(dst));
    if(dstmask.s_addr != 0)
        printf(", Dst mask: %s", inet_ntoa(dstmask));
    
    if(proto == IPPROTO_ICMP) {
        printf(", Type: %d, Code: %d", type, code);
    }
    else {
        if(proto == IPPROTO_TCP || proto == IPPROTO_UDP) {
            if(srcport1 == 0 && srcport2 == 0)
                printf(", Src port: Any");
            else if(pr.rule.src.xport.range.op == PF_OP_EQ)
                printf(", Src port: %d", srcport1);
            else
                printf(", Src port: form %d to %d", srcport1, srcport2);
            
            if(dstport1 == 0 && dstport2 == 0)
                printf(", Dst port: Any");
            else if(pr.rule.dst.xport.range.op == PF_OP_EQ)
                printf(", Dst port: %d", dstport1);
            else
                printf(", Dst port: form %d to %d", dstport1, dstport2);
        }
        else {
            printf(", Src start port: %d, end port: %d", srcport1, srcport2);
            printf(", Dst start port: %d, end port: %d", dstport1, dstport2);
        }
    }
    
    if(keep_state)
        printf(", Keep state");
    
    printf(", Src port op: %d, Dst port op: %d", pr.rule.src.xport.range.op, pr.rule.dst.xport.range.op);
    
    if(tcpFlags || tcpFlagsMask) {
        printf(", ");
        printf("%s/%s", [[IJTFirewall tcpFlags2String:tcpFlags] UTF8String], [[IJTFirewall tcpFlags2String:tcpFlagsMask] UTF8String]);
    }
    
    printf("\n");
}

struct t_flags {
    uint8_t	t_mask;
    char	t_val;
} fw_bits[] = {
    {IJTFirewallTCPFlagFIN,	'F' },
    {IJTFirewallTCPFlagSYN, 'S' },
    {IJTFirewallTCPFlagRST, 'R' },
    {IJTFirewallTCPFlagPUSH, 'P' },
    {IJTFirewallTCPFlagACK, 'A' },
    {IJTFirewallTCPFlagURG, 'U' },
    {IJTFirewallTCPFlagECE, 'E' },
    {IJTFirewallTCPFlagCWR, 'W' },
    { 0 }
};

+ (NSString *)tcpFlags2String: (IJTFirewallTCPFlag)f {
    char name[20], *flags;
    struct t_flags *p = fw_bits;
    
    memset(name, 0, sizeof(name));
    for (flags = name; p->t_mask; p++)
        if (p->t_mask & f)
            *flags++ = p->t_val;
    *flags = '\0';
    
    return [NSString stringWithUTF8String:name];
}

- (int)addTCPOrUDPRuleAtInterface: (NSString *)interface
                               op: (IJTFirewallOperator)op
                              dir: (IJTFirewallDirection)dir
                            proto: (IJTFirewallProtocol)proto
                           family: (sa_family_t)family
                          srcAddr: (NSString *)srcAddr
                          dstAddr: (NSString *)dstAddr
                          srcMask: (NSString *)srcMask
                          dstMask: (NSString *)dstMask
                     srcStartPort: (u_int16_t)srcStartPort
                       srcEndPort: (u_int16_t)srcEndPort
                     dstStartPort: (u_int16_t)dstStartPort
                       dstEndPort: (u_int16_t)dstEndPort
                         tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                     tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                        keepState: (BOOL)keepState
                            quick: (BOOL)quick {
    if(proto != IJTFirewallProtocolTCP && proto != IJTFirewallProtocolUDP) {
        self.errorCode = EINVAL;
        self.errorHappened = YES;
        return -1;
    }
    return [self addRuleAtInterface:interface
                                 op:op
                                dir:dir
                              proto:proto
                             family:family
                            srcAddr:srcAddr
                            dstAddr:dstAddr
                            srcMask:srcMask
                            dstMask:dstMask
                       srcStartPort:srcStartPort
                         srcEndPort:srcEndPort
                       dstStartPort:dstStartPort
                         dstEndPort:dstEndPort
                           tcpFlags:tcpFlags
                       tcpFlagsMask:tcpFlagsMask
                           icmpType:0
                           icmpCode:0
                          keepState:keepState
                              quick:quick];
}

- (int)addTCPOrUDPRuleAtInterface: (NSString *)interface
                               op: (IJTFirewallOperator)op
                              dir: (IJTFirewallDirection)dir
                            proto: (IJTFirewallProtocol)proto
                           family: (sa_family_t)family
                          srcAddr: (NSString *)srcAddr
                          dstAddr: (NSString *)dstAddr
                          srcMask: (NSString *)srcMask
                          dstMask: (NSString *)dstMask
                          srcPort: (u_int16_t)srcPort
                          dstPort: (u_int16_t)dstPort
                         tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                     tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                        keepState: (BOOL)keepState
                            quick: (BOOL)quick {
    if(proto != IJTFirewallProtocolTCP && proto != IJTFirewallProtocolUDP) {
        self.errorCode = EINVAL;
        self.errorHappened = YES;
        return -1;
    }
    return [self addRuleAtInterface:interface
                                 op:op
                                dir:dir
                              proto:proto
                             family:family
                            srcAddr:srcAddr
                            dstAddr:dstAddr
                            srcMask:srcMask
                            dstMask:dstMask
                       srcStartPort:srcPort
                         srcEndPort:srcPort
                       dstStartPort:dstPort
                         dstEndPort:dstPort
                           tcpFlags:tcpFlags
                       tcpFlagsMask:tcpFlagsMask
                           icmpType:0
                           icmpCode:0
                          keepState:keepState
                              quick:quick];
}

- (int)addTCPOrUDPRuleAtInterface: (NSString *)interface
                               op: (IJTFirewallOperator)op
                              dir: (IJTFirewallDirection)dir
                            proto: (IJTFirewallProtocol)proto
                           family: (sa_family_t)family
                          srcAddr: (NSString *)srcAddr
                          dstAddr: (NSString *)dstAddr
                          srcMask: (NSString *)srcMask
                          dstMask: (NSString *)dstMask
                     srcStartPort: (u_int16_t)srcStartPort
                       srcEndPort: (u_int16_t)srcEndPort
                          dstPort: (u_int16_t)dstPort
                         tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                     tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                        keepState: (BOOL)keepState
                            quick: (BOOL)quick {
    if(proto != IJTFirewallProtocolTCP && proto != IJTFirewallProtocolUDP) {
        self.errorCode = EINVAL;
        self.errorHappened = YES;
        return -1;
    }
    return [self addRuleAtInterface:interface
                                 op:op
                                dir:dir
                              proto:proto
                             family:family
                            srcAddr:srcAddr
                            dstAddr:dstAddr
                            srcMask:srcMask
                            dstMask:dstMask
                       srcStartPort:srcStartPort
                         srcEndPort:srcEndPort
                       dstStartPort:dstPort
                         dstEndPort:dstPort
                           tcpFlags:tcpFlags
                       tcpFlagsMask:tcpFlagsMask
                           icmpType:0
                           icmpCode:0
                          keepState:keepState
                              quick:quick];
}

- (int)addTCPOrUDPRuleAtInterface: (NSString *)interface
                               op: (IJTFirewallOperator)op
                              dir: (IJTFirewallDirection)dir
                            proto: (IJTFirewallProtocol)proto
                           family: (sa_family_t)family
                          srcAddr: (NSString *)srcAddr
                          dstAddr: (NSString *)dstAddr
                          srcMask: (NSString *)srcMask
                          dstMask: (NSString *)dstMask
                          srcPort: (u_int16_t)srcPort
                     dstStartPort: (u_int16_t)dstStartPort
                       dstEndPort: (u_int16_t)dstEndPort
                         tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                     tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                        keepState: (BOOL)keepState
                            quick: (BOOL)quick {
    if(proto != IJTFirewallProtocolTCP && proto != IJTFirewallProtocolUDP) {
        self.errorCode = EINVAL;
        self.errorHappened = YES;
        return -1;
    }
    return [self addRuleAtInterface:interface
                                 op:op
                                dir:dir
                              proto:proto
                             family:family
                            srcAddr:srcAddr
                            dstAddr:dstAddr
                            srcMask:srcMask
                            dstMask:dstMask
                       srcStartPort:srcPort
                         srcEndPort:srcPort
                       dstStartPort:dstStartPort
                         dstEndPort:dstEndPort
                           tcpFlags:tcpFlags
                       tcpFlagsMask:tcpFlagsMask
                           icmpType:0
                           icmpCode:0
                          keepState:keepState
                              quick:quick];
}


- (int)addICMPRuleAtInterface: (NSString *)interface
                           op: (IJTFirewallOperator)op
                          dir: (IJTFirewallDirection)dir
                      srcAddr: (NSString *)srcAddr
                      dstAddr: (NSString *)dstAddr
                      srcMask: (NSString *)srcMask
                      dstMask: (NSString *)dstMask
                     icmpType: (u_int8_t)icmpType
                     icmpCode: (u_int8_t)icmpCode
                    keepState: (BOOL)keepState
                        quick: (BOOL)quick {
    
    return [self addRuleAtInterface:interface
                                 op:op
                                dir:dir
                              proto:IJTFirewallProtocolICMP
                             family:AF_INET
                            srcAddr:srcAddr
                            dstAddr:dstAddr
                            srcMask:srcMask
                            dstMask:dstMask
                       srcStartPort:0
                         srcEndPort:0
                       dstStartPort:0
                         dstEndPort:0
                           tcpFlags:0
                       tcpFlagsMask:0
                           icmpType:icmpType
                           icmpCode:icmpCode
                          keepState:keepState
                              quick:quick];
}


- (int)addRuleAtInterface: (NSString *)interface
                       op: (IJTFirewallOperator)op
                      dir: (IJTFirewallDirection)dir
                   family: (sa_family_t)family
                  srcAddr: (NSString *)srcAddr
                  dstAddr: (NSString *)dstAddr
                  srcMask: (NSString *)srcMask
                  dstMask: (NSString *)dstMask
                keepState: (BOOL)keepState
                    quick: (BOOL)quick {
    return [self addRuleAtInterface:interface
                                 op:op
                                dir:dir
                              proto:IJTFirewallProtocolIP
                             family:family
                            srcAddr:srcAddr
                            dstAddr:dstAddr
                            srcMask:srcMask
                            dstMask:dstMask
                       srcStartPort:0
                         srcEndPort:0
                       dstStartPort:0
                         dstEndPort:0
                           tcpFlags:0
                       tcpFlagsMask:0
                           icmpType:0
                           icmpCode:0
                          keepState:keepState
                              quick:quick];
}

#pragma mark other
- (int)blockAtInterface: (NSString *)interface
                 family: (sa_family_t)family
              keepState: (BOOL)keepState
                  quick: (BOOL)quick {
    return [self addRuleAtInterface:interface
                                 op:IJTFirewallOperatorBlock
                                dir:IJTFirewallDirectionInAndOut
                             family:family
                            srcAddr:@"0.0.0.0"
                            dstAddr:@"0.0.0.0"
                            srcMask:@"0.0.0.0"
                            dstMask:@"0.0.0.0"
                          keepState:keepState
                              quick:quick];
}


- (int)allowAtInterface: (NSString *)interface
                 family: (sa_family_t)family
              keepState: (BOOL)keepState
                  quick: (BOOL)quick {
    return [self addRuleAtInterface:interface
                                 op:IJTFirewallOperatorAllow
                                dir:IJTFirewallDirectionInAndOut
                             family:family
                            srcAddr:@"0.0.0.0"
                            dstAddr:@"0.0.0.0"
                            srcMask:@"0.0.0.0"
                            dstMask:@"0.0.0.0"
                          keepState:keepState
                              quick:quick];
}

- (int)blockAtInterface: (NSString *)interface
                 family: (sa_family_t)family
              ipAddress: (NSString *)ipAddress
                  quick: (BOOL)quick {
    int errnumber = 0;
    [self addRuleAtInterface:interface
                          op:IJTFirewallOperatorBlock
                         dir:IJTFirewallDirectionInAndOut
                       proto:IJTFirewallProtocolIP
                      family:family
                     srcAddr:ipAddress
                     dstAddr:@"0.0.0.0"
                     srcMask:@"255.255.255.255"
                     dstMask:@"0.0.0.0"
                srcStartPort:0
                  srcEndPort:0
                dstStartPort:0
                  dstEndPort:0
                    tcpFlags:0
                tcpFlagsMask:0
                    icmpType:0
                    icmpCode:0
                   keepState:NO
                       quick:quick];
    if(self.errorHappened)
        errnumber = self.errorCode;
    
    [self addRuleAtInterface:interface
                          op:IJTFirewallOperatorBlock
                         dir:IJTFirewallDirectionInAndOut
                       proto:IJTFirewallProtocolIP
                      family:family
                     srcAddr:@"0.0.0.0"
                     dstAddr:ipAddress
                     srcMask:@"0.0.0.0"
                     dstMask:@"255.255.255.255"
                srcStartPort:0
                  srcEndPort:0
                dstStartPort:0
                  dstEndPort:0
                    tcpFlags:0
                tcpFlagsMask:0
                    icmpType:0
                    icmpCode:0
                   keepState:NO
                       quick:quick];
    
    //one method error happened
    if(self.errorHappened)
        return -1;
    if(errnumber != 0) {
        self.errorCode = errnumber;
        self.errorHappened = YES;
        return -1;
    }
    
    return 0;
}

- (int)allowAtInterface: (NSString *)interface
                 family: (sa_family_t)family
              ipAddress: (NSString *)ipAddress
                  quick: (BOOL)quick {
    int errnumber = 0;
    [self deleteRuleAtInterface:interface
                             op:IJTFirewallOperatorBlock
                            dir:IJTFirewallDirectionInAndOut
                          proto:IJTFirewallProtocolIP
                         family:family
                        srcAddr:ipAddress
                        dstAddr:@"0.0.0.0"
                        srcMask:@"255.255.255.255"
                        dstMask:@"0.0.0.0"
                   srcStartPort:0
                     srcEndPort:0
                   dstStartPort:0
                     dstEndPort:0
                       tcpFlags:0
                   tcpFlagsMask:0
                       icmpType:0
                       icmpCode:0
                      keepState:NO
                          quick:quick];
    if(self.errorHappened)
        errnumber = self.errorCode;
    
    [self deleteRuleAtInterface:interface
                             op:IJTFirewallOperatorBlock
                            dir:IJTFirewallDirectionInAndOut
                          proto:IJTFirewallProtocolIP
                         family:family
                        srcAddr:@"0.0.0.0"
                        dstAddr:ipAddress
                        srcMask:@"0.0.0.0"
                        dstMask:@"255.255.255.255"
                   srcStartPort:0
                     srcEndPort:0
                   dstStartPort:0
                     dstEndPort:0
                       tcpFlags:0
                   tcpFlagsMask:0
                       icmpType:0
                       icmpCode:0
                      keepState:NO
                          quick:quick];
    
    //one method error happened
    if(self.errorHappened)
        return -1;
    if(errnumber != 0) {
        self.errorCode = errnumber;
        self.errorHappened = YES;
        return -1;
    }
    return 0;
}
- (int)queryCommand: (NSString *)command {

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    int d = system([command UTF8String]);
#pragma GCC diagnostic pop
    
    if(d < 0)
        goto BAD;
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    self.errorHappened = YES;
    return -1;
}

- (int)generateRuleFile {
    //get stdout, skip stderr
    return
    [self queryCommand:@"/sbin/pfctl -sr 2> /dev/null > /var/root/Injector/pf.conf"];
}

- (int)readFromFile {
    //skip stdout, stderr
    [self queryCommand:@"/sbin/pfctl -F all > /dev/null 2>&1"];
    return
    [self queryCommand:@"/sbin/pfctl -f /var/root/Injector/pf.conf > /dev/null 2>&1"];
}

- (int)enableFirewall {
    return [self queryCommand:@"/sbin/pfctl -e > /dev/null 2>&1"];
}

- (int)disableFirewall {
    return [self queryCommand:@"/sbin/pfctl -d > /dev/null 2>&1"];
}

- (int)clearFirewall {
    return [self queryCommand:@"/sbin/pfctl -F all > /dev/null 2>&1"];
}

- (int)tailRuleByExpression: (NSString *)rule {
    FILE *fp = NULL;
    [self generateRuleFile];
    if(self.errorHappened)
        goto BAD;
    
    fp = fopen("/var/root/Injector/pf.conf", "a+");
    if(!fp)
        goto BAD;
    fprintf(fp, "%s\n", [rule UTF8String]);
    fclose(fp);
    
    [self readFromFile];
    if(self.errorHappened)
        goto BAD;
    
    //clear duplicate
    [self generateRuleFile];
    if(self.errorHappened)
        goto BAD;
    
    self.errorHappened = NO;
    return 0;
BAD:
    self.errorCode = errno;
    if(fp)
        fclose(fp);
    self.errorHappened = YES;
    return -1;
}
@end
