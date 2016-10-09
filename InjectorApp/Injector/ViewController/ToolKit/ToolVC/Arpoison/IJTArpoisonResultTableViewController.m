//
//  IJTArpoisonResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/6.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArpoisonResultTableViewController.h"
#import "IJTArpoisonTaskTableViewCell.h"
#import "IJTArpoisonSentTableViewCell.h"
#import "IJTArpoisonNoSentTableViewCell.h"

@interface IJTArpoisonResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *poisonButton;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) IJTArpoison *arpoison;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic) BOOL infinity;
@property (nonatomic, strong) NSMutableArray *sentArray;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic) BOOL cancle;
@property (nonatomic, strong) NSThread *arpoisonThread;
@property (nonatomic, strong) NSTimer *updateProgressViewTimer;
@property (nonatomic) BOOL poisoning;
@property (nonatomic, strong) ASProgressPopUpView *progressView;
@property (nonatomic) BOOL arpProxy;

@end

@implementation IJTArpoisonResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 75;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"arpoison";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    self.poisonButton = [[UIBarButtonItem alloc]
                         initWithImage:[UIImage imageNamed:@"arpoisonNav.png"]
                         style:UIBarButtonItemStylePlain
                         target:self action:@selector(startArpoison)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopArposion)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_poisonButton, nil];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
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
    [self.arpoison close];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setParameters {
    if(self.targetType == 0 || self.targetType == 3) {
        [self.arpoison setOneTarget:self.singleAddress];
    }
    else if(self.targetType == 1) {
        [self.arpoison setLAN];
    }
    else if(self.targetType == 2) {
        [self.arpoison setFrom:self.startIpAddress to:self.endIpAddress];
    }
    if(self.arpoison.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.",
                                          strerror(self.arpoison.errorCode)]];
        return;
    }
    
    if(self.opCode == 0) {
        [self.arpoison setArpOperation:IJTArpoisonArpOpReply];
    }
    else if(self.opCode == 1) {
        [self.arpoison setArpOperation:IJTArpoisonArpOpRequest];
    }
    [self.arpoison setSenderIpAddress:self.senderIpAddress senderMacAddress:self.senderMacAddress];
    if(self.arpoison.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.",
                                          strerror(self.arpoison.errorCode)]];
        return;
    }
    
    [self.arpoison setTwoWayEnabled:_twoWay];
    [self.arpoison readyToInject];
}

