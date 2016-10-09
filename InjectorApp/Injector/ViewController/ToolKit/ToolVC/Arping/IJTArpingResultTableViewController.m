//
//  IJTArpingResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArpingResultTableViewController.h"
#import "IJTArpingTaskTableViewCell.h"
#import "IJTArpingArpFrameTableViewCell.h"
#import "IJTArpingTimeoutTableViewCell.h"

@interface IJTArpingResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *arpingButton;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;

@property (nonatomic, strong) IJTArping *arping;

@property (nonatomic, strong) NSMutableArray *replyArray;
@property (nonatomic, strong) NSThread *arpingThread;
@property (nonatomic, strong) NSTimer *updateProgressViewTimer;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic, strong) ASProgressPopUpView *progressView;
@property (nonatomic) BOOL cancle;
@property (nonatomic) BOOL arpinging;
@property (nonatomic) BOOL infinity;

@end

@implementation IJTArpingResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 74;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"arping";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.arpingButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"arpingNav.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(startArping)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopArping)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_arpingButton, nil];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Target : %@", self.targetIpAddress];
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
    [self.arping close];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)startArping {
    self.cancle = NO;
    self.arpinging = YES;
    [self.dismissButton setEnabled:NO];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    self.replyArray = [[NSMutableArray alloc] init];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    
    //add progress
    if(!self.infinity) {
        self.progressView = [IJTProgressView baseProgressPopUpView];
        self.progressView.dataSource = self;
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:
                                          CGRectMake(0, 0, SCREEN_WIDTH, CGRectGetHeight(_progressView.frame))];
        [self.tableView setContentOffset:CGPointMake(0, -60) animated:YES];
        [self.tableView.tableHeaderView addSubview:self.progressView];
        self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(60, 0, 0, 0);
        self.updateProgressViewTimer =
        [NSTimer scheduledTimerWithTimeInterval:0.05
                                         target:self
                                       selector:@selector(updateProgressView:)
                                       userInfo:nil repeats:YES];
        [self.tableView setUserInteractionEnabled:NO];
    }
    
    self.arpingThread = [[NSThread alloc] initWithTarget:self selector:@selector(startArpingThread) object:nil];
    [self.arpingThread start];
}

- (void)startArpingThread {

    for(_currentIndex = 0 ; _currentIndex < self.amount || self.infinity ; _currentIndex++) {
        if(self.cancle)
            break;
        int ret =
        [self.arping arpingTargetIP:_targetIpAddress
                            timeout:_timeout
                             target:self
                           selector:ARPING_CALLBACK_SEL
                             object:_replyArray];
        
        if(ret == -1) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(self.arping.errorCode)]];
            break;
        }
        else if(ret == 1) {
            [IJTDispatch dispatch_main:^{ //timeout
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                
                struct timeval timestamp;
                gettimeofday(&timestamp, (struct timezone *)0);
                
                [dict setValue:@(YES) forKey:@"Timeout"];
                [dict setValue:@(self.replyArray.count + 1) forKey:@"Index"];
                [dict setValue:[IJTFormatString formatTimestamp:timestamp secondsPadding:3 decimalPoint:3] forKey:@"Timestamp"];
                
                [self.replyArray addObject:dict];
                
                [self updateTableView];
            }];
        }
        usleep(_interval);
    }
    
    self.arpingThread = nil;
    self.arpinging = NO;
    
    if(!self.infinity) {
        [self.updateProgressViewTimer invalidate];
        self.updateProgressViewTimer = nil;
    }
    
    [IJTDispatch dispatch_main:^{
        [self.dismissButton setEnabled:YES];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_arpingButton, nil];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        
        //remove progress
        if(!self.infinity) {
            [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
            [self.tableView setUserInteractionEnabled:YES];
            [self.progressView removeFromSuperview];
            
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
            }];
        }
    }];
}

ARPING_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = (NSMutableArray *)object;
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        [dict setValue:[IJTFormatString formatTimestamp:rt secondsPadding:3 decimalPoint:3] forKey:@"Timestamp"];
        [dict setValue:[NSString stringWithFormat:@"%4.2f ms", RTT] forKey:@"RTT"];
        [dict setValue:ipAddress forKey:@"IpAddress"];
        [dict setValue:macAddress forKey:@"MacAddress"];
        [dict setValue:@(NO) forKey:@"Timeout"];
        [dict setValue:@(self.replyArray.count + 1) forKey:@"Index"];
        
        [list addObject:dict];
        
        [self updateTableView];
    }];
}

