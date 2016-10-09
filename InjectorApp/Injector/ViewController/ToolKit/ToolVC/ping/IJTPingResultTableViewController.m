//
//  IJTPingResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/21.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTPingResultTableViewController.h"
#import "IJTPingTaskTableViewCell.h"
#import "IJTPingReplyTableViewCell.h"
#import "IJTPingTimeoutTableViewCell.h"
#import "IJTPingFakeTableViewCell.h"
@interface IJTPingResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *pingButton;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic, strong) NSMutableArray *replyArray;
@property (nonatomic, strong) NSThread *requestThread;
@property (nonatomic, strong) NSTimer *updateProgressViewTimer;
@property (nonatomic) BOOL cancle;
@property (nonatomic) BOOL infinity;
@property (nonatomic) BOOL pinging;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic, strong) ASProgressPopUpView *progressView;

@end

@implementation IJTPingResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 66;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"ping";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.pingButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"pingNav.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(startPing)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopPing)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_pingButton, nil];
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:self.targetIpAddress forKey:@"Target"];
    [self.taskInfoDict setValue:self.sourceIpAddress forKey:@"Source"];
    [self.taskInfoDict setValue:self.fragment ? @"Yes" : @"No" forKey:@"Fragment"];
    [self.taskInfoDict setValue:[IJTFormatString formatIpTypeOfSerivce:self.tos] forKey:@"ToS"];
    [self.taskInfoDict setValue:@(self.ttl) forKey:@"TTL"];
    [self.taskInfoDict setValue:[IJTFormatString formatBytes:self.payloadSize carry:NO] forKey:@"PayloadSize"];
    [self.taskInfoDict setValue:self.amount == 0 ? @"Infinity" : @(self.amount) forKey:@"Amount"];
    self.infinity = (self.amount == 0 ? YES : NO);
    
    self.messageLabel.text = [NSString stringWithFormat:@"Target : %@\nSource : %@", self.targetIpAddress, self.sourceIpAddress];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)stopPing {
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

- (void)startPing {
    
    self.pinging = YES;
    self.cancle = NO;
    [self.dismissButton setEnabled:NO];
    self.replyArray = [[NSMutableArray alloc] init];
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
    
    self.requestThread = [[NSThread alloc] initWithTarget:self selector:@selector(pingThread) object:nil];
    [self.requestThread start];
}

- (void)pingThread {
    IJTPing *ping = [[IJTPing alloc] init];
    NSString *wifiIpAddress = nil;
    NSString *cellIpAddress = nil;
    BOOL fakeme = NO;
    int ret;
    
    if(ping.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(ping.errorCode)]];
        goto DONE;
    }
    
    ret = [ping setTarget:self.targetIpAddress];
    if(ret == -2) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", hstrerror(ping.errorCode)]];
        goto DONE;
    }
    
    if([IJTNetowrkStatus supportWifi] && [IJTNetowrkStatus wifiReachability].currentReachabilityStatus != NotReachable) {
        wifiIpAddress = [IJTNetowrkStatus currentIPAddress:@"en0"];
    }
    if([IJTNetowrkStatus supportCellular] && [IJTNetowrkStatus cellReachability].currentReachabilityStatus != NotReachable) {
        cellIpAddress = [IJTNetowrkStatus currentIPAddress:@"pdp_ip0"];
    }
    
    
    if([wifiIpAddress isEqualToString:_sourceIpAddress] || [cellIpAddress isEqualToString:_sourceIpAddress])
        fakeme = NO;
    else
        fakeme = YES;
    
    for(_currentIndex = 0 ; _currentIndex < self.amount || self.infinity ; _currentIndex++) {
        
        if(self.cancle)
            break;
        
        ret = [ping pingWithTtl:self.ttl
                            tos:self.tos
                       fragment:self.fragment
                        timeout:self.timeout
                       sourceIP:_sourceIpAddress
                           fake:fakeme
                    recordRoute:NO
                    payloadSize:self.payloadSize
                         target:self
                       selector:PING_CALLBACK_SEL
                         object:_replyArray
                   recordTarget:nil
                 recordSelector:nil
                   recordObject:nil];
        
        if(ret == -1) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(ping.errorCode)]];
            if(ping.errorCode != ENOBUFS)
                goto DONE;
            else
                sleep(1);
        }
        else if(ret == 1) {
            [IJTDispatch dispatch_main:^{
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                struct timeval timestamp;
                gettimeofday(&timestamp, (struct timezone *)0);
                
                [dict setValue:@(YES) forKey:@"Timeout"];
                [dict setValue:@(NO) forKey:@"Fake"];
                [dict setValue:@(self.replyArray.count + 1) forKey:@"Index"];
                [dict setValue:[IJTFormatString formatTimestamp:timestamp secondsPadding:3 decimalPoint:3] forKey:@"Timestamp"];
                
                [_replyArray addObject:dict];
                [self updateTableView];
            }];
        }
        else if(ret == 2) {
            [IJTDispatch dispatch_main:^{
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                struct timeval timestamp;
                gettimeofday(&timestamp, (struct timezone *)0);
                
                [dict setValue:@(YES) forKey:@"Fake"];
                [dict setValue:@(self.replyArray.count + 1) forKey:@"Index"];
                [dict setValue:[IJTFormatString formatTimestamp:timestamp secondsPadding:3 decimalPoint:3] forKey:@"Timestamp"];
                
                [_replyArray addObject:dict];
                [self updateTableView];
            }];
        }
        usleep(_interval);
    }
    
