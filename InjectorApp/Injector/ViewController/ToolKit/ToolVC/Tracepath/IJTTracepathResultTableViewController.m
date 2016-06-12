//
//  IJTTracepathResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTTracepathResultTableViewController.h"
#import "IJTTracepathTaskTableViewCell.h"
#import "IJTTracepathHopsTableViewCell.h"
@interface IJTTracepathResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *traceButton;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic, strong) NSMutableArray *replyArray;
@property (nonatomic, strong) NSThread *traceThread;
@property (nonatomic) BOOL cancle;
@property (nonatomic) BOOL tracing;
@property (nonatomic, strong) IJTTracepath *trace;

@end

@implementation IJTTracepathResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 215;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"tracepath";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.traceButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"tracepathNav.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(startTrace)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopTrace)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_traceButton, nil];
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:self.target forKey:@"Target"];
    [self.taskInfoDict setValue:self.sourceIpAddress forKey:@"Source"];
    [self.taskInfoDict setValue:[NSString stringWithFormat:@"%d - %d", self.startTTL, self.endTTL] forKey:@"TTL Range"];
    [self.taskInfoDict setValue:[NSString stringWithFormat:@"%d - %d", self.startPort, self.endPort] forKey:@"Port Range"];
    [self.taskInfoDict setValue:self.resolveHostname == YES ? @"Yes" : @"No" forKey:@"Resolve"];
    [self.taskInfoDict setValue:[IJTFormatString formatIpTypeOfSerivce:self.tos] forKey:@"Tos"];
    [self.taskInfoDict setValue:[IJTFormatString formatBytes:self.payloadSize carry:NO] forKey:@"PayloadSize"];
    self.messageLabel.text = [NSString stringWithFormat:@"Target : %@\nSource : %@", self.target, self.sourceIpAddress];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)stopTrace {
    if(self.traceThread) {
        [self.stopButton setEnabled:NO];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            if(![self.traceThread isFinished]) {
                self.cancle = YES;
                while(self.traceThread) {
                    usleep(100);
                }
            }
            [self.stopButton setEnabled:YES];
        }];
    }
}

- (void)startTrace {
    
    self.replyArray = [[NSMutableArray alloc] init];
    
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    _trace = [[IJTTracepath alloc] init];
    
    if(_trace.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(_trace.errorCode)]];
        return;
    }
    
    self.tracing = YES;
    self.cancle = NO;
    [self.dismissButton setEnabled:NO];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        
        self.traceThread = [[NSThread alloc] initWithTarget:self selector:@selector(startTraceThread) object:nil];
        [self.traceThread start];
    }];
}

- (void)startTraceThread {
    
    __block NSMutableArray *hopsInfo = [[NSMutableArray alloc] init];
    __block NSArray *addArray = nil;
    BOOL finish = NO;
    
    int ret = [_trace setTarget:self.target];
    if(ret == -2) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", hstrerror(_trace.errorCode)]];
        finish = YES;
    }
    [_trace setStartPort:_startPort endPort:_endPort];
    
    if(!finish) {
        [IJTDispatch dispatch_main:^{
            for(int i = 0 ; i < 3 ; i++) {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setValue:@"Waiting..." forKey:@"Hostname"];
                [dict setValue:@"Waiting..." forKey:@"IpAddress"];
                [dict setValue:@"Waiting..." forKey:@"RTT"];
                [dict setValue:@"Waiting..." forKey:@"Length"];
                [dict setValue:@(NO) forKey:@"Timeout"];
                [hopsInfo addObject:dict];
            }
            
            [self.replyArray addObject:hopsInfo];
            
            addArray = @[[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1]];
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }];
        
        [_trace traceStartTTL:_startTTL
                       maxTTL:_endTTL
                          tos:_tos
                      timeout:_timeout
                     sourceIP:_sourceIpAddress
                  payloadSize:_payloadSize
                         stop:&_cancle
                 skipHostname:!_resolveHostname
                   targetRecv:self
                 selectorRecv:TRACEPATH_CALLBACK_SEL
                   objectRecv:_replyArray
                targetTimeout:self
              selectorTimeout:TRACEPATH_CALLBACK_TIMEOUT_SEL
                objectTimeout:_replyArray];
        
        if(_trace.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(_trace.errorCode)]];
        }
    }
    
    self.tracing = NO;
    [IJTDispatch dispatch_main:^{
        [self.dismissButton setEnabled:YES];
        [self.tableView reloadData];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.traceButton, nil];
    }];
    [_trace close];
    self.traceThread = nil;
}

