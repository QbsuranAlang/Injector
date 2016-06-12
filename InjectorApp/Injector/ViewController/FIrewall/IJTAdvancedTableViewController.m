//
//  IJTAdvancedTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/6/13.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTAdvancedTableViewController.h"
#import "IJTIPRuleTableViewCell.h"
#import "IJTTCPRuleTableViewCell.h"
#import "IJTUDPRuleTableViewCell.h"
#import "IJTICMPRuleTableViewCell.h"
#import "IJTAddFirewallTableViewController.h"
#import "IJTFirewallRuleTableViewController.h"

@interface IJTAdvancedTableViewController ()

@property (nonatomic, strong) NSDictionary *ruleList;

@property (nonatomic, strong) NSString *serialNumber;

@property (nonatomic, strong) CNPGridMenu *gridMenu;

@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *detailButton;

@property (nonatomic, strong) SSARefreshControl *refreshView;
@end

@implementation IJTAdvancedTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"close.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.detailButton =
    [[UIBarButtonItem alloc]
     initWithImage:[UIImage imageNamed:@"other_tool.png"]
     style:UIBarButtonItemStylePlain
     target:self action:@selector(showFunction)];
    
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects:_detailButton, nil];
    
    self.doneButton =
    [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemDone
     target:self action:@selector(doneAction)];
    
    self.serialNumber = [IJTID serialNumber];
    
    CNPGridMenuItem *ruleButton = [[CNPGridMenuItem alloc] init];
    ruleButton.icon = [UIImage imageNamed:@"show_rule.png"];
    ruleButton.title = @"What I Backup";
    
    CNPGridMenuItem *addButton = [[CNPGridMenuItem alloc] init];
    addButton.icon = [UIImage imageNamed:@"add_row.png"];
    addButton.title = @"Add a Rule";
    
    CNPGridMenuItem *deleteButton = [[CNPGridMenuItem alloc] init];
    deleteButton.icon = [UIImage imageNamed:@"trash_big.png"];
    deleteButton.title = @"Delete Rules";
    
    CNPGridMenuItem *backupButton = [[CNPGridMenuItem alloc] init];
    backupButton.icon = [UIImage imageNamed:@"backup.png"];
    backupButton.title = @"Backup All";
    
    CNPGridMenuItem *restoreButton = [[CNPGridMenuItem alloc] init];
    restoreButton.icon = [UIImage imageNamed:@"restore.png"];
    restoreButton.title = @"Restore All";
    
    CNPGridMenuItem *closeButton = [[CNPGridMenuItem alloc] init];
    closeButton.icon = [UIImage imageNamed:@"close_big.png"];
    closeButton.title = @"Close";
    
    self.gridMenu = [[CNPGridMenu alloc] initWithMenuItems:@[addButton, deleteButton, ruleButton, backupButton, restoreButton, closeButton]];
    self.gridMenu.delegate = self;
    
    self.messageLabel.text = @"No Firewall Information";
    
    //refresh control
    self.refreshView = [[SSARefreshControl alloc] initWithScrollView:self.tableView andRefreshViewLayerType:SSARefreshViewLayerTypeOnScrollView];
    self.refreshView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refresh];
}

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)goRuleVC {
    [KVNProgress showWithStatus:@"Retrieving..."];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        
        
        [IJTHTTP retrieveFrom:@"BackupRestoreFirewall.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@&Action=GET&Type=Firewall", self.serialNumber]
                      timeout:5
                        block:^(NSData *data) {
                          time_t lasttime = -1;
                          NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            
                            [IJTDispatch dispatch_main:^{
                                [KVNProgress dismiss];
                            }];
                          
                          NSDictionary *dict = nil;
                          if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                              lasttime = -1;
                          }
                          else {
                              dict = [IJTJson json2dictionary:jsonstring];
                              if(dict) {
                                  NSString *time = [dict valueForKey:@"FirewallTime"];
                                  lasttime = [time intValue];
                              }
                              else {
                                  lasttime = -2;
                              }
                          }
                          if(lasttime == -1) {
                              [self showInfoMessage:@"You didn\'t backup before."];
                          }
                          else if(lasttime == -2) {
                              [self showErrorMessage:@"Retrieve last time backup error, try again?"];
                          }
                          else if(dict) {
                              NSString *firewall = [dict valueForKey:@"Firewall"];
                              NSDictionary *ruleList = [IJTJson json2dictionary:firewall];
                              UINavigationController *ruleNavVC = (UINavigationController *)
                              [self.storyboard instantiateViewControllerWithIdentifier:@"FirewallRuleNavVC"];
                              ruleNavVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                              IJTFirewallRuleTableViewController *ruleVC = (IJTFirewallRuleTableViewController *)[ruleNavVC.viewControllers firstObject];
                              ruleVC.delegate = self;
                              ruleVC.ruleList = [NSMutableDictionary dictionaryWithDictionary:ruleList];
                              ruleVC.lastTime = lasttime;
                              [self.navigationController presentViewController:ruleNavVC animated:YES completion:nil];
                          }
                      }];
    }];
}

