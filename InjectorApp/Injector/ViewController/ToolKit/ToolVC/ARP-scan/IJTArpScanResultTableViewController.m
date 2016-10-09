//
//  IJTArpScanResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/19.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArpScanResultTableViewController.h"
#import "IJTArpScanArpFrameTableViewCell.h"
#import "IJTArpScanTaskTableViewCell.h"

@interface IJTArpScanResultTableViewController ()

@property (nonatomic, strong) IJTArp_scan *arpscan;
@property (nonatomic, strong) NSMutableArray *replyList;
@property (nonatomic, strong) UIBarButtonItem *scanButton;
@property (nonatomic) BOOL scanned;
@property (nonatomic, strong) ASProgressPopUpView *progressView;

@property (nonatomic, strong) NSThread *scanThread;
@property (nonatomic, strong) NSTimer *updateProgressViewTimer;
@property (nonatomic) BOOL cancle;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic) BOOL scanning;

@property (nonatomic) NSUInteger currentIndex;

@end

@implementation IJTArpScanResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"ARP-scan";
    
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.scanButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"ARP-scanNav.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(startScan)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(interruptScan)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_scanButton, nil];
    
    self.scanned = NO;
    
    self.progressView = [IJTProgressView baseProgressPopUpView];
    self.progressView.dataSource = self;
    
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
    [self.arpscan close];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"ARP-scan"];
        [self.scanButton setEnabled:NO];
        [self interruptScan];
        if(self.arpscan != nil) {
            [self.arpscan close];
            self.arpscan = nil;
        }
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.scanButton setEnabled:YES];
        
        if(self.arpscan == nil) {
            //open
            self.arpscan = [[IJTArp_scan alloc] initWithInterface:@"en0"];
            if(self.arpscan.errorHappened) {
                [self showErrorMessage:[NSString stringWithFormat:@"%s.",
                                                  strerror(self.arpscan.errorCode)]];
            }
            else {
                [self setRange];
                if([self.arpscan getTotalInjectCount] == 1) {
                    self.interval = 1;
                }
            }
        }
    }
    
    NSString *injectRange = @"";
    if(self.arpscan != nil) {
        injectRange = [NSString stringWithFormat:@"%@ - %@", [self.arpscan getStartIpAddress], [self.arpscan getEndIpAddress]];
    }
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:injectRange forKey:@"Range"];
    [self.taskInfoDict setValue:[ALNetwork SSID] forKey:@"SSID"];
    [self.taskInfoDict setValue:[ALNetwork BSSID] forKey:@"BSSID"];
    [self.taskInfoDict setValue:[NSString stringWithFormat:@"%llu", [self.arpscan getTotalInjectCount]] forKey:@"Amount"];
    
    [IJTDispatch dispatch_main:^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

#pragma mark scan

- (void)setRange {
    switch (self.scanType) {
        case 0: [self.arpscan setLAN]; break;
        case 1: [self.arpscan setNetwork:_networkAddress slash:_slash]; break;
        case 2: [self.arpscan setFrom:_startIpAddress to:_endIpAddress]; break;
    }
    
    if(self.arpscan.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.",
                                          strerror(self.arpscan.errorCode)]];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_scanButton, nil];
        return;
    }
}

- (void)interruptScan {
    if(self.scanThread || self.updateProgressViewTimer) {
        [self.stopButton setEnabled:NO];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            if(![self.scanThread isFinished]) {
                self.cancle = YES;
                while(self.scanThread) {
                    usleep(100);
                }
            }
            if(self.updateProgressViewTimer) {
                [self.updateProgressViewTimer invalidate];
                self.updateProgressViewTimer = nil;
            }
            [self.stopButton setEnabled:YES];
        }];
    }
    
    self.scanning = NO;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_scanButton, nil];
}

- (void)injectAndRead: (id)sender {
    //inject
    
    u_int64_t amount = [self.arpscan getTotalInjectCount];
    for(_currentIndex = 0 ; _currentIndex < amount ; _currentIndex++) {
        if(self.cancle)
            break;
        
        [self.arpscan injectWithInterval:_interval];
        
        if(self.arpscan.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(self.arpscan.errorCode)]];
            
            if(self.arpscan.errorCode == ENOBUFS) {
                sleep(1);
            }
            else
                break;
        }
    }//end for inject
    
    [self.arpscan readTimeout:_timeout
                       target:self
                     selector:ARPSCAN_CALLBACK_SEL
                       object:_replyList];

    if(self.arpscan.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(self.arpscan.errorCode)]];
    }
    
    [self.updateProgressViewTimer invalidate];
    self.updateProgressViewTimer = nil;
    
    
    [IJTDispatch dispatch_main:^{
        [self.stopButton setEnabled:NO];self.scanning = NO;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
        [self.dismissButton setEnabled:YES];
        [self.stopButton setEnabled:YES];
        [self.tableView setUserInteractionEnabled:YES];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_scanButton, nil];
        [self.progressView setProgress:1.0 animated:YES];
        [self.progressView removeFromSuperview];
        
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        }];
    }];
    
    self.scanThread = nil;
}

