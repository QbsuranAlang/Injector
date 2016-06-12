//
//  IJTTCPFloodingResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/8.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTTCPFloodingResultTableViewController.h"
#import "IJTTCPFloodingTaskTableViewCell.h"
#import "IJTTCPFloodingSentTableViewCell.h"
@interface IJTTCPFloodingResultTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic, strong) NSMutableArray *sentArray;
@property (nonatomic) BOOL infinity;
@property (nonatomic) BOOL flooding;
@property (nonatomic, strong) NSThread *requestThread;
@property (nonatomic, strong) NSTimer *updateProgressViewTimer;
@property (nonatomic, strong) ASProgressPopUpView *progressView;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic) BOOL cancle;
@property (nonatomic, strong) UIBarButtonItem *floodingButton;

@end

@implementation IJTTCPFloodingResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 61;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"SYN Flood";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.floodingButton = [[UIBarButtonItem alloc]
                           initWithImage:[UIImage imageNamed:@"SYN FloodNav.png"]
                           style:UIBarButtonItemStylePlain
                           target:self action:@selector(startFlooding)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_floodingButton, nil];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopFlooding)];
    
    self.infinity = self.amount == 0 ? YES : NO;
    self.interval = self.amount == 1 ? 1 : self.interval;
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:self.amount == 0 ? @"Infinity" : @(self.amount) forKey:@"Amount"];
    [self.taskInfoDict setValue:self.targetIpAddress forKey:@"Target"];
    [self.taskInfoDict setValue:@(self.targetPort) forKey:@"TargetPort"];
    [self.taskInfoDict setValue:self.sourceIpAddress == nil ? @"Randomization" : self.sourceIpAddress forKey:@"Source"];
    [self.taskInfoDict setValue:self.sourcePort == 0 ? @"Randomization" : @(self.sourcePort) forKey:@"SourcePort"];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Target : %@:%d", self.targetIpAddress, self.targetPort];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)stopFlooding {
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

- (void)startFlooding {
    self.flooding = YES;
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
    
    self.requestThread = [[NSThread alloc] initWithTarget:self selector:@selector(floodingThread) object:nil];
    [self.requestThread start];
}

- (void)floodingThread {
    IJTTCP_Flooding *flooding = [[IJTTCP_Flooding alloc] init];
    int ret;
    if(flooding.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(flooding.errorCode)]];
        goto DONE;
    }
    
    ret =
    [flooding setTarget:_targetIpAddress destinationPort:_targetPort];
    if(ret == -2) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", hstrerror(flooding.errorCode)]];
        goto DONE;
    }
    
    for(_currentIndex = 0 ; _currentIndex < self.amount || self.infinity ; _currentIndex++) {
        
        if(self.cancle)
            break;
        
        ret =
        [flooding floodingSourceIpAddress:_sourceIpAddress
                               sourcePort:_sourcePort
                                   target:self
                                 selector:TCPFLOODING_CALLBACK_SEL
                                   object:_sentArray];
        
        if(ret == -1 && flooding.errorCode != EADDRNOTAVAIL) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(flooding.errorCode)]];
            if(flooding.errorCode != ENOBUFS)
                goto DONE;
            else
                sleep(1);
        }
        else {
            usleep(_interval);
        }
    }
DONE:
    self.flooding = NO;
    
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
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.floodingButton, nil];
        
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
    [flooding close];
    self.requestThread = nil;
}

TCPFLOODING_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = (NSMutableArray *)object;
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:@(self.sentArray.count + 1) forKey:@"Index"];
        [dict setValue:source forKey:@"Source"];
        [dict setValue:@(sourcePort) forKey:@"SourcePort"];
        
        [list addObject:dict];
        [self updateTableView];
    }];
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
    if(indexPath.section == 0) {
        IJTTCPFloodingTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
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
                           key:@"TargetPort"
                         label:cell.targetPortLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Source"
                         label:cell.sourceLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"SourcePort"
                         label:cell.sourcePortLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTTCPFloodingSentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SentCell" forIndexPath:indexPath];
        
        NSDictionary *dict = _sentArray[indexPath.row];
        
        [IJTFormatUILabel dict:dict
                           key:@"Index"
                         label:cell.indexLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Source"
                         label:cell.sourceLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"SourcePort"
                         label:cell.sourcePortLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return @"Task Information";
    else if(section == 1) {
        if(self.flooding)
            return @"Sent";
        else
            return [NSString stringWithFormat:@"Sent(%lu)", (unsigned long)self.sentArray.count];
    }
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