#pragma mark firewall

FIREWALL_SHOW_CALLBACK_METHOD {
    NSMutableDictionary *dictRoot = (NSMutableDictionary *)object;
    NSMutableArray *array = nil;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if(proto == IJTFirewallProtocolIP) {
        array = [dictRoot valueForKey:@"IP"];
        
        if(op == IJTFirewallOperatorBlock && dir == IJTFirewallDirectionInAndOut && family == AF_INET && keepState == NO && quick == YES) {
            NSArray *blockList = [IJTAllowAndBlock blockList];
            
            for(NSDictionary *temp in blockList) {
                NSString *ipAddress = [temp valueForKey:@"IpAddress"];
                //match my block rule
                if(([src isEqualToString:ipAddress] &&
                    [srcMask isEqualToString:@"255.255.255.255"] &&
                    [dst isEqualToString:@"0.0.0.0"] &&
                    [dstMask isEqualToString:@"0.0.0.0"]) ||
                   ([src isEqualToString:@"0.0.0.0"] &&
                    [srcMask isEqualToString:@"0.0.0.0"] &&
                    [dst isEqualToString:ipAddress] &&
                    [dstMask isEqualToString:@"255.255.255.255"])) {
                       array = [dictRoot valueForKey:@"Block"];
                       break;
                   }
            }
        }
    }
    else if(proto == IJTFirewallProtocolTCP) {
        array = [dictRoot valueForKey:@"TCP"];
    }
    else if(proto == IJTFirewallProtocolUDP) {
        array = [dictRoot valueForKey:@"UDP"];
    }
    else if(proto == IJTFirewallProtocolICMP) {
        array = [dictRoot valueForKey:@"ICMP"];
    }
    else
        return;
    
    NSString *familyString = @"";
    if(family == AF_INET || family == 0)
        familyString = @"IPv4";
    else
        return;
    
    NSString *opString = @"";
    if(op == IJTFirewallOperatorAllow)
        opString = @"Allow";
    else if(op == IJTFirewallOperatorBlock)
        opString = @"Block";
    else
        return;
    
    NSString *dirString = @"";
    if(dir == IJTFirewallDirectionIn)
        dirString = @"In";
    else if(dir == IJTFirewallDirectionOut)
        dirString = @"Out";
    else if(dir == IJTFirewallDirectionInAndOut)
        dirString = @"In/Out";
    else
        return;
    
    NSString *keepStateString = @"";
    if(keepState)
        keepStateString = @"Yes";
    else
        keepStateString = @"No";
    
    NSString *quickString = @"";
    if(quick)
        quickString = @"Yes";
    else
        quickString = @"No";
    
    NSString *source = @"";
    NSString *destination = @"";
    
    
    if([src isEqualToString:@"0.0.0.0"] && [srcMask isEqualToString:@"0.0.0.0"]) {
        source = @"Any";
    }
    else {
        source = [self ipAddress:src netmask:srcMask];
    }
    if([dst isEqualToString:@"0.0.0.0"] && [dstMask isEqualToString:@"0.0.0.0"]) {
        destination = @"Any";
    }
    else {
        destination = [self ipAddress:dst netmask:dstMask];
    }
    
    [dict setObject:interface forKey:@"Interface"];
    [dict setObject:familyString forKey:@"Family"];
    [dict setObject:[NSNumber numberWithInt:proto] forKey:@"Protocol"];
    [dict setObject:opString forKey:@"Operator"];
    [dict setObject:dirString forKey:@"Direction"];
    [dict setObject:source forKey:@"Source"];
    [dict setObject:destination forKey:@"Destination"];
    [dict setObject:[NSNumber numberWithUnsignedShort:srcStartPort] forKey:@"Src Start Port"];
    [dict setObject:[NSNumber numberWithUnsignedShort:srcEndPort] forKey:@"Src End Port"];
    [dict setObject:[NSNumber numberWithUnsignedShort:dstStartPort] forKey:@"Dst Start Port"];
    [dict setObject:[NSNumber numberWithUnsignedShort:dstEndPort] forKey:@"Dst End Port"];
    [dict setObject:[NSNumber numberWithUnsignedChar:tcpFlags] forKey:@"TCP Flags"];
    [dict setObject:[NSNumber numberWithUnsignedChar:tcpFlagsMask] forKey:@"TCP Flags Mask"];
    [dict setObject:[NSNumber numberWithUnsignedChar:icmpType] forKey:@"ICMP Type"];
    [dict setObject:[NSNumber numberWithUnsignedChar:icmpCode] forKey:@"ICMP Code"];
    [dict setObject:keepStateString forKey:@"Keep State"];
    [dict setObject:quickString forKey:@"Quick"];
    [array addObject:dict];
}

