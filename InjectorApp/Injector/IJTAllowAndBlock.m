//
//  IJTAllowAndBlock.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTAllowAndBlock.h"
#import "IJTJson.h"
#import "IJTFirewall.h"
#import "IJTShowMessage.h"
#import "IJTNetowrkStatus.h"
#import <kvnprogress.h>
#import "IJTDispatch.h"
#import "IJTBaseViewController.h"

@implementation IJTAllowAndBlock

+ (NSString *)applicationDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

+ (NSString *)allowFilename {
    NSString *filename = nil;
    if(getegid()) {
        filename = [NSString stringWithFormat:@"%@/WhiteList",
                    [IJTAllowAndBlock applicationDocumentsDirectory]];
    }
    else {
        filename = @"/var/root/Injector/WhiteList";
    }
    NSLog(@"Allow: %@", filename);
    return filename;
}

+ (NSString *)blockFilename {
    NSString *filename = nil;
    if(getegid()) {
        filename = [NSString stringWithFormat:@"%@/BlackList",
                    [IJTAllowAndBlock applicationDocumentsDirectory]];
    }
    else {
        filename = @"/var/root/Injector/BlackList";
    }
    NSLog(@"Block: %@", filename);
    return filename;
}

+ (NSString *)firewallFilename {
    NSString *filename = nil;
    if(getegid()) {
        filename = [NSString stringWithFormat:@"%@/FirewallList",
                    [IJTAllowAndBlock applicationDocumentsDirectory]];
    }
    else {
        filename = @"/var/root/Injector/FirewallList";
    }
    NSLog(@"Firewall: %@", filename);
    return filename;
}

+ (NSArray *)allowList {
    NSMutableArray *allowList = [NSMutableArray arrayWithContentsOfFile:[IJTAllowAndBlock allowFilename]];
    
    if(allowList == nil) {
        allowList = [[NSMutableArray alloc] init];
        [allowList writeToFile:[IJTAllowAndBlock allowFilename] atomically:YES];
    }
    
    //sort by add time, aes
    for(int i = 0 ; i < allowList.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSDictionary *dict1 = allowList[i];
            NSDictionary *dict2 = allowList[j];
            NSString *time1 = [dict1 valueForKey:@"AddTime"];
            NSString *time2 = [dict2 valueForKey:@"AddTime"];
            
            if([time1 longLongValue] > [time2 longLongValue]) {
                [allowList exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }
    return allowList;
}

+ (NSArray *)blockList {
    NSMutableArray *blockList = [NSMutableArray arrayWithContentsOfFile:[IJTAllowAndBlock blockFilename]];
    
    if(blockList == nil) {
        blockList = [[NSMutableArray alloc] init];
        [blockList writeToFile:[IJTAllowAndBlock blockFilename] atomically:YES];
    }
    
    //sort by add time, aes
    for(int i = 0 ; i < blockList.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSDictionary *dict1 = blockList[i];
            NSDictionary *dict2 = blockList[j];
            NSString *time1 = [dict1 valueForKey:@"AddTime"];
            NSString *time2 = [dict2 valueForKey:@"AddTime"];
            
            if([time1 longLongValue] > [time2 longLongValue]) {
                [blockList exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }
    return blockList;
}

+ (NSDictionary *)firewallList {
    NSMutableDictionary *ruleList = [NSMutableDictionary dictionaryWithContentsOfFile:[IJTAllowAndBlock firewallFilename]];
    
    if(ruleList == nil) {
        ruleList = [[NSMutableDictionary alloc] init];
        [ruleList setValue:[[NSMutableArray alloc] init] forKey:@"IP"];
        [ruleList setValue:[[NSMutableArray alloc] init] forKey:@"TCP"];
        [ruleList setValue:[[NSMutableArray alloc] init] forKey:@"UDP"];
        [ruleList setValue:[[NSMutableArray alloc] init] forKey:@"ICMP"];
        [ruleList setValue:[[NSMutableArray alloc] init] forKey:@"Block"];
        
        [ruleList writeToFile:[IJTAllowAndBlock firewallFilename] atomically:YES];
    }
    return ruleList;
}

+ (BOOL)exsitInAllow: (NSString *)ipAddress {
    NSArray *allowList = [IJTAllowAndBlock allowList];
    BOOL found = NO;
    for(NSDictionary *dict in allowList) {
        NSString *ipAddress2 = [dict valueForKey:@"IpAddress"];
        if([ipAddress2 isEqualToString:ipAddress]) {
            found = YES;
            break;
        }
    }
    return found;
}

+ (BOOL)exsitInBlock: (NSString *)ipAddress {
    NSArray *allowList = [IJTAllowAndBlock blockList];
    BOOL found = NO;
    for(NSDictionary *dict in allowList) {
        NSString *ipAddress2 = [dict valueForKey:@"IpAddress"];
        if([ipAddress2 isEqualToString:ipAddress]) {
            found = YES;
            break;
        }
    }
    return found;
}

+ (BOOL)newAllow: (NSString *)ipAddress time: (time_t)time displayName: (NSString *)displayName enable:(BOOL)enable {
    BOOL found = [IJTAllowAndBlock exsitInAllow:ipAddress];
    if(found)
        return YES;
    
    NSMutableArray *allowList = [NSMutableArray arrayWithArray:[IJTAllowAndBlock allowList]];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:ipAddress forKey:@"IpAddress"];
    [dict setObject:[NSNumber numberWithLong:time] forKey:@"AddTime"];
    [dict setObject:displayName forKey:@"DisplayName"];
    [dict setObject:@(enable) forKey:@"Enable"];
    [allowList addObject:dict];
    [allowList writeToFile:[IJTAllowAndBlock allowFilename] atomically:YES];
    
    return YES;
}

+ (BOOL)newBlock: (NSString *)ipAddress time: (time_t)time displayName: (NSString *)displayName enable:(BOOL)enable target: (id)target {
    BOOL found = [IJTAllowAndBlock exsitInBlock:ipAddress];
    if(found)
        return YES;
    
    if(enable && !getegid()) {
        IJTFirewall *fw = [[IJTFirewall alloc] init];
        if(fw.errorHappened) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
            }];
            
            [fw close];
            fw = nil;
            return NO;
        }
        
        if([IJTNetowrkStatus supportWifi]) {
            [fw blockAtInterface:@"en0"
                          family:AF_INET
                       ipAddress:ipAddress quick:YES];
        }
        
        BOOL wifi = fw.errorHappened;
        int codewifi = fw.errorCode;
        if([IJTNetowrkStatus supportCellular]) {
            [fw blockAtInterface:@"pdp_ip0"
                          family:AF_INET
                       ipAddress:ipAddress quick:YES];
        }
        BOOL cell = fw.errorHappened;
        int codecell = fw.errorCode;
        
        [fw close];
        fw = nil;
        if(wifi && codewifi != EEXIST) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"Wi-Fi : %s.", strerror(codewifi)]];
            }];
            return NO;
        }
        if(cell && codecell != EEXIST) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"Cellular : %s.", strerror(codecell)]];
            }];
            return NO;
        }
    }//end if enable
    
    NSMutableArray *blockList = [NSMutableArray arrayWithArray:[IJTAllowAndBlock blockList]];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:ipAddress forKey:@"IpAddress"];
    [dict setObject:[NSNumber numberWithLong:time] forKey:@"AddTime"];
    [dict setObject:displayName forKey:@"DisplayName"];
    [dict setObject:@(enable) forKey:@"Enable"];
    [blockList addObject:dict];
    [blockList writeToFile:[IJTAllowAndBlock blockFilename] atomically:YES];
    return YES;
}

