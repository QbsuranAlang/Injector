//
//  IJTNetbiosResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/14.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTNetbiosResultTableViewController.h"
#import "IJTNetbiosTaskTableViewCell.h"
#import "IJTNetbiosResponseTableViewCell.h"

@interface IJTNetbiosResultTableViewController ()

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) UIBarButtonItem *queryButton;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic, strong) NSMutableArray *replyArray;
@property (nonatomic, strong) IJTNetbios *netbios;
@property (nonatomic, strong) NSThread *requestThread;
@property (nonatomic, strong) NSTimer *updateProgressViewTimer;
@property (nonatomic) BOOL cancle;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic, strong) ASProgressPopUpView *progressView;

@end

@implementation IJTNetbiosResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 76;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"NetBIOS";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.queryButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"NetBIOSNav.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(query)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopQuery)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_queryButton, nil];
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
    [self.netbios close];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)stopQuery {
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

- (void)query {
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    self.replyArray = [[NSMutableArray alloc] init];
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    [self.dismissButton setEnabled:NO];
    self.messageLabel.text = @"Querying...";
    self.cancle = NO;
    self.requestThread = [[NSThread alloc] initWithTarget:self selector:@selector(queryThread) object:nil];
    
    if(self.selectedIndex == 0) {
        [self.netbios setOneTarget:self.singleIpAddress];
        self.interval = 1;
        
        [self.requestThread start];
    }
    else if(self.selectedIndex == 1) {
        [self.netbios setLAN];
        self.messageLabel.text = [NSString stringWithFormat:@"From: %@\nTo: %@",
                                  [self.netbios getStartIpAddress], [self.netbios getEndIpAddress]];
        
        self.progressView = [IJTProgressView baseProgressPopUpView];
        self.progressView.dataSource = self;
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:
                                          CGRectMake(0, 0, SCREEN_WIDTH, CGRectGetHeight(_progressView.frame))];
        [self.tableView setContentOffset:CGPointMake(0, -60) animated:YES];
        [self.tableView.tableHeaderView addSubview:self.progressView];
        [self.tableView setUserInteractionEnabled:NO];
        
        
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(60, 0, 0, 0);
            self.updateProgressViewTimer =
            [NSTimer scheduledTimerWithTimeInterval:0.05
                                             target:self
                                           selector:@selector(updateProgressView:)
                                           userInfo:nil repeats:YES];
            
            [self.requestThread start];
        }];
    }
}

- (void)queryThread {
    u_int64_t amount = [self.netbios getTotalInjectCount];
    for(_currentIndex = 0 ; _currentIndex < amount ; _currentIndex++) {
        if(self.cancle)
            break;
        int ret =
        [self.netbios injectWithInterval:_interval];
        
        if(ret == -1) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(self.netbios.errorCode)]];
            if(self.netbios.errorCode == ENOBUFS) {
                sleep(1);
            }
            else
                break;
        }
    }
    
    [self.netbios readTimeout:_timeout
                       target:self
                     selector:NETBIOS_CALLBACK_SEL
                       object:_replyArray];
    
    if(self.netbios.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(self.netbios.errorCode)]];
    }
    
    
    if(self.selectedIndex == 1) {
        [self.updateProgressViewTimer invalidate];
        self.updateProgressViewTimer = nil;
    }
    
    [IJTDispatch dispatch_main:^{
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_queryButton, nil];
        [self.dismissButton setEnabled:YES];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if(self.replyArray.count == 0) {
            self.messageLabel.text = @"No Answer";
        }
        
        if(self.selectedIndex == 1) {
            [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
            [self.tableView setUserInteractionEnabled:YES];
            [self.progressView removeFromSuperview];
            
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
            }];
        }
    }];
    
    self.requestThread = nil;
}

NETBIOS_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = (NSMutableArray *)object;
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSString *nameString = @"";
        
        for(NSString *name in netbiosNames) {
            if(nameString.length <= 0) {
                nameString = [NSString stringWithString:name];
            }
            else {
                nameString = [nameString stringByAppendingString:[NSString stringWithFormat:@"\n%@", name]];
            }
        }//end for
        
        NSString *groupString = @"";
        for(NSString *name in groupNames) {
            if(groupString.length <= 0) {
                groupString = [NSString stringWithString:name];
            }
            else {
                groupString = [groupString stringByAppendingString:[NSString stringWithFormat:@"\n%@", name]];
            }
        }//end for
        
        [dict setValue:nameString forKey:@"Names"];
        [dict setValue:groupString forKey:@"Group"];
        [dict setValue:unitID forKey:@"UnitID"];
        [dict setValue:sourceIpAddress forKey:@"Source"];
        
        [list addObject:dict];
        
        NSArray *addArray = @[[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1]];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        if(_interval >= 50000) {//0.05 s
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

#pragma mark - ASProgressPopUpView dataSource

- (void)updateProgressView: (id)sender {
    float value = self.currentIndex/(float)[self.netbios getTotalInjectCount];
    [self.progressView setProgress:value animated:YES];
}

// <ASProgressPopUpViewDataSource> is entirely optional
// it allows you to supply custom NSStrings to ASProgressPopUpView
- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress
{
    NSString *s;
    if(progress < 0.99) {
        u_int64_t count = [self.netbios getTotalInjectCount] - (u_int64_t)self.currentIndex;
        s = [NSString stringWithFormat:@"Left : %lu(%2d%%)", (unsigned long)count, (int)(progress*100)%100];
    }
    else {
        s = @"Reading...";
    }
    return s;
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        if(self.selectedIndex == 1) {
            [self showWarningMessage:@"Now select LAN as target, but there is no Wi-Fi connection."];
            [self.queryButton setEnabled:NO];
        }
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.queryButton setEnabled:YES];
    }
    
    self.netbios = [[IJTNetbios alloc] init];
    
    NSString *target = @"";
    
    if(self.selectedIndex == 0) {
        [self.netbios setOneTarget:self.singleIpAddress];
        target = self.singleIpAddress;
        self.messageLabel.text = [NSString stringWithFormat:@"Target : %@", self.singleIpAddress];
    }
    else if(self.selectedIndex == 1) {
        [self.netbios setLAN];
        self.messageLabel.text = [NSString stringWithFormat:@"From: %@\nTo: %@",
                                  [self.netbios getStartIpAddress], [self.netbios getEndIpAddress]];
        target = [NSString stringWithFormat:@"%@ - %@",
                  [self.netbios getStartIpAddress], [self.netbios getEndIpAddress]];
    }
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:target forKey:@"Target"];
    
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
        IJTNetbiosTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Target"
                         label:cell.targetLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTNetbiosResponseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ResponseCell" forIndexPath:indexPath];
        
        NSDictionary *dict = self.replyArray[indexPath.row];
        
        [IJTFormatUILabel dict:dict
                           key:@"Names"
                         label:cell.namesLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"UnitID"
                         label:cell.unitIDLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Source"
                         label:cell.sourceLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Group"
                         label:cell.groupLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        cell.indexLabel.text = [NSString stringWithFormat:@"%ld", (long)(indexPath.row + 1)];
        cell.indexLabel.font = [UIFont systemFontOfSize:11];
        cell.indexLabel.textColor = IJTValueColor;
        
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
    if(section == 0) {
        return @"Task Information";
    }
    else if(section == 1) {
        return [NSString stringWithFormat:@"Answer(%lu)", (unsigned long)self.replyArray.count];
    }
    return @"";
}

@end