- (void)updateProgressView: (id)sender {
    u_int64_t total = [self.arpscan getTotalInjectCount];
    u_int64_t remain = [self.arpscan getRemainInjectCount];
    float value = (total - remain)/(float)total;
    
    [self.progressView setProgress:value animated:YES];
}

- (void)startScan {
    self.scanning = YES;
    self.replyList = [[NSMutableArray alloc] init];
    self.scanned = NO;
    self.progressView.progress = 0.0f;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    self.scanned = YES;
    self.cancle = NO;
    [self setRange];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    [self.dismissButton setEnabled:NO];
    [self.tableView setUserInteractionEnabled:NO];
    
    //add progress view
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:
                                      CGRectMake(0, 0, SCREEN_WIDTH, CGRectGetHeight(_progressView.frame))];
    [self.tableView setContentOffset:CGPointMake(0, -60) animated:YES];
    [self.tableView.tableHeaderView addSubview:self.progressView];
    
    //read inject and read
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(60, 0, 0, 0);
        self.scanThread = [[NSThread alloc] initWithTarget:self selector:@selector(injectAndRead:) object:nil];
        [self.scanThread start];
        self.updateProgressViewTimer =
        [NSTimer scheduledTimerWithTimeInterval:0.05
                                         target:self
                                       selector:@selector(updateProgressView:)
                                       userInfo:nil repeats:YES];
    }];
}

ARPSCAN_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = (NSMutableArray *)object;
        
        for(NSDictionary *dict in list) {
            NSString *ip = [dict valueForKey:@"IpAddress"];
            if([ip isEqualToString:ipAddress])
                return;
        }
    
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        NSString *timestamp = [IJTFormatString formatTimestamp:rt secondsPadding:3 decimalPoint:6];
        
        [dict setValue:timestamp forKey:@"Time"];
        [dict setValue:ipAddress forKey:@"IpAddress"];
        [dict setValue:macAddress forKey:@"MacAddress"];
        
        [list addObject:dict];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:list.count - 1 inSection:1]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

#pragma mark - ASProgressPopUpView dataSource

// <ASProgressPopUpViewDataSource> is entirely optional
// it allows you to supply custom NSStrings to ASProgressPopUpView
- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress
{
    NSString *s;
    if(progress < 0.99) {
        u_int64_t count = [self.arpscan getTotalInjectCount] - (u_int64_t)self.currentIndex;
        s = [NSString stringWithFormat:@"Left : %lu(%2d%%)", (unsigned long)count, (int)(progress*100)%100];
    }
    else {
        s = @"Reading...";
    }
    return s;
}

- (NSArray *)allStringsForProgressView:(ASProgressPopUpView *)progressView {
    NSString *s = [NSString stringWithFormat:@"Left : %u(%2d%%)", UINT32_MAX, 100];
    return @[s, @"Reading..."];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.replyList.count == 0) {
        if(self.arpscan == nil) {
            self.messageLabel.text = @"Form: N/A\nTo: N/A";
        }
        else {
            if(_scanned) {
                self.messageLabel.text = [NSString stringWithFormat:@"No ARP Reply\nFrom: %@\nTo: %@",
                                          [self.arpscan getStartIpAddress], [self.arpscan getEndIpAddress]];
            }
            else {
                self.messageLabel.text = [NSString stringWithFormat:@"From: %@\nTo: %@",
                                          [self.arpscan getStartIpAddress], [self.arpscan getEndIpAddress]];
            }
        }
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    if(section == 0)
        return 1;
    else if(section == 1)
        return self.replyList.count;
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Task Information";
    else if(section == 1) {
        if(self.scanning)
            return @"ARP Reply";
        else
            return [NSString stringWithFormat:@"ARP Reply(%lu)", (unsigned long)self.replyList.count];
    }
    
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        IJTArpScanTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Range"
                         label:cell.injectRangeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"SSID"
                         label:cell.ssidLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"BSSID"
                         label:cell.bssidLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Amount"
                         label:cell.amountLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTArpScanArpFrameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ARPFrameCell" forIndexPath:indexPath];
        
        // Configure the cell...
        NSDictionary *dict = self.replyList[indexPath.row];
        
        [IJTFormatUILabel dict:dict
                           key:@"Time"
                         label:cell.timeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"IpAddress"
                         label:cell.ipAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"MacAddress"
                         label:cell.macAddressLabel
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