TRACEPATH_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *hopsInfo = [self.replyArray lastObject];
        NSMutableDictionary *dict = [hopsInfo objectAtIndex:numberOfUDP-1];
        [dict setValue:hostname forKey:@"Hostname"];
        [dict setValue:ipAddress forKey:@"IpAddress"];
        [dict setValue:[NSString stringWithFormat:@"%4.2f ms", RTT] forKey:@"RTT"];
        [dict setValue:[IJTFormatString formatBytes:recvlength carry:NO] forKey:@"Length"];
        [dict setValue:@(NO) forKey:@"Timeout"];
        
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1]]
                              withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        
        if(numberOfUDP == 3 && !found) { //need new hops
            NSMutableArray *hopsInfo = [[NSMutableArray alloc] init];
            
            for(int i = 0 ; i < 3 ; i++) {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setValue:@"Waiting..." forKey:@"Hostname"];
                [dict setValue:@"Waiting..." forKey:@"IpAddress"];
                [dict setValue:@"Waiting..." forKey:@"RTT"];
                [dict setValue:@"Waiting..." forKey:@"Length"];
                [dict setValue:@(NO) forKey:@"Timeout"];
                [hopsInfo addObject:dict];
            }
            
            [self.replyArray addObject:hopsInfo];
            
            NSArray *addArray = @[[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1]];
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }];
}

