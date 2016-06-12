//
//  IJTDNSpoofResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/12/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTDNSpoofResultTableViewController.h"
#import "IJTDNSpoofTaskTableViewCell.h"
#import "IJTDNSpoofSentTableViewCell.h"
@interface IJTDNSpoofResultTableViewController ()

@property (nonatomic, strong) NSMutableArray *sentArray;
@property (nonatomic, strong) NSThread *spoofThread;
@property (nonatomic, strong) IJTDNSpoof *dnspoof;
@property (nonatomic) BOOL spoofing;
@property (nonatomic, strong) UIBarButtonItem *spoofButton;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic) BOOL cancle;

@end

@implementation IJTDNSpoofResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 45;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"DNSpoof";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.spoofButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"DNSpoofNav"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(startSpoof)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopSpoof)];
    
    self.navigationItem.rightBarButtonItem = self.spoofButton;
    
    
    self.dnspoof = [[IJTDNSpoof alloc] init];
    if(_dnspoof.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%@.", _dnspoof.errorMessage]];
    }
    [_dnspoof readPattern:_dnsPatternString];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Pattern amount : %lu", (unsigned long)_dnspoof.paternArray.count];
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
    [_dnspoof close];
    _dnspoof = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)stopSpoof {
    if(self.spoofThread != nil) {
        [self.stopButton setEnabled:NO];
        [self.dnspoof stop];
        self.cancle = YES;
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            if(![self.spoofThread isFinished]) {
                while(self.spoofThread) {
                    usleep(100);
                }
            }
            [self.stopButton setEnabled:YES];
        }];
    }
}

- (void)startSpoof {
    if([self.dnspoof openSniffer] == -1) {
        [self showErrorMessage:self.dnspoof.errorMessage];
    }
    else {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
        self.sentArray = [[NSMutableArray alloc] init];
        self.spoofing = YES;
        self.cancle = NO;
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        [self.dismissButton setEnabled:NO];
        self.messageLabel.text = @"Spoofing...";
        
        self.spoofThread = [[NSThread alloc] initWithTarget:self selector:@selector(startSpoofThread) object:nil];
        [self.spoofThread setThreadPriority:1.0];
        [self.spoofThread start];
    }
}

- (void)startSpoofThread {
    [IJTDispatch dispatch_global:IJTDispatchPriorityHigh block:^{
        [_dnspoof startRegisterTarget:self selector:DNSPOOF_LIST_CALLBACK_SEL object:_sentArray];
        _cancle = YES;
    }];
    while(!_cancle) {
        usleep(100);
    }
    
    self.spoofThread = nil;
    self.spoofing = NO;
    [IJTDispatch dispatch_main:^{
        [self.dismissButton setEnabled:YES];
        
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_spoofButton, nil];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if(self.sentArray.count <= 0) {
            self.messageLabel.text = [NSString stringWithFormat:@"Pattern amount : %lu", (unsigned long)_dnspoof.paternArray.count];
        }
        else {
            self.messageLabel.text = @"Spoofing...";
        }
    }];
}

DNSPOOF_LIST_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = (NSMutableArray *)object;
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        [dict setValue:sourceIpAddress forKey:@"Source"];
        [dict setValue:queryName forKey:@"QueryName"];
        [dict setValue:spoofIpAddress forKey:@"SpoofIpAddress"];
        [dict setValue:@(type) forKey:@"Type"];
        
        [dict setValue:[IJTFormatString formatTimestamp:recvTime secondsPadding:2 decimalPoint:0] forKey:@"SentTime"];
        
        [list addObject:dict];
        NSArray *addArray = @[[NSIndexPath indexPathForRow:self.sentArray.count - 1 inSection:1]];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.sentArray.count - 1 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"DNSpoof"];
        [self.spoofButton setEnabled:NO];
        [self stopSpoof];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.spoofButton setEnabled:YES];
    }
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
    if(self.sentArray.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    
    if(section == 0)
        return 1;
    else if(section == 1)
        return _sentArray.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTDNSpoofTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        NSArray *list = _dnspoof.paternArray;
        NSMutableString *pattern = [[NSMutableString alloc] init];
        for(NSDictionary *dict in list) {
            NSString *hostname = [dict valueForKey:@"OriginHostname"];
            NSString *type = [dict valueForKey:@"Type"];
            NSString *ipAddress = [dict valueForKey:@"IpAddress"];
            if(pattern.length <= 0) {
                [pattern appendFormat:@"%@ %@ %@", hostname, type, ipAddress];
            }
            else {
                [pattern appendFormat:@"\n%@ %@ %@", hostname, type, ipAddress];
            }
        }//end for
        
        [IJTFormatUILabel text:pattern
                         label:cell.patternLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTDNSpoofSentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SentCell" forIndexPath:indexPath];
        NSDictionary *dict = _sentArray[indexPath.row];
        
        [IJTFormatUILabel dict:dict
                           key:@"Source"
                         label:cell.sourceIpAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"QueryName"
                         label:cell.queryHostnameLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"SpoofIpAddress"
                         label:cell.replyIpAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"SentTime"
                         label:cell.sentTimeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Task Information";
    }
    else if (section == 1) {
        if(self.spoofing)
            return @"Sent";
        else
            return [NSString stringWithFormat:@"Sent(%lu)", (unsigned long)_sentArray.count];
    }
    return @"";
}

@end