+ (BOOL)removeAllowIpAddress: (NSString *)ipAddress {
    NSMutableArray *allowList = [NSMutableArray arrayWithArray:[IJTAllowAndBlock allowList]];
    
    NSDictionary *needRemoved = nil;
    BOOL found = NO;
    for(NSDictionary *dict in allowList) {
        NSString *ipAddress2 = [dict valueForKey:@"IpAddress"];
        if([ipAddress2 isEqualToString:ipAddress]) {
            needRemoved = dict;
            found = YES;
            break;
        }
    }
    if(found) {
        [allowList removeObject:needRemoved];
        [allowList writeToFile:[IJTAllowAndBlock allowFilename] atomically:YES];
    }
    return found;
}

+ (BOOL)removeBlockIpAddress: (NSString *)ipAddress target: (id)target {
    NSMutableArray *blockList = [NSMutableArray arrayWithArray:[IJTAllowAndBlock blockList]];
    
    NSDictionary *needRemoved = nil;
    BOOL found = NO;
    for(NSDictionary *dict in blockList) {
        NSString *ipAddress2 = [dict valueForKey:@"IpAddress"];
        if([ipAddress2 isEqualToString:ipAddress]) {
            needRemoved = dict;
            found = YES;
            break;
        }
    }
    if(found && !getegid()) {
        IJTFirewall *fw = [[IJTFirewall alloc] init];
        if(fw.errorHappened) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
            }];
            
            [fw close];
            fw = nil;
            return NO;
        }
        
        if([IJTNetowrkStatus supportWifi]) {
            [fw allowAtInterface:@"en0"
                          family:AF_INET
                       ipAddress:ipAddress quick:YES];
        }
        
        BOOL wifi = fw.errorHappened;
        int codewifi = fw.errorCode;
        if([IJTNetowrkStatus supportCellular]) {
            [fw allowAtInterface:@"pdp_ip0"
                          family:AF_INET
                       ipAddress:ipAddress quick:YES];
        }
        BOOL cell = fw.errorHappened;
        int codecell = fw.errorCode;
        
        [fw close];
        fw = nil;
        if(wifi && codewifi != ENOENT) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"Wi-Fi : %s.", strerror(codewifi)]];
            }];
            return NO;
        }
        if(cell && codecell != ENOENT) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"Cellular : %s.", strerror(codecell)]];
            }];
            return NO;
        }
    }
    if(found) {
        [blockList removeObject:needRemoved];
        [blockList writeToFile:[IJTAllowAndBlock blockFilename] atomically:YES];
    }
    
    return found;
}

