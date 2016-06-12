//
//  IJTWiFiScannerTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/11/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWiFiScannerTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTWiFiScannerKnownNetworksTableViewController.h"
#import "IJTWiFiScannerNetworkTableViewCell.h"
#import "IJTWiFiScannerDetailTableViewController.h"

@interface IJTWiFiScannerTableViewController ()

@property (nonatomic, strong) FUISwitch *wifiSwitch;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) IJTWiFiScanner *scanner;
@property (nonatomic, strong) NSArray *scanList;
@property (nonatomic, strong) SSARefreshControl *refreshView;
@property (nonatomic, strong) FUIButton *scanButton;
@property (nonatomic) BOOL scanning;

@end

@implementation IJTWiFiScannerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    if(self.multiToolButton == nil) {
        self.dismissButton = [[UIBarButtonItem alloc]
                              initWithImage:[UIImage imageNamed:@"down.png"]
                              style:UIBarButtonItemStylePlain
                              target:self action:@selector(dismissVC)];
    }
    else {
        self.dismissButton = self.multiToolButton;
    }
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    
    self.scanner = [[IJTWiFiScanner alloc] init];
    
    self.wifiSwitch = [[FUISwitch alloc]
                             initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.wifiSwitch.onLabel.text = @"YES";
    self.wifiSwitch.offLabel.text = @"NO";
    self.wifiSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.wifiSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.wifiSwitch addTarget:self action:@selector(wifiSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    //scan button
    _scanButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [_scanButton addTarget:self action:@selector(scan:) forControlEvents:UIControlEventTouchUpInside];
    [_scanButton setTitle:@"Scan" forState:UIControlStateNormal];

    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        if([_scanner isWiFiEnabled]) {
            [self scan:_scanButton];
        }
    }];
    //refresh control
    /*self.refreshView = [[SSARefreshControl alloc] initWithScrollView:self.tableView andRefreshViewLayerType:SSARefreshViewLayerTypeOnScrollView];
    self.refreshView.delegate = self;
     */
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
    if([IJTNetowrkStatus supportWifi]) {
        self.wifiReachability = [IJTNetowrkStatus wifiReachability];
        [self.wifiReachability startNotifier];
        [self reachabilityChanged:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if([IJTNetowrkStatus supportWifi])
        [self.wifiReachability stopNotifier];
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark refresh delegate
- (void)beganRefreshing {
    if(_scanning) {
        return;
    }
    
    if(![_scanner isWiFiEnabled]) {
        [self showErrorMessage:@"Wi-Fi is disabled."];
        [self.refreshView endRefreshing];
        return;
    }
    
    [self scan:_scanButton];
}

- (void)scan: (id)sender {
    if(_scanning) {
        return;
    }
    
    [_scanButton setEnabled:NO];
    
    _scanning = YES;
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        NSArray *temp = [NSArray arrayWithArray:[_scanner scan]];
        if(temp.count > 0)
            self.scanList = temp;
        //[self.refreshView endRefreshing];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        [_scanButton setEnabled:YES];
        _scanning = NO;
    }];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    [self.tableView reloadData];
}