- (void)stopArposion {
    if(self.arpoisonThread || self.updateProgressViewTimer) {
        [self.stopButton setEnabled:NO];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            if(![self.arpoisonThread isFinished]) {
                self.cancle = YES;
                while(self.arpoisonThread) {
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

- (void)startArpoison {
    
    [self.dismissButton setEnabled:NO];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    self.sentArray = [[NSMutableArray alloc] init];
    self.cancle = NO;
    self.poisoning = YES;
    self.currentIndex = 0;
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
    
    [self showInfoMessage:@"Detecting ARP proxy..."];
    self.arpoisonThread = [[NSThread alloc] initWithTarget:self selector:@selector(startArpoisonThread) object:nil];
    [self.arpoisonThread start];
}

- (void)startArpoisonThread {
    
    [self.arpoison storeArpTable];
    [self setParameters];

    //detecting arp proxy. If using arp proxy, arp sender mac address is not equal to ethernet source address
    NSMutableArray *targets = [[NSMutableArray alloc] init];
    while([self.arpoison getRemainInjectCount] != 0) {
        [targets addObject:[self.arpoison getCurrentIpAddress]];
        [self.arpoison moveToNext];
    }
    
    self.arpProxy = NO;
    IJTArping *arping = [[IJTArping alloc] initWithInterface:@"en0"];
    if(!arping.errorHappened) {
        NSMutableArray *replyTargets = [[NSMutableArray alloc] init];
        NSUInteger count = 0;
        for(NSString *ipAddress in targets) {
            [arping arpingTargetIP:ipAddress
                           timeout:1000
                            target:self
                          selector:ARPING_CALLBACK_SEL
                            object:replyTargets];
            if(self.arpProxy == YES)
                break;
            if(replyTargets.count >= 5)
                break;
            if(self.cancle)
                break;
            if(++count >= 5)
                break;
            usleep(100);
        }
        
        [arping close];
    }
    
    //[self dismissShowMessage];
    if(self.arpProxy) {
        [IJTDispatch dispatch_main_after:@"Detecting ARP protection...".length*0.15+1 block:^{
            [self showWarningMessage:@"ARP protection is detected. It may not working."];
        }];
    }
    
    NSMutableArray *sentInARow = [[NSMutableArray alloc] init];
    [self setParameters];
    
    for(NSUInteger injectIndex = 0 ; injectIndex < self.injectRows || self.infinity ; injectIndex++) {
        
        if(self.cancle)
            break;
        
        //inject arp frame
        while([self.arpoison getRemainInjectCount] > 0) {
            if(self.cancle)
                break;
            
            int ret = [self.arpoison injectRegisterTarget:self
                                                 selector:ARPOISON_CALLBACK_SEL
                                                   object:sentInARow];
            
            if(ret == -1) {
                [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(self.arpoison.errorCode)]];
                if(self.arpoison.errorCode == ENOBUFS) {
                    sleep(1);
                }
                else
                    break;
            }
            else if(ret == -2) { //skip
            }
            else if(ret == 0) {
                usleep(1000);
            }
        }
        
        __block NSArray *sentInARowMainThread = [NSArray arrayWithArray:sentInARow];
        sentInARow = [[NSMutableArray alloc] init];
        [IJTDispatch dispatch_main:^{
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            
            NSString *targets = @"";
            NSString *timestamp = @"";
            [dict setValue:@(sentInARowMainThread.count) forKey:@"Amount"];
            [dict setValue:@(self.sentArray.count + 1) forKey:@"Index"];
            for(NSDictionary *sentDict in sentInARowMainThread) {
                if(sentDict == [sentInARowMainThread firstObject])
                    timestamp = [sentDict valueForKey:@"Timestamp"];
                NSString *targetIp = [sentDict valueForKey:@"TargetIpAddress"];
                NSString *targetMac = [sentDict valueForKey:@"TargetMacAddress"];
                if(targets.length <= 0) {
                    targets = [NSString stringWithFormat:@"%@ <%@>", targetIp, targetMac];
                }
                else {
                    targets =
                    [targets stringByAppendingString:
                     [NSString stringWithFormat:@"\n%@ <%@>" , targetIp, targetMac]];
                }
                
            }//end for
            
            if(sentInARowMainThread.count == 0) {
                struct timeval nowtime;
                gettimeofday(&nowtime, (struct timezone *)0);
                [dict setValue:[IJTFormatString formatTimestamp:nowtime secondsPadding:3 decimalPoint:3] forKey:@"Timestamp"];
                [dict setValue:@(NO) forKey:@"Sent"];
            }
            else {
                [dict setValue:@(YES) forKey:@"Sent"];
                [dict setValue:targets forKey:@"Targets"];
                [dict setValue:timestamp forKey:@"Timestamp"];
            }
            
            [self.sentArray addObject:dict];
            _currentIndex++;
            
            [self updateTableView];
        }];
        
        if(self.infinity) {
            injectIndex = 0;
        }
        if(self.injectRows != 1 || self.infinity) {
            [self.arpoison storeArpTable];
        }
        [self setParameters];
        usleep(_interval);
        
    }//end for
    
    self.arpoisonThread = nil;
    self.poisoning = NO;
    if(!self.infinity) {
        [self.updateProgressViewTimer invalidate];
        self.updateProgressViewTimer = nil;
    }
    [IJTDispatch dispatch_main:^{
        [self.dismissButton setEnabled:YES];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_poisonButton, nil];
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

ARPOISON_CALLBACK_METHOD {
    NSMutableArray *list = (NSMutableArray *)object;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setValue:targetIpAddress forKey:@"TargetIpAddress"];
    [dict setValue:targetMacAddress forKey:@"TargetMacAddress"];
    [dict setValue:[IJTFormatString formatTimestamp:sentTimestamp secondsPadding:3 decimalPoint:3] forKey:@"Timestamp"];
    
    [list addObject:dict];
}

ARPING_CALLBACK_METHOD {
    NSMutableArray *list = (NSMutableArray *)object;
    [list addObject:macAddress];
    if([macAddress isEqualToString:etherSourceAddress]) {
        self.arpProxy = NO;
    }
    else {
        self.arpProxy = YES;
    }
}

- (void)updateTableView {
    NSArray *addArray = @[[NSIndexPath indexPathForRow:self.sentArray.count - 1 inSection:1]];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    if(_interval >= 50000 && self.infinity) {//0.05 s
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.sentArray.count - 1 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma mark - ASProgressPopUpView dataSource

- (void)updateProgressView: (id)sender {
    float value = self.currentIndex/(float)self.injectRows;
    [self.progressView setProgress:value animated:YES];
}

// <ASProgressPopUpViewDataSource> is entirely optional
// it allows you to supply custom NSStrings to ASProgressPopUpView
- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress
{
    NSString *s;
    if(progress <= 0.0) {
        s = @"Storing ARP Entries...";
    }
    else if(progress < 0.99) {
        NSUInteger count = self.injectRows - self.currentIndex;
        s = [NSString stringWithFormat:@"Left : %lu(%2d%%)", (unsigned long)count, (int)(progress*100)%100];
    }
    else {
        s = @"Completed";
    }
    return s;
}

- (NSArray *)allStringsForProgressView:(ASProgressPopUpView *)progressView {
    NSString *s = [NSString stringWithFormat:@"Left : %u(%2d%%)", UINT32_MAX, 100];
    return @[@"Storing ARP Entries...", s, @"Completed"];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"arpoison"];
        [self.poisonButton setEnabled:NO];
        [self stopArposion];
        if(self.arpoison != nil) {
            [self.arpoison close];
            self.arpoison = nil;
        }
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.poisonButton setEnabled:YES];
        
        if(self.arpoison == nil) {
            self.arpoison = [[IJTArpoison alloc] initWithInterface:@"en0"];
            if(self.arpoison.errorHappened) {
                [self showErrorMessage:[NSString stringWithFormat:@"%s.",
                                                  strerror(self.arpoison.errorCode)]];
            }
            else {
                [self setParameters];
            }
        }
    }
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    NSString *amount = nil;
    NSString *target = nil;
    NSString *operation = nil;
    if(self.injectRows == 0) {
        amount = @"Infinity";
        self.infinity = YES;
    }
    else {
        amount = [NSString stringWithFormat:@"%lu", (unsigned long)self.injectRows];
        self.infinity = NO;
    }
    
    if(self.injectRows == 1) {
        self.interval = 1;
    }
    
    if(self.targetType == 0 || self.targetType == 3) {
        target = self.singleAddress;
    }
    else if(self.targetType == 1) {
        if(self.arpoison == nil)
            target = @"N/A";
        else {
            target = [NSString stringWithFormat:@"%@ - %@",
                      [self.arpoison getStartIpAddress], [self.arpoison getEndIpAddress]];
        }
    }
    else if(self.targetType == 2) {
        target = [NSString stringWithFormat:@"%@ - %@",
                  self.startIpAddress, self.endIpAddress];
    }
    
    if(self.opCode == 0) {
        operation = @"Reply";
    }
    else
        operation = @"Request";
    
    [self.taskInfoDict setValue:amount forKey:@"Amount"];
    [self.taskInfoDict setValue:[ALNetwork SSID] forKey:@"SSID"];
    [self.taskInfoDict setValue:[ALNetwork BSSID] forKey:@"BSSID"];
    [self.taskInfoDict setValue:target forKey:@"Target"];
    [self.taskInfoDict setValue:self.senderIpAddress forKey:@"SenderIP"];
    [self.taskInfoDict setValue:self.senderMacAddress forKey:@"SenderMAC"];
    [self.taskInfoDict setValue:operation forKey:@"Operation"];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Sender : %@(%@)\nTarget : %@\nOperation : %@",
                              self.senderIpAddress, self.senderMacAddress, target, operation];
    
    [IJTDispatch dispatch_main:^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.sentArray.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    if(section == 0)
        return 1;
    else if(section == 1)
        return self.sentArray.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTArpoisonTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
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
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"SenderIP"
                         label:cell.senderIpAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"SenderMAC"
                         label:cell.sendMacAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Operation"
                         label:cell.operationLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        
        NSDictionary *dict = self.sentArray[indexPath.row];
        NSNumber *sent = [dict valueForKey:@"Sent"];
        if([sent boolValue]) {
            IJTArpoisonSentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SentCell" forIndexPath:indexPath];
            [IJTFormatUILabel dict:dict
                               key:@"Index"
                             label:cell.indexLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"Amount"
                             label:cell.amountLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"Timestamp"
                             label:cell.timeLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"Targets"
                             label:cell.targetLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
                label.font = [UIFont systemFontOfSize:11];
            }];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else {
            IJTArpoisonNoSentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotSentCell" forIndexPath:indexPath];
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
            
            cell.notSentLabel.font = [UIFont systemFontOfSize:17];
            cell.notSentLabel.textColor = IJTValueColor;
            
            [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
                label.font = [UIFont systemFontOfSize:11];
            }];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Task Information";
    else if(section == 1) {
        if(self.poisoning)
            return @"Sent Rows";
        else {
            return [NSString stringWithFormat:@"Sent Rows(%lu)", (unsigned long)self.sentArray.count];
        }
    }
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