- (NSString *)ipAddress: (NSString *)ipAddress netmask: (NSString *)netmask {
    struct in_addr addr;
    if(inet_aton([netmask UTF8String], &addr) == 0)
        return ipAddress;
    int slash = 0;
    for(int i = 0, mask = 1 ; i < 32 ; i++) {
        if(mask & addr.s_addr) {
            slash++;
        }
        mask <<= 1;
    }
    
    return [NSString stringWithFormat:@"%@/%d", ipAddress, slash];
}

- (void)beganRefreshing {
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        [self refresh];
        [self.refreshView endRefreshing];
    }];
}
#pragma mark functions
- (void)refresh {
    [self loadFirewall];
    [self.tableView reloadData];
}

- (void)showFunction {
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    if(self.tableView.editing == YES) {
        [self.tableView setEditing:NO animated:YES];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [self presentGridMenu:self.gridMenu animated:YES completion:nil];
        }];
    }
    else {
        [self presentGridMenu:self.gridMenu animated:YES completion:nil];
    }
}

- (void)gridMenu:(CNPGridMenu *)menu didTapOnItem:(CNPGridMenuItem *)item {
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [self dismissGridMenuAnimated:YES completion:^{
        if([item.title hasPrefix:@"Add"]) {
            [self addRule];
        }
        else if([item.title hasPrefix:@"Delete"]) {
            if(self.ruleList.count <= 0) {
                [self showInfoMessage:@"There is no firewall information"];
                return;
            }
            [self.tableView setEditing:YES animated:YES];
            self.dismissButton.enabled = NO;
            self.tabBarController.tabBar.userInteractionEnabled = NO;
            
            NSMutableArray *array = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
            [array replaceObjectAtIndex:0 withObject:self.doneButton];
            self.navigationItem.rightBarButtonItems = array;
        }
        else if([item.title hasPrefix:@"What"]) {
            [self goRuleVC];
        }
        else if([item.title hasPrefix:@"Backup"]) {
            [self backupAction];
        }
        else if([item.title hasPrefix:@"Restore"]) {
            [self restoreAction];
        }
    }];
}

- (void)doneAction {
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    [array replaceObjectAtIndex:0 withObject:self.detailButton];
    self.navigationItem.rightBarButtonItems = array;
    
    [self.tableView setEditing:NO animated:YES];
    self.dismissButton.enabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
}