- (void)updateTableView {
    NSArray *addArray = @[[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1]];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    if(_interval >= 50000 && self.infinity) {//0.05 s
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)stopArping {
    if(self.arpingThread || self.updateProgressViewTimer) {
        [self.stopButton setEnabled:NO];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            if(![self.arpingThread isFinished]) {
                self.cancle = YES;
                while(self.arpingThread) {
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
}

#pragma mark - ASProgressPopUpView dataSource

- (void)updateProgressView: (id)sender {
    float value = self.currentIndex/(float)self.amount;
    [self.progressView setProgress:value animated:YES];
}

// <ASProgressPopUpViewDataSource> is entirely optional
// it allows you to supply custom NSStrings to ASProgressPopUpView
- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress
{
    NSString *s;
    if(progress < 0.99) {
        NSUInteger count = self.amount - self.currentIndex;
        s = [NSString stringWithFormat:@"Left : %lu(%2d%%)", (unsigned long)count, (int)(progress*100)%100];
    }
    else {
        s = @"Completed";
    }
    return s;
}

- (NSArray *)allStringsForProgressView:(ASProgressPopUpView *)progressView {
    NSString *s = [NSString stringWithFormat:@"Left : %u(%2d%%)", UINT32_MAX, 100];
    return @[s, @"Completed"];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"arping"];
        [self.arpingButton setEnabled:NO];
        [self stopArping];
        if(self.arping != nil) {
            [self.arping close];
            self.arping = nil;
        }
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.arpingButton setEnabled:YES];
        
        if(self.arping == nil) {
            self.arping = [[IJTArping alloc] initWithInterface:@"en0"];
            if(self.arping.errorHappened) {
                [self showErrorMessage:[NSString stringWithFormat:@"%s.",
                                                  strerror(self.arping.errorCode)]];
            }
        }
    }
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    NSString *amount = nil;
    if(self.amount == 0) {
        amount = @"Infinity";
        self.infinity = YES;
    }
    else {
        amount = [NSString stringWithFormat:@"%lu", (unsigned long)self.amount];
        self.infinity = NO;
    }
    if(self.amount == 1) {
        self.interval = 1;
    }
    
    [self.taskInfoDict setValue:amount forKey:@"Amount"];
    [self.taskInfoDict setValue:[ALNetwork SSID] forKey:@"SSID"];
    [self.taskInfoDict setValue:[ALNetwork BSSID] forKey:@"BSSID"];
    [self.taskInfoDict setValue:self.targetIpAddress forKey:@"Target"];
    
    [IJTDispatch dispatch_main:^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    if(self.replyArray.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    
    if(section == 0)
        return 1;
    else
        return self.replyArray.count;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Task Information";
    else if(section == 1) {
        if(self.arpinging)
            return @"ARP Reply";
        else
            return [NSString stringWithFormat:@"ARP Reply(%lu)", (unsigned long)self.replyArray.count];
    }
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        IJTArpingTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Amount"
                         label:cell.amountLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Target"
                         label:cell.targetLabel
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
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        NSDictionary *dict = self.replyArray[indexPath.row];
        NSNumber *timeout = [dict valueForKey:@"Timeout"];
        
        if([timeout boolValue]) {
            IJTArpingTimeoutTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeoutCell" forIndexPath:indexPath];
            
            [IJTFormatUILabel dict:dict
                               key:@"Index"
                             label:cell.indexLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"Timestamp"
                             label:cell.timeLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            cell.timeoutLabel.font = [UIFont systemFontOfSize:17];
            cell.timeoutLabel.textColor = IJTValueColor;
            [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
                label.font = [UIFont systemFontOfSize:11];
            }];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else {
            IJTArpingArpFrameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ARPFrameCell" forIndexPath:indexPath];
            
            [IJTFormatUILabel dict:dict
                               key:@"Index"
                             label:cell.indexLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"Timestamp"
                             label:cell.timeLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"RTT"
                             label:cell.rttLabel
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
    }
    
    return nil;
}

@end
