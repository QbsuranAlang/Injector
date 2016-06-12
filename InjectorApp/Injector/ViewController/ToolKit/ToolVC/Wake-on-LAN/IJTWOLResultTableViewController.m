//
//  IJTWOLResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWOLResultTableViewController.h"
#import "IJTWOLLANTaskTableViewCell.h"
#import "IJTWOLWANTaskTableViewCell.h"
#import "IJTWOLSentTableViewCell.h"

@interface IJTWOLResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *wakeupButton;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic, strong) NSMutableArray *sentArray;
@property (nonatomic) BOOL cancle;
@property (nonatomic) BOOL infinity;
@property (nonatomic) BOOL waking;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) NSThread *requestThread;
@property (nonatomic, strong) NSTimer *updateProgressViewTimer;
@property (nonatomic, strong) ASProgressPopUpView *progressView;

@end

@implementation IJTWOLResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 76;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"Wake-on-LAN";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.wakeupButton = [[UIBarButtonItem alloc]
                         initWithImage:[UIImage imageNamed:@"Wake-on-LANNav.png"]
                         style:UIBarButtonItemStylePlain
                         target:self action:@selector(startWakeup)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopWakeup)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_wakeupButton, nil];
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:self.targetMacAddress forKey:@"TargetMacAddress"];
    [self.taskInfoDict setValue:self.targetIpAddress forKey:@"TargetIpAddress"];
    [self.taskInfoDict setValue:@(self.targetPortNumber) forKey:@"TargetPortNumber"];
    [self.taskInfoDict setValue:self.amount == 0 ? @"Infinity" : @(self.amount) forKey:@"Amount"];
    
    self.infinity = (self.amount == 0 ? YES : NO);
    
    if(self.selectedIndex == 0) {
        self.messageLabel.text = [NSString stringWithFormat:@"Target : %@", self.targetMacAddress];
    }
    else if(self.selectedIndex == 1) {
        self.messageLabel.font = [UIFont boldFlatFontOfSize:20];
        self.messageLabel.text = [NSString stringWithFormat:@"Target : %@(%@)\nPort : %d", self.targetIpAddress, self.targetMacAddress, self.targetPortNumber];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(self.selectedIndex == 0) {
        [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
        if([IJTNetowrkStatus supportWifi]) {
            self.wifiReachability = [IJTNetowrkStatus wifiReachability];
            [self.wifiReachability startNotifier];
            [self reachabilityChanged:nil];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(self.selectedIndex == 0) {
        [IJTNotificationObserver reachabilityRemoveObserver:self];
        if([IJTNetowrkStatus supportWifi])
            [self.wifiReachability stopNotifier];
    }
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)stopWakeup {
    if(self.requestThread || self.updateProgressViewTimer) {
        [self.stopButton setEnabled:NO];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            if(![self.requestThread isFinished]) {
                self.cancle = YES;
                while(self.requestThread) {
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

- (void)startWakeup {
    self.waking = YES;
    self.cancle = NO;
    [self.dismissButton setEnabled:NO];
    self.sentArray = [[NSMutableArray alloc] init];
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    
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
    
    self.requestThread = [[NSThread alloc] initWithTarget:self selector:@selector(wakeupThread) object:nil];
    [self.requestThread start];
}

- (void)wakeupThread {
    IJTWOL *wake = [[IJTWOL alloc] init];
    int ret = 0;
    
    if(wake.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(wake.errorCode)]];
        goto DONE;
    }
    
    for(_currentIndex = 0 ; _currentIndex < self.amount || self.infinity ; _currentIndex++) {
        
        if(self.cancle)
            break;
        
        __block NSMutableArray *sentInARow = [[NSMutableArray alloc] init];
        if(self.selectedIndex == 0) {
            ret = [wake wakeUpMacAddress:_targetMacAddress
                                  target:self
                                selector:WOL_CALLBACK_SEL
                                  object:sentInARow];
        }
        else if(self.selectedIndex == 1) {
            ret = [wake wakeUpIpAddress:_targetIpAddress
                             macAddress:_targetMacAddress
                                   port:_targetPortNumber
                                 target:self
                               selector:WOL_CALLBACK_SEL
                                 object:sentInARow];
        }
        
        if(ret == -1) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(wake.errorCode)]];
            if(wake.errorCode != ENOBUFS)
                goto DONE;
            else
                sleep(1);
        }
        else if(ret == 0) {
            [IJTDispatch dispatch_main:^{
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                NSString *addresses = @"";
                for(NSString *address in sentInARow) {
                    if(addresses.length <= 0) {
                        addresses = [NSString stringWithString:address];
                    }
                    else {
                        addresses = [addresses stringByAppendingString:[NSString stringWithFormat:@"\n%@", address]];
                    }
                }
                
                struct timeval sentTime;
                gettimeofday(&sentTime, (struct timezone *)0);
                
                [dict setValue:@(self.sentArray.count + 1) forKey:@"Index"];
                [dict setValue:self.targetMacAddress forKey:@"MacAddress"];
                [dict setValue:addresses forKey:@"DestinationAddress"];
                [dict setValue:[IJTFormatString formatTimestamp:sentTime secondsPadding:3 decimalPoint:3] forKey:@"Timestamp"];
                
                [self.sentArray addObject:dict];
                
                NSArray *addArray = @[[NSIndexPath indexPathForRow:self.sentArray.count - 1 inSection:1]];
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
                if(_interval >= 50000 && self.infinity) {//0.05 s
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.sentArray.count - 1 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                }
            
            }];
        }
        usleep(_interval);
    }
    
    
DONE:
    self.waking = NO;
    
    if(!self.infinity) {
        [self.updateProgressViewTimer invalidate];
        self.updateProgressViewTimer = nil;
    }
    
    [IJTDispatch dispatch_main:^{
        [self.dismissButton setEnabled:YES];
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.wakeupButton, nil];
        
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
    [wake close];
    self.requestThread = nil;
}

WOL_CALLBACK_METHOD {
    NSMutableArray *names = (NSMutableArray *)object;
    [names addObject:destinationAddress];
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

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWarningMessage:@"Now select LAN as target, but there is no Wi-Fi connection."];
        [self.wakeupButton setEnabled:NO];
        [self stopWakeup];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.wakeupButton setEnabled:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.sentArray.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    
    if(section == 0)
        return 1;
    else if(section == 1) {
        return self.sentArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        if(self.selectedIndex == 0) {
            IJTWOLLANTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LANTaskCell" forIndexPath:indexPath];
            
            [IJTFormatUILabel dict:_taskInfoDict
                               key:@"TargetMacAddress"
                             label:cell.targetMacAddressLabel
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
        else if(self.selectedIndex == 1) {
            IJTWOLWANTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WANTaskCell" forIndexPath:indexPath];
            
            [IJTFormatUILabel dict:_taskInfoDict
                               key:@"TargetMacAddress"
                             label:cell.targetMacAddressLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:_taskInfoDict
                               key:@"TargetIpAddress"
                             label:cell.targetIpAddressLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:_taskInfoDict
                               key:@"TargetPortNumber"
                             label:cell.targetPortNumberLabel
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
    }
    else if(indexPath.section == 1) {
        IJTWOLSentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SentCell" forIndexPath:indexPath];
        NSDictionary *dict = self.sentArray[indexPath.row];
        
        [IJTFormatUILabel dict:dict
                           key:@"Index"
                         label:cell.indexLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"MacAddress"
                         label:cell.macAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"DestinationAddress"
                         label:cell.destinationAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Timestamp"
                         label:cell.timeLabel
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Task Information";
    else if(section == 1) {
        if(self.waking)
            return @"Sent";
        else
            return [NSString stringWithFormat:@"Sent(%lu)", (unsigned long)self.sentArray.count];
    }
    return @"";
}

@end
