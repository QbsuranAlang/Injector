//
//  IJTArpTableTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/14.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArpTableTableViewController.h"
#import "IJTArpTableTableViewCell.h"
#import "IJTAddArpCacheTableViewController.h"

@interface IJTArpTableTableViewController ()

@property (nonatomic, strong) NSMutableArray *arpCacheList;
@property (nonatomic, strong) UIBarButtonItem *trashButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *addButton;
@property (nonatomic) BOOL isLoading;

@property (nonatomic, strong) Reachability *wifiReachability;

@property (nonatomic, strong) SSARefreshControl *refreshView;
@property (nonatomic) BOOL resolveHostname;

@end

@implementation IJTArpTableTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 110;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    if(self.multiToolButton == nil) {
        self.dismissButton = [[UIBarButtonItem alloc]
                              initWithImage:[UIImage imageNamed:@"down.png"]
                              style:UIBarButtonItemStylePlain
                              target:self action:@selector(dismissVC)];
    }
    else {
        self.dismissButton = self.multiToolButton;
    }
    
    //set edit button
    self.trashButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"trash.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(editAction:)];
    
    self.doneButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                       target:self
                       action:@selector(editAction:)];
    
    self.addButton = [[UIBarButtonItem alloc]
                      initWithImage:[UIImage imageNamed:@"plus.png"]
                      style:UIBarButtonItemStylePlain
                      target:self action:@selector(gotoAddVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_addButton, _trashButton, nil];
    
    self.messageLabel.text = @"Pull to Refresh";
    
    //refresh control
    self.refreshView = [[SSARefreshControl alloc] initWithScrollView:self.tableView andRefreshViewLayerType:SSARefreshViewLayerTypeOnScrollView];
    self.refreshView.delegate = self;
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
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if([IJTNetowrkStatus supportWifi]) {
        [self.wifiReachability stopNotifier];
    }
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoAddVC {
    IJTAddArpCacheTableViewController *vc = (IJTAddArpCacheTableViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"AddArpCacheVC"];
    vc.delegate = self;
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) callback {
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        self.arpCacheList = [[NSMutableArray alloc] init];
        IJTArptable *arptable = [[IJTArptable alloc] init];
        if(arptable.errorHappened) {
            if(arptable.errorCode == 0)
                [self showErrorMessage:arptable.errorMessage];
            else
                [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(arptable.errorCode)]];
            return;
        }
        [arptable getAllEntriesSkipHostname:NO target:self selector:ARPTABLE_SHOW_CALLBACK_SEL object:_arpCacheList];
        [arptable close];
        [self.tableView reloadData];
    }];
}

- (void)editAction: (id)sender {
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    if(button == self.trashButton) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_addButton, _doneButton, nil];
        self.dismissButton.enabled = NO;
        self.addButton.enabled = NO;
        [self.tableView setEditing:YES animated:YES];
    }
    else if(button == self.doneButton) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_addButton, _trashButton, nil];
        self.dismissButton.enabled = YES;
        self.addButton.enabled = YES;
        [self.tableView setEditing:NO animated:YES];
    }
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(!self.isLoading) {
        self.resolveHostname = NO;
        [self loadArp];
    }
}

#pragma mark refresh delegate
- (void)beganRefreshing {
    
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    [alert addButton:@"Yes" actionBlock:^{
        self.resolveHostname = YES;
        [self loadArp];
    }];
    
    [alert addButton:@"No" actionBlock:^{
        self.resolveHostname = NO;
        [self loadArp];
    }];
    
    [alert addButton:@"Nothing to do" actionBlock:^{
        [self.refreshView endRefreshing];
    }];
    [alert showInfo:@"Reslove"
           subTitle:@"Do you want to reslove hostname?"
   closeButtonTitle:nil
           duration:0.0f];
    
}

#pragma mark arp table

- (void) loadArp {
    self.isLoading = YES;
    
    [KVNProgress showWithStatus:@"Loading arp cache..."];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        self.arpCacheList = [[NSMutableArray alloc] init];
        IJTArptable *arptable = [[IJTArptable alloc] init];
        if(arptable.errorHappened) {
            [KVNProgress dismiss];
            if(arptable.errorCode == 0)
                [self showErrorMessage:arptable.errorMessage];
            else
                [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(arptable.errorCode)]];
            self.isLoading = NO;
            [self.refreshView endRefreshing];
            return;
        }
        [arptable getAllEntriesSkipHostname:!_resolveHostname
                                     target:self
                                   selector:ARPTABLE_SHOW_CALLBACK_SEL
                                     object:_arpCacheList];
        [arptable close];
        
        //oui
        NSMutableArray *macAddresses = [[NSMutableArray alloc] init];
        for(int i = 0 ; i < [_arpCacheList count] ; i++) {
            NSMutableDictionary *dict = [_arpCacheList objectAtIndex:i];
            [macAddresses addObject:[dict valueForKey:@"MacAddress"]];
        }
        NSArray *ouis = [IJTDatabase ouiArray:macAddresses];
        for(int i = 0 ; i < [_arpCacheList count] ; i++) {
            NSMutableDictionary *dict = [_arpCacheList objectAtIndex:i];
            [dict setValue:[ouis objectAtIndex:i] forKey:@"OUI"];
        }
        
        if(self.arpCacheList.count == 0) {
            self.messageLabel.text = @"No ARP Entry\nPull to Refresh";
        }
        [self.tableView reloadData];
        self.isLoading = NO;
        [self.refreshView endRefreshing];
        [KVNProgress dismiss];
    }];
}