+ (NSArray *)createAllowWithJson: (NSString *)json {
    NSArray *allowList = [IJTJson json2array:json];
    if(allowList == nil) {
        allowList = [[NSArray alloc] init];
    }
    [allowList writeToFile:[IJTAllowAndBlock allowFilename] atomically:YES];
    return allowList;
}


+ (NSArray *)createBlockWithJson: (NSString *)json {
    NSArray *blockList = [IJTJson json2array:json];
    if(blockList == nil) {
        blockList = [[NSArray alloc] init];
    }
    [blockList writeToFile:[IJTAllowAndBlock blockFilename] atomically:YES];
    return blockList;
}

+ (BOOL)allowMoveToBlock: (NSString *)ipAddress target: (id)target {
    NSMutableArray *allowList = [NSMutableArray arrayWithArray:[IJTAllowAndBlock allowList]];
    
    NSString *displayName = @"Injector";
    NSNumber *enable = @(YES);
    time_t addTime = time(NULL);
    for(NSDictionary *dict in allowList) {
        NSString *ipAddress2 = [dict valueForKey:@"IpAddress"];
        if([ipAddress2 isEqualToString:ipAddress]) {
            displayName = [dict valueForKey:@"DisplayName"];
            enable = [dict valueForKey:@"Enable"];
            addTime = [(NSNumber *)[dict valueForKey:@"AddTime"] longValue];
            break;
        }
    }
    
    [IJTAllowAndBlock removeAllowIpAddress:ipAddress];
    [IJTAllowAndBlock newBlock:ipAddress time:addTime displayName:displayName enable:[enable boolValue] target:target];
    return YES;
}

+ (BOOL)blockMoveToAllow: (NSString *)ipAddress target: (id)target {
    NSMutableArray *blockList = [NSMutableArray arrayWithArray:[IJTAllowAndBlock blockList]];
    
    NSString *displayName = @"Injector";
    NSNumber *enable = @(YES);
    time_t addTime = time(NULL);
    for(NSDictionary *dict in blockList) {
        NSString *ipAddress2 = [dict valueForKey:@"IpAddress"];
        if([ipAddress2 isEqualToString:ipAddress]) {
            displayName = [dict valueForKey:@"DisplayName"];
            enable = [dict valueForKey:@"Enable"];
            addTime = [(NSNumber *)[dict valueForKey:@"AddTime"] longValue];
            break;
        }
    }
    
    [IJTAllowAndBlock removeBlockIpAddress:ipAddress target:target];
    [IJTAllowAndBlock newAllow:ipAddress time:addTime displayName:displayName enable:[enable boolValue]];
    return YES;
}

+ (BOOL)restoreAllowList: (NSArray *)allowList target: (id)target {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for(NSDictionary *dict in allowList) {
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        if(![IJTAllowAndBlock exsitInBlock:ipAddress]) {
            [array addObject:dict];
        }
    }//end for
    [array writeToFile:[IJTAllowAndBlock allowFilename] atomically:YES];
    return YES;
}

