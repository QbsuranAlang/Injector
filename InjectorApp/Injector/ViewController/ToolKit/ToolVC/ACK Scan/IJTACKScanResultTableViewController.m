//
//  IJTACKScanResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/10.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTACKScanResultTableViewController.h"
#import "IJTScanTaskTableViewCell.h"
#import "IJTScanPortTableViewCell.h"

@interface IJTACKScanResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *scanButton;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic, strong) NSMutableArray *replyArray;
@property (nonatomic) BOOL scanning;
@property (nonatomic, strong) NSThread *requestThread;
@property (nonatomic, strong) NSTimer *updateProgressViewTimer;
@property (nonatomic, strong) ASProgressPopUpView *progressView;
@property (nonatomic) BOOL cancle;
@property (nonatomic, strong) IJTACK_Scan *ack_scan;

@end

@implementation IJTACKScanResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 76;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"ACK Scan";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.scanButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"ACK ScanNav.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(scan)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopScan)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_scanButton, nil];
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:self.target forKey:@"Target"];
    [self.taskInfoDict setValue:@(self.startPort) forKey:@"StartPort"];
    [self.taskInfoDict setValue:@(self.endPort) forKey:@"EndPort"];
    [self.taskInfoDict setValue:self.randomization == YES ? @"Yes" : @"No" forKey:@"Rand"];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Target : %@\nPort : %u - %u", self.target, self.startPort, self.endPort];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    self.ack_scan = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)stopScan {
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

- (void)scan {
    self.messageLabel.text = [NSString stringWithFormat:@"Target : %@\nPort : %u - %u", self.target, self.startPort, self.endPort];
    
    self.ack_scan = [[IJTACK_Scan alloc] init];
    [self.ack_scan setTarget:self.target];
    if(self.ack_scan.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", hstrerror(self.ack_scan.errorCode)]];
        return;
    }
    [self.ack_scan setStartPort:self.startPort endPort:self.endPort];
    
    self.cancle = NO;
    self.scanning = YES;
    [self.dismissButton setEnabled:NO];
    self.replyArray = [[NSMutableArray alloc] init];
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    [self.dismissButton setEnabled:NO];
    [self.tableView setUserInteractionEnabled:NO];
    
    //add progress view
    self.progressView = [IJTProgressView baseProgressPopUpView];
    self.progressView.dataSource = self;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:
                                      CGRectMake(0, 0, SCREEN_WIDTH, CGRectGetHeight(_progressView.frame))];
    [self.tableView setContentOffset:CGPointMake(0, -60) animated:YES];
    [self.tableView.tableHeaderView addSubview:self.progressView];
    
    //read inject and read
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(60, 0, 0, 0);
        self.requestThread = [[NSThread alloc] initWithTarget:self selector:@selector(scanThread) object:nil];
        [self.requestThread start];
        self.updateProgressViewTimer =
        [NSTimer scheduledTimerWithTimeInterval:0.05
                                         target:self
                                       selector:@selector(updateProgressView:)
                                       userInfo:nil repeats:YES];
    }];
    
}

- (void)scanThread {
    int ret =
    [_ack_scan injectWithInterval:_interval
                    randomization:_randomization
                             stop:&_cancle
                          timeout:_timeout
                           target:self
                         selector:ACKSCAN_CALLBACK_SEL
                           object:_replyArray];
    
    if(_ack_scan.errorHappened) {
        if(ret == -2) {
            [self showErrorMessage:@"Host seems down."];
        }
        else {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(_ack_scan.errorCode)]];
        }
    }
    
    if(self.replyArray.count == 0) {
        if(ret == -2) {
            self.messageLabel.text = [NSString stringWithFormat:@"Host seems down\nTarget : %@\nPort : %u - %u", self.target, self.startPort, self.endPort];
        }
        else {
            self.messageLabel.text = [NSString stringWithFormat:@"No port available\nTarget : %@\nPort : %u - %u", self.target, self.startPort, self.endPort];
        }
    }
    
    self.scanning = NO;
    
    [self.updateProgressViewTimer invalidate];
    self.updateProgressViewTimer = nil;
    [IJTDispatch dispatch_main:^{
        [self.dismissButton setEnabled:YES];
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.scanButton, nil];
        
        [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
        [self.tableView setUserInteractionEnabled:YES];
        [self.progressView removeFromSuperview];
        
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        }];
    }];
    [self.ack_scan close];
    self.ack_scan = nil;
    self.requestThread = nil;
}

ACKSCAN_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        [dict setValue:@(port) forKey:@"Port"];
        [dict setValue:portName forKey:@"Name"];
        
        NSString *state = @"";
        if(flags == IJTACK_ScanFlagsUnfiltered)
            state = @"Unfiltered";
        else if(flags == IJTACK_ScanFlagsFiltered)
            state = @"Filtered";
        
        [dict setValue:state forKey:@"State"];
        
        [self.replyArray addObject:dict];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

#pragma mark - ASProgressPopUpView dataSource

- (void)updateProgressView: (id)sender {
    float value = ([_ack_scan getTotalInjectCount] - [_ack_scan getRemainInjectCount])/(float)[_ack_scan getTotalInjectCount];
    [self.progressView setProgress:value animated:YES];
}

// <ASProgressPopUpViewDataSource> is entirely optional
// it allows you to supply custom NSStrings to ASProgressPopUpView
- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress
{
    NSString *s;
    if(progress == 0) {
        s = @"Try connecting...";
    }
    else if(progress < 0.99) {
        u_int64_t count = [_ack_scan getTotalInjectCount] - ([_ack_scan getTotalInjectCount] - [_ack_scan getRemainInjectCount]);
        s = [NSString stringWithFormat:@"Left : %lu(%2d%%)", (unsigned long)count, (int)(progress*100)%100];
    }
    else {
        s = @"Reading...";
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
        IJTScanTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Target"
                         label:cell.targetLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"StartPort"
                         label:cell.startPortLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"EndPort"
                         label:cell.endPortLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Rand"
                         label:cell.randLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTScanPortTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PortCell" forIndexPath:indexPath];
        
        NSMutableDictionary *dict = self.replyArray[indexPath.row];
        
        if([dict valueForKey:@"Info"] == nil) {
            NSString *portName = [dict valueForKey:@"Name"];
            [dict setValue:[IJTDatabase port:portName] forKey:@"Info"];
        }
        
        [IJTFormatUILabel dict:dict
                           key:@"Port"
                         label:cell.portLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Info"
                         label:cell.infoLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Name"
                         label:cell.nameLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"State"
                         label:cell.stateLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
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
        if(self.scanning)
            return @"Ports";
        else
            return [NSString stringWithFormat:@"Ports(%lu)", (unsigned long)self.replyArray.count];
    }
    return @"";
}

@end