ARPTABLE_SHOW_CALLBACK_METHOD {
    NSMutableArray *list = (NSMutableArray *)object;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    NSString *timestamp = nil;
    
    if(dynamic) {
        timestamp = [IJTFormatString formatExpire:expireTime];
    }
    else {
        timestamp = @"-- --:--:--";
    }
    
    [dict setValue:hostname forKey:@"Hostname"];
    [dict setValue:ipAddress forKey:@"IpAddress"];
    [dict setValue:macAddress forKey:@"MacAddress"];
    [dict setValue:interface forKey:@"Interface"];
    [dict setValue:timestamp forKey:@"ExpireTime"];
    [dict setValue:@(dynamic) forKey:@"Dynamic"];
    [dict setValue:@(proxy) forKey:@"Proxy"];
    [dict setValue:@(ifscope) forKey:@"Ifscope"];
    [dict setValue:netmask forKey:@"Netmask"];
    [dict setValue:[IJTArptable sdltype2string:sdl_type] forKey:@"SdlType"];
    
    
    [list addObject:dict];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.arpCacheList.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    return self.arpCacheList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTArpTableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArpCacheCell" forIndexPath:indexPath];
    
    NSMutableDictionary *dict = self.arpCacheList[indexPath.row];
    NSNumber *dynamic = [dict valueForKey:@"Dynamic"];
    NSNumber *proxy = [dict valueForKey:@"Proxy"];
    NSNumber *ifscope = [dict valueForKey:@"Ifscope"];
    
    [IJTFormatUILabel dict:dict
                       key:@"Hostname"
                     label:cell.hostnameLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"IpAddress"
                     label:cell.ipAddressLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Interface"
                     label:cell.interfaceLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"MacAddress"
                     label:cell.macAddressLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"ExpireTime"
                     label:cell.expireLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Netmask"
                     label:cell.netmaskLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"SdlType"
                     label:cell.typeLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"OUI"
                     label:cell.ouiLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    if([dynamic boolValue]) {
        cell.dynamicLabel.text = @"Yes";
    }
    else {
        cell.dynamicLabel.text = @"No";
    }
    if([proxy boolValue]) {
        cell.proxyLabel.text = @"Yes";
    }
    else {
        cell.proxyLabel.text = @"No";
    }
    if([ifscope boolValue]) {
        cell.ifscopeLabel.text = @"Yes";
    }
    else {
        cell.ifscopeLabel.text = @"No";
    }
    
    cell.dynamicLabel.textColor = IJTValueColor;
    cell.proxyLabel.textColor = IJTValueColor;
    cell.ifscopeLabel.textColor = IJTValueColor;
    
    [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:11];
    }];
    
    [cell layoutIfNeeded];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [NSString stringWithFormat:@"ARP Entry(%ld)", (unsigned long)self.arpCacheList.count];
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *dict = self.arpCacheList[indexPath.row];
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        NSString *macAddress = [dict valueForKey:@"MacAddress"];
        
        SCLAlertView *alert = [IJTShowMessage baseAlertView];
        
        [alert addButton:@"Yes" actionBlock:^{
            if(!getegid()) {
                IJTArptable *arptable = [[IJTArptable alloc] init];
                if(arptable.errorHappened) {
                    [KVNProgress dismiss];
                    if(arptable.errorCode == 0)
                        [self showErrorMessage:arptable.errorMessage];
                    else
                        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(arptable.errorCode)]];
                    return;
                }
                
                [arptable deleteIpAddress:ipAddress];
                
                if(arptable.errorHappened) {
                    [KVNProgress dismiss];
                    if(arptable.errorCode == 0)
                        [self showErrorMessage:arptable.errorMessage];
                    else
                        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(arptable.errorCode)]];
                    [arptable close];
                    return;
                }
                [arptable close];
                
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showSuccessMessage:@"Success"];
                    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                        [self loadArp];
                    }];
                }];
            }
        }];
        
        [alert showWarning:@"Warning"
                  subTitle:[NSString stringWithFormat:@"Are you sure delete: %@(%@)?", ipAddress, macAddress]
          closeButtonTitle:@"No"
                  duration:0];
    }
}

@end