TRACEPATH_CALLBACK_TIMEOUT_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *hopsInfo = [self.replyArray lastObject];
        NSMutableDictionary *dict = [hopsInfo objectAtIndex:numberOfUDP-1];
        [dict setValue:@(YES) forKey:@"Timeout"];
        
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1]]
                              withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        
        if(numberOfUDP == 3) { //need new hops
            NSMutableArray *hopsInfo = [[NSMutableArray alloc] init];
            
            for(int i = 0 ; i < 3 ; i++) {
                NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
                [dict setValue:@"Waiting..." forKey:@"Hostname"];
                [dict setValue:@"Waiting..." forKey:@"IpAddress"];
                [dict setValue:@"Waiting..." forKey:@"RTT"];
                [dict setValue:@"Waiting..." forKey:@"Length"];
                [dict setValue:@(NO) forKey:@"Timeout"];
                [hopsInfo addObject:dict];
            }
            
            [self.replyArray addObject:hopsInfo];
            
            NSArray *addArray = @[[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1]];
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.replyArray.count - 1 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    
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
        IJTTracepathTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
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
                           key:@"TTL Range"
                         label:cell.ttlRangeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Port Range"
                         label:cell.portRangeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Tos"
                         label:cell.tosLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"PayloadSize"
                         label:cell.payloadSizeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Resolve"
                         label:cell.resloveIpAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTTracepathHopsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HopsCell" forIndexPath:indexPath];
        NSArray *reply = self.replyArray[indexPath.row];
        NSDictionary *dict1 = [reply objectAtIndex:0];
        NSDictionary *dict2 = [reply objectAtIndex:1];
        NSDictionary *dict3 = [reply objectAtIndex:2];
        /*NSNumber *waiting1 = [dict1 valueForKey:@"Waiting"];
        NSNumber *waiting2 = [dict2 valueForKey:@"Waiting"];
        NSNumber *waiting3 = [dict3 valueForKey:@"Waiting"];*/
        NSNumber *timeout1 = [dict1 valueForKey:@"Timeout"];
        NSNumber *timeout2 = [dict2 valueForKey:@"Timeout"];
        NSNumber *timeout3 = [dict3 valueForKey:@"Timeout"];
        
        if([timeout1 boolValue]) {
            [cell.hostname1Label setHidden:YES];
            [cell.ipAddress1Label setHidden:YES];
            [cell.rtt1Label setHidden:YES];
            [cell.length1Label setHidden:YES];
            [cell.ipAddress1TextLabel setHidden:YES];
            [cell.rtt1TextLabel setHidden:YES];
            [cell.length1TextLabel setHidden:YES];
            [IJTFormatUILabel text:@"Timeout !"
                             label:cell.hostname1TextLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:17]];
        }
        else {
            [cell.hostname1Label setHidden:NO];
            [cell.ipAddress1Label setHidden:NO];
            [cell.rtt1Label setHidden:NO];
            [cell.length1Label setHidden:NO];
            [cell.ipAddress1TextLabel setHidden:NO];
            [cell.rtt1TextLabel setHidden:NO];
            [cell.length1TextLabel setHidden:NO];
            [IJTFormatUILabel text:@"Hostname :"
                             label:cell.hostname1TextLabel
                             color:[UIColor blackColor]
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict1
                               key:@"Hostname"
                             label:cell.hostname1Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict1
                               key:@"IpAddress"
                             label:cell.ipAddress1Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict1
                               key:@"RTT"
                             label:cell.rtt1Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict1
                               key:@"Length"
                             label:cell.length1Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
        }
        
        if([timeout2 boolValue]) {
            [cell.hostname2Label setHidden:YES];
            [cell.ipAddress2Label setHidden:YES];
            [cell.rtt2Label setHidden:YES];
            [cell.length2Label setHidden:YES];
            [cell.ipAddress2TextLabel setHidden:YES];
            [cell.rtt2TextLabel setHidden:YES];
            [cell.length2TextLabel setHidden:YES];
            [IJTFormatUILabel text:@"Timeout !"
                             label:cell.hostname2TextLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:17]];
        }
        else {
            [cell.hostname2Label setHidden:NO];
            [cell.ipAddress2Label setHidden:NO];
            [cell.rtt2Label setHidden:NO];
            [cell.length2Label setHidden:NO];
            [cell.ipAddress2TextLabel setHidden:NO];
            [cell.rtt2TextLabel setHidden:NO];
            [cell.length2TextLabel setHidden:NO];
            [IJTFormatUILabel text:@"Hostname :"
                             label:cell.hostname2TextLabel
                             color:[UIColor blackColor]
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict2
                               key:@"Hostname"
                             label:cell.hostname2Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict2
                               key:@"IpAddress"
                             label:cell.ipAddress2Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict2
                               key:@"RTT"
                             label:cell.rtt2Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict2
                               key:@"Length"
                             label:cell.length2Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
        }
        
        if([timeout3 boolValue]) {
            [cell.hostname3Label setHidden:YES];
            [cell.ipAddress3Label setHidden:YES];
            [cell.rtt3Label setHidden:YES];
            [cell.length3Label setHidden:YES];
            [cell.ipAddress3TextLabel setHidden:YES];
            [cell.rtt3TextLabel setHidden:YES];
            [cell.length3TextLabel setHidden:YES];
            [IJTFormatUILabel text:@"Timeout !"
                             label:cell.hostname3TextLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:17]];
        }
        else {
            [cell.hostname3Label setHidden:NO];
            [cell.ipAddress3Label setHidden:NO];
            [cell.rtt3Label setHidden:NO];
            [cell.length3Label setHidden:NO];
            [cell.ipAddress3TextLabel setHidden:NO];
            [cell.rtt3TextLabel setHidden:NO];
            [cell.length3TextLabel setHidden:NO];
            [IJTFormatUILabel text:@"Hostname :"
                             label:cell.hostname3TextLabel
                             color:[UIColor blackColor]
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict3
                               key:@"Hostname"
                             label:cell.hostname3Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict1
                               key:@"IpAddress"
                             label:cell.ipAddress3Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict1
                               key:@"RTT"
                             label:cell.rtt3Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict1
                               key:@"Length"
                             label:cell.length3Label
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
        }
        
        [IJTFormatUILabel text:[NSString stringWithFormat:@"%ld", (long)indexPath.row + 1]
                         label:cell.indexLabel
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
        if(self.tracing)
            return @"Hops";
        else
            return [NSString stringWithFormat:@"Hops(%lu)", (unsigned long)self.replyArray.count];
    }
    return @"";
}

@end