#pragma mark WiFi function
- (void)wifiSwitchValueChanged: (id)sender {
    if(getegid())
        return;
    
    [_scanner setWiFiEnabled:_wifiSwitch.isOn];
    
    if(_wifiSwitch.isOn) {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME*2 block:^{
            [self scan:_scanButton];
        }];
    }
    else {
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
    
    if(_scanList.count > 0) {
        NSMutableArray *needDelete = [[NSMutableArray alloc] init];
        for(NSUInteger i = 0 ; i < [_scanList count] ; i++) {
            [needDelete addObject:[NSIndexPath indexPathForRow:i inSection:1]];
        }
        _scanList = @[];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:needDelete withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0) {
        if(_scanner.isWiFiEnabled) {
            return 3;
        }
        else {
            return 2;
        }
    }
    else if(section == 1) {
        return _scanList.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(indexPath.row == 0) {
            GET_ARG_CELL;
            
            cell.nameLabel.text = @"Wi-Fi";
            
            [cell.controlView addSubview:_wifiSwitch];
            [self.wifiSwitch setOn:[_scanner isWiFiEnabled] animated:YES];
            
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            [cell layoutIfNeeded];
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            _wifiSwitch.frame = CGRectMake(width - 80, 0, 80, 28);
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_ARG_CELL;
            
            cell.nameLabel.text = @"Known Networks";
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
        else if(indexPath.row == 2) {
            GET_EMPTY_CELL;
            
            [_scanButton setEnabled:[_scanner isWiFiEnabled]];
            
            [cell.contentView addSubview:_scanButton];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if(indexPath.section == 1) {
        IJTWiFiScannerNetworkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NetworkCell" forIndexPath:indexPath];
        
        NSDictionary *dict = [_scanList objectAtIndex:indexPath.row];
        UIColor *color = IJTBlackColor;
        
        if([[dict valueForKey:@"Apple Hotspot"] boolValue]) {
            cell.isAppleHotspotImageView.image = [UIImage imageNamed:@"AppleHotspot.png"];
        }
        else {
            cell.isAppleHotspotImageView.image = nil;
        }
        
        if([[dict valueForKey:@"IsCurrentNetwork"] boolValue]) {
            color = [IJTColor lighter:IJTValueColor times:1];
            cell.isAppleHotspotImageView.image =
            [cell.isAppleHotspotImageView.image imageWithColor:color];
        }
        
        [IJTFormatUILabel dict:dict
                           key:@"SSID"
                         label:cell.SSIDLabel
                         color:color
                          font:[UIFont systemFontOfSize:17]];
        if([[dict valueForKey:@"Hidden"] boolValue]) {
            cell.SSIDLabel.text = @"";
        }
        cell.SSIDLabel.adjustsFontSizeToFitWidth = YES;
        
        [IJTFormatUILabel dict:dict
                           key:@"BSSID"
                         label:cell.BSSIDLabel
                         color:color
                          font:[UIFont systemFontOfSize:11]];
        
        if([[dict valueForKey:@"Requires Password"] boolValue]) {
            cell.keyImageView.image = [UIImage imageNamed:@"key.png"];
            cell.keyImageView.image =
            [cell.keyImageView.image imageWithColor:color];
        }
        else {
            cell.keyImageView.image = nil;
        }
        
        [IJTFormatUILabel dict:dict
                           key:@"RSSI"
                         label:cell.RSSILabel
                         color:color
                          font:[UIFont boldSystemFontOfSize:9]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Channel"
                        prefix:@"CH "
                         label:cell.channelLabel
                         color:color
                          font:[UIFont boldSystemFontOfSize:11]];
        cell.channelLabel.textColor = color;
        
        
        [IJTFormatUILabel dict:dict
                           key:@"Encryption Model"
                         label:cell.encryptionModelLabel
                         color:color
                          font:[UIFont boldSystemFontOfSize:9]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section == 0 && indexPath.row == 1) {
        IJTWiFiScannerKnownNetworksTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"KnownNetworkVC"];
        vc.knownNetworks = [NSMutableArray arrayWithArray:[_scanner getKnownNetworks]];
        vc.multiToolButton = self.multiToolButton;
        vc.scanner = self.scanner;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if(indexPath.section == 1) {
        NSDictionary *dict = [_scanList objectAtIndex:indexPath.row];
        
        SCLAlertView *alert = [IJTShowMessage baseAlertView];
        if([[dict valueForKey:@"IsCurrentNetwork"] boolValue]) {
            [alert addButton:@"Yes" actionBlock:^{
                
                [_scanner disassociate];
                
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showInfoMessage:@"Please rescan to refresh current status."];
                    
                    self.scanList = [_scanner networks];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
                }];
            }];
            
            [alert showWarning:@"Warning"
                      subTitle:@"Do you want to disconnect?"
              closeButtonTitle:@"No"
                      duration:0];
        }
        else {
            BOOL requiresUsername = [[dict valueForKey:@"Requires Username"] boolValue];
            BOOL requiresPassword = [[dict valueForKey:@"Requires Password"] boolValue];
            NSString *SSID = [dict valueForKey:@"SSID"];
            NSString *BSSID = [dict valueForKey:@"BSSID"];
            
            if(SSID.length <= 0) {
                [self showInfoMessage:@"This is a hidden SSID."];
            }
            else if(!requiresUsername && !requiresPassword) {
                [alert addButton:@"Connect" actionBlock:^{
                    [_scanner associateWithSSID:SSID
                                          BSSID:BSSID
                                       username:@""
                                       password:@""];
                    
                    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                        [self showInfoMessage:@"Please rescan to refresh current status."];
                        
                        self.scanList = [_scanner networks];
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }];
                }];
                [alert showEdit:@"Connect"
                       subTitle:[NSString stringWithFormat:@"Connect to \"%@\"?", SSID]
               closeButtonTitle:@"Cancle"
                       duration:0];
                
            }
            else if(requiresPassword && !requiresUsername) {
                UITextField *password = [alert addTextField:@"Password"];
                password.keyboardType = UIKeyboardTypeASCIICapable;
                password.secureTextEntry = YES;
                
                [alert addButton:@"Connect" actionBlock:^{
                    [password resignFirstResponder];
                    
                    if(password == nil || password.text.length <= 0) {
                        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                            [self showErrorMessage:@"Please enter a password."];
                        }];
                        return;
                    }
                    
                    [_scanner associateWithSSID:SSID
                                          BSSID:BSSID
                                       username:@""
                                       password:password.text];
                    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                        [self showInfoMessage:@"Please rescan to refresh current status."];
                        self.scanList = [_scanner networks];
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }];
                }];
                
                [alert showEdit:@"Authentication"
                       subTitle:[NSString stringWithFormat:@"\"%@\" requires authentication.", SSID]
               closeButtonTitle:@"Cancle"
                       duration:0];
            }
            else {
                [self showInfoMessage:@"Sorry, I need to figure out how apple set username."];
            }
        }
        
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1) {
        IJTWiFiScannerDetailTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"WiFiScannerDetailVC"];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[_scanList objectAtIndex:indexPath.row]];
        NSMutableDictionary *recordDict = [NSMutableDictionary dictionaryWithDictionary:[dict valueForKey:@"Record"]];
        
        [self formatBooleanDictonary:dict key:@"Apple Hotspot"];
        [self formatBooleanDictonary:dict key:@"Ad Hoc"];
        [self formatBooleanDictonary:dict key:@"Hidden"];
        [self formatBooleanDictonary:dict key:@"Requires Username"];
        [self formatBooleanDictonary:dict key:@"Requires Password"];
        NSNumber *currentNetwork = [dict valueForKey:@"IsCurrentNetwork"];
        [dict setValue:currentNetwork forKey:@"Current Network"];
        [dict removeObjectForKey:@"IsCurrentNetwork"];
        [self formatBooleanDictonary:dict key:@"Current Network"];
        NSNumber *RSSI = [dict valueForKey:@"RSSI"];
        [dict setValue:[NSString stringWithFormat:@"%ld dBm", (long)[RSSI integerValue]] forKey:@"RSSI"];
        [dict removeObjectForKey:@"Record"];
        NSString *BSSID = [dict valueForKey:@"BSSID"];
        [dict setObject:[IJTDatabase oui:BSSID] forKey:@"Vendor"];
        
        NSNumber *strength = [recordDict valueForKey:@"Strength"];
        [recordDict setValue:[NSString stringWithFormat:@"%f", [strength doubleValue]] forKey:@"Strength"];
        
        NSNumber *scaledRSSI = [recordDict valueForKey:@"ScaledRSSI"];
        [recordDict setValue:[NSString stringWithFormat:@"%f", [scaledRSSI doubleValue]] forKey:@"ScaledRSSI"];
        
        NSArray *rates = [recordDict valueForKey:@"RATES"];
        NSString *temp = @"";
        for(NSNumber *s in rates) {
            if(temp.length <= 0) {
                temp = [NSString stringWithFormat:@"%ld", (long)[s integerValue]];
            }
            else {
                temp = [temp stringByAppendingString:[NSString stringWithFormat:@"\n%ld", (long)[s integerValue]]];
            }
        }//end for
        [recordDict setValue:temp forKey:@"RATES"];
        
        [self formatDictonary:recordDict];
        [self formatDictonary:dict];
        
        
        vc.dict = [NSDictionary dictionaryWithDictionary:dict];
        vc.recordDict = [NSDictionary dictionaryWithDictionary:recordDict];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(indexPath.row == 2) {
            return 55.f;
        }
        else {
            return 44.f;
        }
    }
    else if(indexPath.section == 1) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    
    return 0.f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"General";
    else if(section == 1) {
        if(_scanList.count == 0) {
            return @"";
        }
        if(_scanList.count == 1) {
            return [NSString stringWithFormat:@"Network(%lu)", (unsigned long)_scanList.count];
        }
        else {
            return [NSString stringWithFormat:@"Networks(%lu)", (unsigned long)_scanList.count];
        }
    }
    return @"";
}

- (void)formatDictonary: (NSMutableDictionary *)dict {
    for(NSString *key in [dict allKeys]) {
        id object = [dict valueForKey:key];
        
        if([object isKindOfClass:[NSArray class]]) {
            NSString *temp = @"";
            for(id s in object) {
                if([s isKindOfClass:[NSString class]]) {
                    if(temp.length <= 0) {
                        temp = [NSString stringWithString:s];
                    }
                    else {
                        temp = [temp stringByAppendingString:[NSString stringWithFormat:@"\n%@", s]];
                    }
                }
                
            }//end for
            //replace
            [dict removeObjectForKey:key];
            [dict setObject:temp forKey:key];
        }
    }
}

- (void)formatBooleanDictonary: (NSMutableDictionary *)dict key: (NSString *)key {
    if([[dict valueForKey:key] boolValue]) {
        [dict setValue:@"Yes" forKey:key];
    }
    else {
        [dict setValue:@"No" forKey:key];
    }
}

@end
