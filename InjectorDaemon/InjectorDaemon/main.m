//
//  main.m
//  InjectorDaemon
//
//  Created by 聲華 陳 on 2015/4/11.
//  Copyright (c) 2015年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IJTDaemon.h"
#import "IJTDatabase.h"
#import <sys/types.h>
#import <sys/stat.h>
#import <IJTFirewall.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "IJTConnection.h"

#define NOT_DONE 0
#define DONE 1

static BOOL checkInterface(NSString *interface)
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    BOOL support = NO;
    
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr) {
            if(!strcmp(temp_addr->ifa_name, (const char *)[interface UTF8String])) {
                support = YES;
                break;
            }//end if found
            temp_addr = temp_addr->ifa_next;
        }//end while
        freeifaddrs(interfaces);
    }//end if
    return support;
}

static NSString *ipAddressWithSlash(NSString *ipAddress, NSString **netmask) {
    NSArray *array = [ipAddress componentsSeparatedByString:@"/"];
    if(array.count != 2) {
        *netmask = @"255.255.255.255";
        return ipAddress;
    }
    NSInteger slash = [array[1] integerValue];
    u_int32_t netmask_addr = 0;
    for(int i = 0, mask = 1<<31 ; i < slash ; i++, mask>>=1) {
        netmask_addr |= mask;
    }
    netmask_addr = htonl(netmask_addr);
    char ntop_buf[256];
    inet_ntop(AF_INET, &netmask_addr, ntop_buf, sizeof(ntop_buf));
    *netmask = [NSString stringWithUTF8String:ntop_buf];
    return array[0];
}

