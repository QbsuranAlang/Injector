//
//  IJTFirewallRuleTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTFirewallRuleTableViewController.h"
#import "IJTLastBackupTableViewCell.h"
#import "IJTIPRuleTableViewCell.h"
#import "IJTTCPRuleTableViewCell.h"
#import "IJTUDPRuleTableViewCell.h"
#import "IJTICMPRuleTableViewCell.h"

@interface IJTFirewallRuleTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *dict;

@end

@implementation IJTFirewallRuleTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"down.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.dict = [[NSMutableDictionary alloc] init];
    [self.dict setValue:[IJTFormatString formatTime:self.lastTime] forKey:@"Time"];
    NSArray *ipArray = [self.ruleList valueForKey:@"IP"];
    NSArray *tcpArray = [self.ruleList valueForKey:@"TCP"];
    NSArray *udpArray = [self.ruleList valueForKey:@"UDP"];
    NSArray *icmpArray = [self.ruleList valueForKey:@"ICMP"];
    [self.dict setValue:@(ipArray.count+tcpArray.count+udpArray.count+icmpArray.count) forKey:@"Count"];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *array = nil;
    switch (section) {
        case 0:
            return @"Backup Information";
        case 1:
            array = [self.ruleList valueForKey:@"IP"];
            return [NSString stringWithFormat:@"IPv4(%lu)", (unsigned long)array.count];
            
        case 2:
            array = [self.ruleList valueForKey:@"TCP"];
            return [NSString stringWithFormat:@"TCP(%lu)", (unsigned long)array.count];
            
        case 3:
            array = [self.ruleList valueForKey:@"UDP"];
            return [NSString stringWithFormat:@"UDP(%lu)", (unsigned long)array.count];
            
        case 4:
            array = [self.ruleList valueForKey:@"ICMP"];
            return [NSString stringWithFormat:@"ICMP(%lu)", (unsigned long)array.count];
    }
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSArray *ipArray = [self.ruleList valueForKey:@"IP"];
    NSArray *tcpArray = [self.ruleList valueForKey:@"TCP"];
    NSArray *udpArray = [self.ruleList valueForKey:@"UDP"];
    NSArray *icmpArray = [self.ruleList valueForKey:@"ICMP"];
    
    switch (section) {
        case 0: return 1;
        case 1: return ipArray.count;
        case 2: return tcpArray.count;
        case 3: return udpArray.count;
        case 4: return icmpArray.count;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    
    __block NSInteger section = indexPath.section;
    [alert addButton:@"Yes" actionBlock:^{
        NSString *key = @"";
        if(section == 0) {
            key = @"IP";
        }
        else if(section == 1) {
            key = @"TCP";
        }
        else if(section == 2) {
            key = @"UDP";
        }
        else if(section == 3) {
            key = @"ICMP";
        }
        else {
            return;
        }
        
        NSArray *array = [_ruleList valueForKey:key];
        if(array == nil)
            return;
        NSDictionary *dict = array[indexPath.row];
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
        
        if(getegid()) {
            return;
        }
        IJTFirewall *fw = [[IJTFirewall alloc] init];
        if(fw.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
            return;
        }
        if(section == 0) {
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
        }//end if ip
        else if(section == 1 || section == 2) {
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
        }// if tcp or udp
        else if(section == 3) {
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
        }//end if icmp
        
        if(fw.errorHappened) {
            if(fw.errorCode == EEXIST) {
                [self showErrorMessage:@"The rule is exsit."];
            }
            else {
                [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
            }
        }//end if
        else {
            [self showSuccessMessage:@"Success"];
        }
        
        [fw close];
        fw = nil;
        [self.delegate callback];
        
    }];
    
    [alert showInfo:@"Restore one"
           subTitle:[NSString stringWithFormat:@"Do you want store it?"]
   closeButtonTitle:@"No"
           duration:0];
}

- (NSString *)ipAddressWithSlash: (NSString *)ipAddress slash: (NSString **)netmask {
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        IJTLastBackupTableViewCell *cell = (IJTLastBackupTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"BackupCell" forIndexPath:indexPath];
        [IJTFormatUILabel dict:self.dict
                           key:@"Time"
                         label:cell.timeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:self.dict
                           key:@"Count"
                         label:cell.itemsLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTIPRuleTableViewCell *cell = (IJTIPRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"IPRuleCell" forIndexPath:indexPath];
        
        NSArray *array = [self.ruleList valueForKey:@"IP"];
        
#define BASE_IP_RULE(cell) \
NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[array objectAtIndex:indexPath.row]]; \
[IJTFormatUILabel dict:dict \
key:@"Operator" \
label:cell.actionLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]]; \
[IJTFormatUILabel dict:dict \
key:@"Quick" \
label:cell.quickLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]]; \
[IJTFormatUILabel dict:dict \
key:@"Direction" \
label:cell.directionLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]]; \
[IJTFormatUILabel dict:dict \
key:@"Family" \
label:cell.internetLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]]; \
[IJTFormatUILabel dict:dict \
key:@"Interface" \
label:cell.interfaceLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]]; \
[IJTFormatUILabel dict:dict \
key:@"Keep State" \
label:cell.keepStateLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]]; \
[IJTFormatUILabel dict:dict \
key:@"Source" \
label:cell.sourceLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]]; \
[IJTFormatUILabel dict:dict \
key:@"Destination" \
label:cell.destinationLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]];
        
        BASE_IP_RULE(cell);
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 2) {
        IJTTCPRuleTableViewCell *cell = (IJTTCPRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TCPRuleCell" forIndexPath:indexPath];
        
        NSArray *array = [self.ruleList valueForKey:@"TCP"];
        
        BASE_IP_RULE(cell);
        
#define BASE_PORT(cell) \
NSNumber *srcStartPort = [dict valueForKey:@"Src Start Port"]; \
NSNumber *srcEndPort = [dict valueForKey:@"Src End Port"]; \
NSNumber *dstStartPort = [dict valueForKey:@"Dst Start Port"]; \
NSNumber *dstEndPort = [dict valueForKey:@"Dst End Port"]; \
NSString *srcPortString = @""; \
NSString *dstPortString = @""; \
if([srcStartPort integerValue] == 0 && [srcEndPort integerValue] == 0) { \
srcPortString = @"Any"; \
} \
else if([srcStartPort integerValue] == [srcEndPort integerValue]) { \
srcPortString = [NSString stringWithFormat:@"%ld", (long)[srcStartPort integerValue]]; \
} \
else { \
srcPortString = [NSString stringWithFormat:@"%ld-%ld", (long)[srcStartPort integerValue], (long)[srcEndPort integerValue]]; \
} \
[dict setValue:srcPortString forKey:@"Src String"]; \
if([dstStartPort integerValue] == 0 && [dstEndPort integerValue] == 0) { \
dstPortString = @"Any"; \
} \
else if([dstStartPort integerValue] == [dstEndPort integerValue]) { \
dstPortString = [NSString stringWithFormat:@"%ld", (long)[dstStartPort integerValue]]; \
} \
else { \
dstPortString = [NSString stringWithFormat:@"%ld-%ld", (long)[dstStartPort integerValue], (long)[dstEndPort integerValue]]; \
} \
[dict setValue:dstPortString forKey:@"Dst String"]; \
[IJTFormatUILabel dict:dict \
key:@"Src String" \
label:cell.srcPortLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]]; \
[IJTFormatUILabel dict:dict \
key:@"Dst String" \
label:cell.dstPortLabel \
color:IJTValueColor \
font:[UIFont systemFontOfSize:11]]
        
        BASE_PORT(cell);
        
        NSNumber *tcpflags = [dict valueForKey:@"TCP Flags"];
        NSNumber *tcpflagsmask = [dict valueForKey:@"TCP Flags Mask"];
        NSString *tcpflagsString = [NSString stringWithFormat:@"%@/%@",
                                    [IJTFirewall tcpFlags2String:[tcpflags integerValue]],
                                    [IJTFirewall tcpFlags2String:[tcpflagsmask integerValue]]];
        
        [dict setValue:tcpflagsString forKey:@"TCP Flags String"];
        
        [IJTFormatUILabel dict:dict
                           key:@"TCP Flags String"
                         label:cell.tcpFlagsLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 3) {
        IJTUDPRuleTableViewCell *cell = (IJTUDPRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"UDPRuleCell" forIndexPath:indexPath];
        NSArray *array = [self.ruleList valueForKey:@"UDP"];
        
        BASE_IP_RULE(cell);
        BASE_PORT(cell);
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 4) {
        IJTICMPRuleTableViewCell *cell = (IJTICMPRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ICMPRuleCell" forIndexPath:indexPath];
        NSArray *array = [self.ruleList valueForKey:@"ICMP"];
        
        BASE_IP_RULE(cell);
        
        [IJTFormatUILabel dict:dict
                           key:@"ICMP Type"
                         label:cell.typeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"ICMP Code"
                         label:cell.codeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

@end
