//
//  IJTLANHistoryTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTLANHistoryTableViewController.h"
#import "IJTLANTaskTableViewCell.h"
#import "IJTLANHistoryTableViewCell.h"
#import "IJTLANScanTableViewController.h"

@interface IJTLANHistoryTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) UIBarButtonItem *scanButton;
@property (nonatomic, strong) NSString *startIp;
@property (nonatomic, strong) NSString *endIp;
@property (nonatomic, strong) NSString *bssid;
@property (nonatomic, strong) NSString *ssid;
@property (nonatomic, strong) NSMutableArray *historyArray;

@property (nonatomic, strong) UIBarButtonItem *trashButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

@end

@implementation IJTLANHistoryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 90;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"close.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.scanButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"LANNav.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(gotoScan)];
    
    //set edit button
    self.trashButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"trash.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(editAction:)];
    
    self.doneButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                       target:self
                       action:@selector(editAction:)];
    
    self.navigationItem.leftBarButtonItem = self.dismissButton;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_scanButton, _trashButton, nil];
    
    [self loadHistory];
    
    self.messageLabel.text = @"Click icon to scan";
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

- (void)callback {
    [self loadHistory];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)loadHistory {
    NSString *path = nil;
    if(geteuid()) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        path = [NSString stringWithFormat:@"%@/%@", basePath, @"LANHistory"];
    }
    else {
        path = @"/var/root/Injector/LANHistory";
    }
    self.historyArray = [NSMutableArray arrayWithContentsOfFile:path];
    for(NSMutableDictionary *dict in _historyArray) {
        
        NSString *startIp = [dict valueForKey:@"StartIP"];
        NSString *endIp = [dict valueForKey:@"EndIP"];
        [dict setValue:[NSString stringWithFormat:@"%@ - %@", startIp, endIp] forKey:@"Range"];
        
        NSDate *date = [dict valueForKey:@"Date"];
        [dict setValue:[IJTFormatString formatLANScanDate:date] forKey:@"DateString"];
        
        NSArray *data = [dict valueForKey:@"Data"];
        [dict setValue:@(data.count) forKey:@"Amount"];
    }
}

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoScan {
    IJTLANScanTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LANScanVC"];
    IJTArp_scan *arpScan = [[IJTArp_scan alloc] initWithInterface:@"en0"];
    [arpScan setLAN];
    vc.startIp = [arpScan getStartIpAddress];
    vc.endIp = [arpScan getEndIpAddress];
    vc.ssid = [ALNetwork SSID];
    vc.bssid = [ALNetwork BSSID];
    vc.startScan = YES;
    vc.delegate = self;
    [arpScan close];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)editAction: (id)sender {
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    if(button == self.trashButton) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_scanButton, _doneButton, nil];
        self.dismissButton.enabled = NO;
        self.scanButton.enabled = NO;
        [self.tableView setEditing:YES animated:YES];
        self.tabBarController.tabBar.userInteractionEnabled = NO;
    }
    else if(button == self.doneButton) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_scanButton, _trashButton, nil];
        self.dismissButton.enabled = YES;
        self.scanButton.enabled = YES;
        [self.tableView setEditing:NO animated:YES];
        self.tabBarController.tabBar.userInteractionEnabled = YES;
    }
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    self.startIp = @"";
    self.endIp = @"";
    self.ssid = @"";
    self.bssid = @"";
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"Scan LAN"];
        [self.scanButton setEnabled:NO];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.scanButton setEnabled:YES];
        IJTArp_scan *arpScan = [[IJTArp_scan alloc] initWithInterface:@"en0"];
        if(arpScan.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"ARP-scan : %s.", strerror(arpScan.errorCode)]];
        }
        [arpScan setLAN];
        if(arpScan.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"ARP-scan : %s.", strerror(arpScan.errorCode)]];
        }
        else {
            NSString *range = [NSString stringWithFormat:@"%@ - %@", [arpScan getStartIpAddress], [arpScan getEndIpAddress]];
            [self.taskInfoDict setValue:range forKey:@"Range"];
            [self.taskInfoDict setValue:[ALNetwork BSSID] forKey:@"BSSID"];
            [self.taskInfoDict setValue:[ALNetwork SSID] forKey:@"SSID"];
            self.startIp = [arpScan getStartIpAddress];
            self.endIp = [arpScan getEndIpAddress];
            self.ssid = [ALNetwork SSID];
            self.bssid = [ALNetwork BSSID];
            [arpScan close];
        }
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 1) {
        IJTLANScanTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LANScanVC"];
        NSDictionary *dict = _historyArray[indexPath.row];

        NSArray *historyArray = [dict valueForKey:@"Data"];
        vc.startIp = [dict valueForKey:@"StartIP"];
        vc.endIp = [dict valueForKey:@"EndIP"];
        vc.ssid = [dict valueForKey:@"SSID"];
        vc.bssid = [dict valueForKey:@"BSSID"];
        vc.startScan = NO;
        vc.delegate = self;
        vc.historyArray = historyArray;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.historyArray.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    
    if(section == 0)
        return 1;
    else if(section == 1)
        return _historyArray.count;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"LAN Information";
    }
    else if(section == 1) {
        return [NSString stringWithFormat:@"History(%lu)", (unsigned long)_historyArray.count];
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTLANTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Range"
                         label:cell.rangeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"BSSID"
                         label:cell.bssidLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"SSID"
                         label:cell.ssidLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTLANHistoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HistoryCell" forIndexPath:indexPath];
        NSDictionary *dict = _historyArray[indexPath.row];
        
        
        [IJTFormatUILabel dict:dict
                           key:@"SSID"
                         label:cell.ssidLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:17]];
        [IJTFormatUILabel dict:dict
                           key:@"Range"
                         label:cell.rangeLabel
                         color:[UIColor darkGrayColor]
                          font:[UIFont systemFontOfSize:11]];
        [IJTFormatUILabel dict:dict
                           key:@"DateString"
                         label:cell.dateLabel
                         color:[UIColor darkGrayColor]
                          font:[UIFont systemFontOfSize:11]];
        [IJTFormatUILabel dict:dict
                           key:@"Amount"
                         label:cell.amountLabel
                         color:[UIColor lightGrayColor]
                          font:[UIFont systemFontOfSize:11]];
        
        
        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1)
        return YES;
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            SCLAlertView *alert = [IJTShowMessage baseAlertView];
            IJTLANHistoryTableViewCell *cell = (IJTLANHistoryTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            NSInteger index = indexPath.row;
            NSDictionary *dict = [_historyArray objectAtIndex:index];
            __block NSDate *date = [dict valueForKey:@"Date"];
            [alert addButton:@"Yes" actionBlock:^{
                NSDictionary *needDelete = nil;
                
                for(NSDictionary *dict in _historyArray) {
                    NSDate *time = [dict valueForKey:@"Date"];
                    if(time.timeIntervalSince1970 == date.timeIntervalSince1970) {
                        needDelete = dict;
                        break;
                    }
                }
                if(needDelete) {
                    [self.historyArray removeObject:needDelete];
                    NSString *path = nil;
                    if(geteuid()) {
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
                        path = [NSString stringWithFormat:@"%@/%@", basePath, @"LANHistory"];
                    }
                    else {
                        path = @"/var/root/Injector/LANHistory";
                    }
                    [self.historyArray writeToFile:path atomically:YES];
                }
                
                [self callback];
            }];
            [alert showWarning:@"Warning"
                      subTitle:[NSString stringWithFormat:@"Are you sure delete: %@(%@)?", cell.ssidLabel.text, cell.dateLabel.text]
              closeButtonTitle:@"No"
                      duration:0];
        }
    }
}
@end