int main (int argc, const char * argv[])
{
    @autoreleasepool
    {
        NSConditionLock *finishedLock = [[NSConditionLock alloc] initWithCondition: NOT_DONE];
        
        //because when booting, network connection is not available immediately
        if(!(argc >= 2 && !strcmp(argv[1], "skip")))
            sleep(10);
        
        struct stat st = {0};
        //create dir
        if (stat("/var/root/Injector/", &st) == -1) {
            mkdir("/var/root/Injector/", 0755);
        }
        if (stat("/var/root/Injector/PacketFlowTemp", &st) == -1) {
            mkdir("/var/root/Injector/PacketFlowTemp", 0755);
        }
        
        IJTDatabase *database = [[IJTDatabase alloc] init];
        if(!(argc >= 3 && !strcmp(argv[2], "dont"))) {
            [database retrieve];
        }
        IJTFirewall *fw = [[IJTFirewall alloc] init];
        [fw enableFirewall];
        [fw clearFirewall];
        BOOL supportwifi = checkInterface(@"en0");
        BOOL supportcell = checkInterface(@"pdp_ip0");
        
        NSMutableArray *blacklist = [NSMutableArray arrayWithContentsOfFile:@"/var/root/Injector/BlackList"];
        if(blacklist == nil) {
            blacklist = [[NSMutableArray alloc] init];
        }
        for(NSDictionary *dict in blacklist) {
            NSString *ip = [dict valueForKey:@"IpAddress"];
            NSNumber *enable = [dict valueForKey:@"Enable"];
            if([enable boolValue] == NO)
                continue;
            
            if(supportwifi) {
                [fw blockAtInterface:@"en0"
                              family:AF_INET
                           ipAddress:ip quick:YES];
            }
            if(supportcell) {
                [fw blockAtInterface:@"pdp_ip0"
                              family:AF_INET
                           ipAddress:ip quick:YES];
            }
        }
        NSMutableDictionary *firewallList = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/root/Injector/FirewallList"];
        if(firewallList != nil) {
            NSArray *ip = [firewallList valueForKey:@"IP"];
            NSArray *tcp = [firewallList valueForKey:@"TCP"];
            NSArray *udp = [firewallList valueForKey:@"UDP"];
            NSArray *icmp = [firewallList valueForKey:@"ICMP"];
            NSArray *list = @[ip, tcp, udp, icmp];
            
            for(NSArray *array in list) {
                for(NSDictionary *dict in array) {
                    NSString *actionString = [dict valueForKey:@"Operator"];
                    IJTFirewallOperator operation = [actionString isEqualToString:@"Allow"] ? IJTFirewallOperatorAllow : IJTFirewallOperatorBlock;
                    NSString *quickString = [dict valueForKey:@"Quick"];
                    BOOL quick = [quickString isEqualToString:@"Yes"] ? YES : NO;
                    NSString *interface = [dict valueForKey:@"Interface"];
                    NSString *directionString = [dict valueForKey:@"Direction"];
                    IJTFirewallDirection direction = [directionString isEqualToString:@"In"] ? IJTFirewallDirectionIn : ([directionString isEqualToString:@"Out"] ? IJTFirewallDirectionOut : IJTFirewallDirectionInAndOut);
                    NSString *keepStateString = [dict valueForKey:@"Keep State"];
                    BOOL keepState = [keepStateString isEqualToString:@"Yes"] ? YES : NO;
                    NSString *sourceAddr = [dict valueForKey:@"Source"];
                    NSString *sourceMask = nil;
                    sourceAddr = ipAddressWithSlash(sourceAddr, &sourceMask);
                    NSString *destinationAddr = [dict valueForKey:@"Destination"];
                    NSString *destiantionMask = nil;
                    destinationAddr = ipAddressWithSlash(destinationAddr, &destiantionMask);
                    NSInteger protocol = [[dict valueForKey:@"Protocol"] integerValue];
                    NSInteger srcStartPort = [[dict valueForKey:@"Src Start Port"] integerValue];
                    NSInteger srcEndPort = [[dict valueForKey:@"Src End Port"] integerValue];
                    NSInteger dstStartPort = [[dict valueForKey:@"Dst Start Port"] integerValue];
                    NSInteger dstEndPort = [[dict valueForKey:@"Dst End Port"] integerValue];
                    IJTFirewallTCPFlag flags = [[dict valueForKey:@"TCP Flags"] integerValue];
                    IJTFirewallTCPFlag flagsMask = [[dict valueForKey:@"TCP Flags Mask"] integerValue];
                    NSInteger icmpCode = [[dict valueForKey:@"ICMP Code"] integerValue];
                    NSInteger icmpType = [[dict valueForKey:@"ICMP Type"] integerValue];
                    
                    BOOL srcRange = srcStartPort != 0 && srcEndPort != 0 && srcStartPort != srcEndPort ? YES : NO;
                    BOOL dstRange = dstStartPort != 0 && dstEndPort != 0 && dstStartPort != dstEndPort ? YES : NO;
                    
                    if(protocol == IJTFirewallProtocolIP) {
                        [fw addRuleAtInterface:interface
                                            op:operation
                                           dir:direction
                                        family:AF_INET
                                       srcAddr:sourceAddr
                                       dstAddr:destinationAddr
                                       srcMask:sourceMask
                                       dstMask:destiantionMask
                                     keepState:keepState
                                         quick:quick];
                    }
                    else if(protocol == IJTFirewallProtocolTCP || protocol == IJTFirewallProtocolUDP) {
                        if(srcRange && dstRange) {
                            [fw addTCPOrUDPRuleAtInterface:interface
                                                        op:operation
                                                       dir:direction
                                                     proto:protocol
                                                    family:AF_INET
                                                   srcAddr:sourceAddr
                                                   dstAddr:destinationAddr
                                                   srcMask:sourceMask
                                                   dstMask:destiantionMask
                                              srcStartPort:srcStartPort
                                                srcEndPort:srcEndPort
                                              dstStartPort:dstStartPort
                                                dstEndPort:dstEndPort
                                                  tcpFlags:flags
                                              tcpFlagsMask:flagsMask
                                                 keepState:keepState
                                                     quick:quick];
                        }
                        else if(srcRange) {
                            [fw addTCPOrUDPRuleAtInterface:interface
                                                        op:operation
                                                       dir:direction
                                                     proto:protocol
                                                    family:AF_INET
                                                   srcAddr:sourceAddr
                                                   dstAddr:destinationAddr
                                                   srcMask:sourceMask
                                                   dstMask:destiantionMask
                                              srcStartPort:srcStartPort
                                                srcEndPort:srcEndPort
                                                   dstPort:dstStartPort
                                                  tcpFlags:flags
                                              tcpFlagsMask:flagsMask
                                                 keepState:keepState
                                                     quick:quick];
                        }
                        else if(dstRange) {
                            [fw addTCPOrUDPRuleAtInterface:interface
                                                        op:operation
                                                       dir:direction
                                                     proto:protocol
                                                    family:AF_INET
                                                   srcAddr:sourceAddr
                                                   dstAddr:destinationAddr
                                                   srcMask:sourceMask
                                                   dstMask:destiantionMask
                                                   srcPort:srcStartPort
                                              dstStartPort:dstStartPort
                                                dstEndPort:dstEndPort
                                                  tcpFlags:flags
                                              tcpFlagsMask:flagsMask
                                                 keepState:keepState
                                                     quick:quick];
                        }
                        else {
                            [fw addTCPOrUDPRuleAtInterface:interface
                                                        op:operation
                                                       dir:direction
                                                     proto:protocol
                                                    family:AF_INET
                                                   srcAddr:sourceAddr
                                                   dstAddr:destinationAddr
                                                   srcMask:sourceMask
                                                   dstMask:destiantionMask
                                                   srcPort:srcStartPort
                                                   dstPort:dstStartPort
                                                  tcpFlags:flags
                                              tcpFlagsMask:flagsMask
                                                 keepState:keepState
                                                     quick:quick];
                        }//
                    }
                    else if(protocol == IJTFirewallProtocolICMP) {
                        [fw addICMPRuleAtInterface:interface
                                                op:operation
                                               dir:direction
                                           srcAddr:sourceAddr
                                           dstAddr:destinationAddr
                                           srcMask:sourceMask
                                           dstMask:destiantionMask
                                          icmpType:icmpType
                                          icmpCode:icmpCode
                                         keepState:keepState
                                             quick:quick];
                    }
                }//end for
            }//end for
        }
        
        
        [fw close];
        fw = nil;
        
        IJTDaemon *wifi = [[IJTDaemon alloc] initWithInterface:@"en0"];
        IJTDaemon *cell = [[IJTDaemon alloc] initWithInterface:@"pdp_ip0"];
        
        IJTConnection *connection = [[IJTConnection alloc] init];
        [connection addObserver];
        
        [wifi start];
        [cell start];
        
        printf("Start\n");
        while(wifi.ok || cell.ok) {
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop addTimer:database.updateTimer forMode:NSDefaultRunLoopMode];
            [runLoop run];
            database = [[IJTDatabase alloc] init];
            [database retrieve];
        }
        [finishedLock lockWhenCondition:DONE];
    }
    return 0;
}