- (void)backupAction {
    [KVNProgress showWithStatus:@"Retrieving last time backup..."];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        [IJTHTTP retrieveFrom:@"BackupRestoreFirewall.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@&Action=GET&Type=Firewall", self.serialNumber]
                      timeout:5
                        block:^(NSData *data) {
                            time_t lasttime = -1;
                            NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            
                            [IJTDispatch dispatch_main:^{
                                [KVNProgress dismiss];
                            }];
                            
                            if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                                lasttime = -1;
                            }
                            else {
                                NSDictionary *dict = [IJTJson json2dictionary:jsonstring];
                                if(dict) {
                                    NSString *time = [dict valueForKey:@"FirewallTime"];
                                    lasttime = [time intValue];
                                }
                                else {
                                    lasttime = -2;
                                }
                            }
                            
                            NSString *timestring = nil;
                            if(lasttime == -1 || lasttime == -2) {
                                timestring = @"Never";
                            }
                            else {
                                timestring = [IJTFormatString formatTime:lasttime];
                            }
                            
                            if(lasttime == -2) {
                                [self showErrorMessage:@"Retrieve last time backup error, try again?"];
                            }
                            else {
                                [IJTDispatch dispatch_main:^{
                                    SCLAlertView *alert = [IJTShowMessage baseAlertView];
                                    [alert addButton:@"Yes" actionBlock:^(void) {
                                        [IJTDispatch dispatch_main:^{
                                            [KVNProgress showWithStatus:@"Posting..."];
                                        }];
                                        
                                        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                                            NSString *allowContents = [IJTJson dictionary2sting:self.ruleList prettyPrint:YES];
                                            allowContents = [IJTHTTP string2post:allowContents];
                                            
                                            [IJTHTTP retrieveFrom:@"BackupRestoreFirewall.php"
                                                             post:[NSString stringWithFormat:@"SerialNumber=%@&Action=SET&Type=Firewall&Value=%@", self.serialNumber, allowContents]
                                                          timeout:5
                                                            block:^(NSData *data) {
                                                                
                                                                NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                                                                
                                                                [IJTDispatch dispatch_main:^{
                                                                    [KVNProgress dismiss];
                                                                }];
                                                                
                                                                if([jsonstring integerValue] == IJTStatusServerSuccess) {
                                                                    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                                                                        [self showSuccessMessage:@"Success"];
                                                                    }];
                                                                }
                                                                else {
                                                                    [self showErrorMessage:@"Error when posting, try again?"];
                                                                }
                                                            }];
                                        }];
                                    }];
                                    BOOL empty = NO;
                                    NSArray *ip = [self.ruleList valueForKey:@"IP"];
                                    NSArray *tcp = [self.ruleList valueForKey:@"TCP"];
                                    NSArray *udp = [self.ruleList valueForKey:@"UDP"];
                                    NSArray *icmp = [self.ruleList valueForKey:@"ICMP"];
                                    
                                    if(ip.count == 0 && tcp.count == 0 && udp.count == 0 && icmp.count == 0)
                                        empty = YES;
                                    
                                    if(empty) {
                                        [alert showWarning:@"Backup"
                                                  subTitle:[NSString stringWithFormat:@"Firewall list is empty.\nLast time back : %@.", timestring]
                                          closeButtonTitle:@"No"
                                                  duration:0];
                                    }
                                    else {
                                        [alert showInfo:@"Backup"
                                               subTitle:[NSString stringWithFormat:@"Last time backup : %@.", timestring]
                                       closeButtonTitle:@"No"
                                               duration:0];
                                    }
                                }];
                                
                            }
                        }];
        
        
    }];
}

- (void)restoreAction {
    [KVNProgress showWithStatus:@"Retrieving last time backup..."];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        
        
        [IJTHTTP retrieveFrom:@"BackupRestoreFirewall.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@&Action=GET&Type=Firewall", self.serialNumber]
                      timeout:5
                        block:^(NSData *data){
                            time_t lasttime = -1;
                            NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            
                            [IJTDispatch dispatch_main:^{
                                [KVNProgress dismiss];
                            }];
                            
                            NSDictionary *dict = nil;
                            if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                                lasttime = -1;
                            }
                            else {
                                dict = [IJTJson json2dictionary:jsonstring];
                                if(dict) {
                                    NSString *time = [dict valueForKey:@"AllowTime"];
                                    lasttime = [time intValue];
                                }
                                else {
                                    lasttime = -2;
                                }
                            }
                            
                            NSString *timestring = nil;
                            if(lasttime == -1 || lasttime == -2) {
                                timestring = @"Never";
                            }
                            else {
                                timestring = [IJTFormatString formatTime:lasttime];
                            }
                            
                            if(lasttime == -2) {
                                [self showErrorMessage:@"Retrieve last time backup error, try again?"];
                            }
                            else {
                                [IJTDispatch dispatch_main:^{
                                    SCLAlertView *alert = [IJTShowMessage baseAlertView];
                                    NSString *closeButton = @"OK";
                                    if(lasttime != -1) {
                                        [alert addButton:@"Yes" actionBlock:^(void) {
                                            NSString *firewall = [dict valueForKey:@"Firewall"];
                                            self.ruleList = [IJTJson json2dictionary:firewall];
                                            [IJTAllowAndBlock restoreFirewallList:self.ruleList target:self];
                                            
                                            [self refresh];
                                            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                                                [self showSuccessMessage:@"Success"];
                                            }];
                                        }];
                                        closeButton = @"No";
                                    }
                                    
                                    [alert showInfo:@"Restore"
                                           subTitle:[NSString stringWithFormat:@"Last time backup : %@.", timestring]
                                   closeButtonTitle:closeButton
                                           duration:0];
                                }];
                                
                            }
                        }];
    }];
}

- (void)addRule {
    UINavigationController *ruleNavVC = (UINavigationController *)
    [self.storyboard instantiateViewControllerWithIdentifier:@"AddFirewallNavVC"];
    ruleNavVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    IJTAddFirewallTableViewController *addVC = (IJTAddFirewallTableViewController *)[ruleNavVC.viewControllers firstObject];
    addVC.delegate = self;
    [self.navigationController presentViewController:ruleNavVC animated:YES completion:nil];
}

- (void)callback {
    [self refresh];
}