+ (BOOL)restoreBlockList: (NSArray *)blockList target: (id)target {
    IJTFirewall *fw = nil;
    
    if(!getegid()) { //reload to firewall
        fw = [[IJTFirewall alloc] init];
        if(fw.errorHappened) {
            [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
            [fw close];
            fw = nil;
            return NO;
        }
    }
    
    BOOL wifi = [IJTNetowrkStatus supportWifi];
    BOOL cell = [IJTNetowrkStatus supportCellular];
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for(NSDictionary *dict in blockList) {
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        if(![IJTAllowAndBlock exsitInAllow:ipAddress]) {
            [array addObject:dict];
            
            if(!getegid()) {
                NSNumber *enable = [dict valueForKey:@"Enable"];
                if([enable boolValue] == YES) {
                    if(wifi) {
                        [fw blockAtInterface:@"en0"
                                      family:AF_INET
                                   ipAddress:ipAddress
                                       quick:YES];
                    }
                    if(cell) {
                        [fw blockAtInterface:@"pdp_ip0"
                                      family:AF_INET
                                   ipAddress:ipAddress
                                       quick:YES];
                    }
                }//end if enable
            }//end if is root
        }//end if not exsit in allow
    }//end for each ip address
    
    
    [array writeToFile:[IJTAllowAndBlock blockFilename] atomically:YES];
    return YES;
}

+ (BOOL)setEnableAllow: (BOOL)enable ipAddress: (NSString *)ipAddress{
    NSMutableArray *allowList = [NSMutableArray arrayWithArray:[IJTAllowAndBlock allowList]];
    
    NSDictionary *needChanged = nil;
    BOOL found = NO;
    for(NSDictionary *dict in allowList) {
        NSString *ipAddress2 = [dict valueForKey:@"IpAddress"];
        if([ipAddress2 isEqualToString:ipAddress]) {
            needChanged = dict;
            found = YES;
            break;
        }
    }
    if(found) {
        [needChanged setValue:@(enable) forKey:@"Enable"];
        [allowList writeToFile:[IJTAllowAndBlock allowFilename] atomically:YES];
    }
    
    return YES;
}

+ (BOOL)setEnableBlock: (BOOL)enable ipAddress: (NSString *)ipAddress target: (id)target {
    NSMutableArray *blockList = [NSMutableArray arrayWithArray:[IJTAllowAndBlock blockList]];
    
    NSDictionary *needChanged = nil;
    BOOL found = NO;
    for(NSDictionary *dict in blockList) {
        NSString *ipAddress2 = [dict valueForKey:@"IpAddress"];
        if([ipAddress2 isEqualToString:ipAddress]) {
            needChanged = dict;
            found = YES;
            break;
        }
    }
    if(found) {
        if(enable && !getegid()) {
            IJTFirewall *fw = [[IJTFirewall alloc] init];
            if(fw.errorHappened) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
                }];
                
                [fw close];
                fw = nil;
                return NO;
            }
            
            if([IJTNetowrkStatus supportWifi]) {
                [fw blockAtInterface:@"en0"
                              family:AF_INET
                           ipAddress:ipAddress quick:YES];
            }
            
            BOOL wifi = fw.errorHappened;
            int codewifi = fw.errorCode;
            if([IJTNetowrkStatus supportCellular]) {
                [fw blockAtInterface:@"pdp_ip0"
                              family:AF_INET
                           ipAddress:ipAddress quick:YES];
            }
            BOOL cell = fw.errorHappened;
            int codecell = fw.errorCode;
            
            [fw close];
            fw = nil;
            if(wifi && codewifi != ENOENT) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"Wi-Fi : %s.", strerror(codewifi)]];
                }];
                return NO;
            }
            if(cell && codecell != ENOENT) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"Cellular : %s.", strerror(codecell)]];
                }];
                return NO;
            }
        }//end if is root
        else if(!enable && !getegid()) {
            IJTFirewall *fw = [[IJTFirewall alloc] init];
            if(fw.errorHappened) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
                }];
                
                [fw close];
                fw = nil;
                return NO;
            }
            
            if([IJTNetowrkStatus supportWifi]) {
                [fw allowAtInterface:@"en0"
                              family:AF_INET
                           ipAddress:ipAddress quick:YES];
            }
            
            BOOL wifi = fw.errorHappened;
            int codewifi = fw.errorCode;
            if([IJTNetowrkStatus supportCellular]) {
                [fw allowAtInterface:@"pdp_ip0"
                              family:AF_INET
                           ipAddress:ipAddress quick:YES];
            }
            BOOL cell = fw.errorHappened;
            int codecell = fw.errorCode;
            
            [fw close];
            fw = nil;
            if(wifi && codewifi != ENOENT) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"Wi-Fi : %s.", strerror(codewifi)]];
                }];
                return NO;
            }
            if(cell && codecell != ENOENT) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"Cellular : %s.", strerror(codecell)]];
                }];
                return NO;
            }
        }
        
        [needChanged setValue:@(enable) forKey:@"Enable"];
        [blockList writeToFile:[IJTAllowAndBlock blockFilename] atomically:YES];
    }
    return YES;
}

+ (NSString *)ipAddressWithSlash: (NSString *)ipAddress slash: (NSString **)netmask {
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

+ (BOOL)restoreFirewallList: (NSDictionary *)firewallList target: (id)target {
    [firewallList writeToFile:[self firewallFilename] atomically:YES];
    if(getegid())
        return YES;
    IJTFirewall *fw = [[IJTFirewall alloc] init];
    if(fw.errorHappened) {
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [(IJTBaseViewController *)target showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
        }];
        return NO;
    }
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
            sourceAddr = [self ipAddressWithSlash:sourceAddr slash:&sourceMask];
            NSString *destinationAddr = [dict valueForKey:@"Destination"];
            NSString *destiantionMask = nil;
            destinationAddr = [self ipAddressWithSlash:destinationAddr slash:&destiantionMask];
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
    
    [fw close];
    fw = nil;
    return YES;
}


@end
