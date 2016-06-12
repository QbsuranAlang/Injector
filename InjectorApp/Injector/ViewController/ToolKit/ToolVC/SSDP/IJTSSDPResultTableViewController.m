//
//  IJTSSDPResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTSSDPResultTableViewController.h"
#import "IJTSSDPServerTableViewCell.h"

@interface IJTSSDPResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *ssdpButton;
@property (nonatomic, strong) NSMutableArray *replyArray;
@property (nonatomic, strong) NSThread *requestThread;
@property (nonatomic) BOOL scaning;
@property (nonatomic, strong) Reachability *wifiReachability;

@end

@implementation IJTSSDPResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 107;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"SSDP";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.ssdpButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"SSDPNav.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(startSSDP)];
    
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_ssdpButton, nil];
    
    self.messageLabel.text = @"Click icon to start";
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

- (void)startSSDP {
    [self.ssdpButton setEnabled:NO];
    [self.dismissButton setEnabled:NO];
    self.scaning = YES;
    self.replyArray = [[NSMutableArray alloc] init];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    self.requestThread = [[NSThread alloc] initWithTarget:self selector:@selector(startSSDPThread) object:nil];
    [self.requestThread start];
}

- (void)startSSDPThread {
    IJTSSDP *ssdp = [[IJTSSDP alloc] init];
    if(ssdp.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(ssdp.errorCode)]];
    }
    else {
        [ssdp injectTargetIpAddress:_targetIpAddress
                            timeout:_timeout
                             target:self
                           selector:SSDP_CALLBACK_SEL
                             object:_replyArray];
        if(ssdp.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(ssdp.errorCode)]];
        }
    }
    [ssdp close];
    self.scaning = NO;
    [IJTDispatch dispatch_main:^{
        [self.ssdpButton setEnabled:YES];
        [self.dismissButton setEnabled:YES];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

SSDP_CALLBACK_METHOD {
    
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = (NSMutableArray *)object;
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        [dict setValue:sourceIpAddress forKey:@"Source"];
        [dict setValue:location forKey:@"Location"];
        [dict setValue:os forKey:@"OS"];
        [dict setValue:osVersion forKey:@"OSVersion"];
        [dict setValue:product forKey:@"Product"];
        [dict setValue:productVersion forKey:@"ProductVersion"];
        
        [list addObject:dict];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:list.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWarningMessage:@"Now select LAN as target, but there is no Wi-Fi connection."];
        [self.ssdpButton setEnabled:NO];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.ssdpButton setEnabled:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.replyArray.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    return _replyArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        IJTSSDPServerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ServerCell" forIndexPath:indexPath];
        
        NSDictionary *dict = _replyArray[indexPath.row];
        
        [IJTFormatUILabel dict:dict
                           key:@"Source"
                         label:cell.sourceLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Location"
                         label:cell.locationLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"OS"
                         label:cell.osLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"OSVersion"
                         label:cell.osVersionLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Product"
                         label:cell.productLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"ProductVersion"
                         label:cell.productVersionLabel
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
    if(section == 0) {
        if(self.scaning)
            return @"Servers";
        else
            return [NSString stringWithFormat:@"Servers(%lu)", (unsigned long)_replyArray.count];
    }
    return @"";
}

@end