- (void)loadFirewall {
    if(!getegid()) {
        IJTFirewall *fw = [[IJTFirewall alloc] init];
        if(fw.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
            [fw close];
            fw = nil;
            return;
        }
        
        NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
        [temp setValue:[[NSMutableArray alloc] init] forKey:@"IP"];
        [temp setValue:[[NSMutableArray alloc] init] forKey:@"TCP"];
        [temp setValue:[[NSMutableArray alloc] init] forKey:@"UDP"];
        [temp setValue:[[NSMutableArray alloc] init] forKey:@"ICMP"];
        [temp setValue:[[NSMutableArray alloc] init] forKey:@"Block"];
        
        [fw getAllRulesRegisterTarget:self
                             selector:FIREWALL_SHOW_CALLBACK_SEL
                               object:temp];
        [fw close];
        fw = nil;
        [temp writeToFile:[IJTAllowAndBlock firewallFilename] atomically:YES];
    }
    
    self.ruleList = [IJTAllowAndBlock firewallList];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *array = nil;
    switch (section) {
        case 0:
            array = [self.ruleList valueForKey:@"IP"];
            return [NSString stringWithFormat:@"IPv4(%lu)", (unsigned long)array.count];
            
        case 1:
            array = [self.ruleList valueForKey:@"TCP"];
            return [NSString stringWithFormat:@"TCP(%lu)", (unsigned long)array.count];
            
        case 2:
            array = [self.ruleList valueForKey:@"UDP"];
            return [NSString stringWithFormat:@"UDP(%lu)", (unsigned long)array.count];
            
        case 3:
            array = [self.ruleList valueForKey:@"ICMP"];
            return [NSString stringWithFormat:@"ICMP(%lu)", (unsigned long)array.count];
            
        case 4:
            array = [self.ruleList valueForKey:@"Block"];
            return [NSString stringWithFormat:@"Block List(%ld)", (unsigned long)array.count];
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
    NSArray *blockArray = [self.ruleList valueForKey:@"Block"];
    
    if(ipArray.count == 0 && tcpArray.count == 0 && udpArray.count == 0 && icmpArray.count == 0 && blockArray.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
        switch (section) {
            case 0: return ipArray.count;
            case 1: return tcpArray.count;
            case 2: return udpArray.count;
            case 3: return icmpArray.count;
            case 4: return blockArray.count;
        }
    }
    return 0;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if(indexPath.section == 4)
        return NO;
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 || indexPath.section == 4) { //IP and block
        NSString *key = nil;
        if(indexPath.section == 0) {
            key = @"IP";
        }
        else {
            key = @"Block";
        }
        IJTIPRuleTableViewCell *cell = (IJTIPRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"IPRuleCell" forIndexPath:indexPath];
        
        NSArray *array = [self.ruleList valueForKey:key];
        
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
    else if(indexPath.section == 1) {
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
    else if(indexPath.section == 2) {
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
    else if(indexPath.section == 3) {
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

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 4) {
        [self showInfoMessage:@"These rules can only be deleted in \"Block\"."];
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)ipAddressWithSlash: (NSString *)ipAddress slash: (NSString **)netmask {
    if([ipAddress isEqualToString:@"Any"]) {
        *netmask = @"0.0.0.0";
        return @"0.0.0.0";
    }
    
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

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SCLAlertView *alert = [IJTShowMessage baseAlertView];
        
        __block NSInteger section = indexPath.section;
        [alert addButton:@"Yes" actionBlock:^{
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
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
                
                if(interface == nil || interface.length <= 0) {
                    [self showErrorMessage:@"The rule can\'t be deleted."];
                    return;
                }
                
                IJTFirewall *fw = [[IJTFirewall alloc] init];
                if(fw.errorHappened) {
                    [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
                    return;
                }
                if(section == 0) {
                    [fw deleteRuleAtInterface:interface
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
                        [fw deleteTCPOrUDPRuleAtInterface:interface
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
                        [fw deleteTCPOrUDPRuleAtInterface:interface
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
                        [fw deleteTCPOrUDPRuleAtInterface:interface
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
                        [fw deleteTCPOrUDPRuleAtInterface:interface
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
                    [fw deleteICMPRuleAtInterface:interface
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
                    if(fw.errorCode == ENOENT) {
                        [self showErrorMessage:@"Rule not found."];
                    }
                    else {
                        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(fw.errorCode)]];
                    }
                }
                
                [fw close];
                fw = nil;
                [self refresh];
            }];
        }];
        
        [alert showWarning:@"Warning"
                  subTitle:@"Are you sure delete it?"
          closeButtonTitle:@"No"
                  duration:0];
        
    }//end if
}


@end