DONE:
    self.pinging = NO;
    
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
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.pingButton, nil];
        
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
    [ping close];
    self.requestThread = nil;
}

PING_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = (NSMutableArray *)object;
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        NSString *timestamp = [IJTFormatString formatTimestamp:rt secondsPadding:3 decimalPoint:3];
        
        [dict setValue:@(self.replyArray.count + 1) forKey:@"Index"];
        [dict setValue:timestamp forKey:@"Timestamp"];
        [dict setValue:replyIpAddress forKey:@"ReplyIpAddress"];
        [dict setValue:[NSString stringWithFormat:@"%4.2f ms", rtt] forKey:@"RTT"];
        [dict setValue:@(type) forKey:@"Type"];
        [dict setValue:@(code) forKey:@"Code"];
        [dict setValue:[IJTFormatString formatBytes:recvlength carry:NO] forKey:@"Length"];
        [dict setValue:[IJTFormatString formatIcmpCode:code type:type] forKey:@"Info"];
        [dict setValue:@(NO) forKey:@"Timeout"];
        [dict setValue:@(NO) forKey:@"Fake"];
        
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

#pragma mark - Table view data source

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
    else if(section == 1) {
        return self.replyArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTPingTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Target"
                         label:cell.targetLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Source"
                         label:cell.sourceLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Fragment"
                         label:cell.fragmentLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"ToS"
                         label:cell.tosLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"TTL"
                         label:cell.ttlLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"PayloadSize"
                         label:cell.payloadSizeLabel
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
        NSDictionary *dict = self.replyArray[indexPath.row];
        NSNumber *timeout = [dict valueForKey:@"Timeout"];
        NSNumber *fake = [dict valueForKey:@"Fake"];
        
        if([fake boolValue]) {
            IJTPingFakeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FakeCell" forIndexPath:indexPath];
            
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
            
            cell.spoofLabel.font = [UIFont systemFontOfSize:17];
            cell.spoofLabel.textColor = IJTValueColor;
            
            [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
                label.font = [UIFont systemFontOfSize:11];
            }];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else {
            if([timeout boolValue]) {
                IJTPingTimeoutTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimeoutCell" forIndexPath:indexPath];
                
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
                IJTPingReplyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReplyCell" forIndexPath:indexPath];
                
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
                                   key:@"ReplyIpAddress"
                                 label:cell.replyLabel
                                 color:IJTValueColor
                                  font:[UIFont systemFontOfSize:11]];
                
                [IJTFormatUILabel dict:dict
                                   key:@"Type"
                                 label:cell.typeLabel
                                 color:IJTValueColor
                                  font:[UIFont systemFontOfSize:11]];
                
                [IJTFormatUILabel dict:dict
                                   key:@"Code"
                                 label:cell.codeLabel
                                 color:IJTValueColor
                                  font:[UIFont systemFontOfSize:11]];
                
                [IJTFormatUILabel dict:dict
                                   key:@"Info"
                                 label:cell.infoLabel
                                 color:IJTValueColor
                                  font:[UIFont systemFontOfSize:11]];
                
                [IJTFormatUILabel dict:dict
                                   key:@"Length"
                                 label:cell.lengthLabel
                                 color:IJTValueColor
                                  font:[UIFont systemFontOfSize:11]];
                
                [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
                    label.font = [UIFont systemFontOfSize:11];
                }];
                
                [cell layoutIfNeeded];
                return cell;
            }
        }
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
        if(self.fakeMe) {
            if(self.pinging)
                return @"Sent";
            else
                return [NSString stringWithFormat:@"Sent(%lu)", (unsigned long)self.replyArray.count];
        }
        else {
            if(self.pinging)
                return @"Reply";
            else
                return [NSString stringWithFormat:@"Reply(%lu)", (unsigned long)self.replyArray.count];
        }
        
    }
    return @"";
}

@end
