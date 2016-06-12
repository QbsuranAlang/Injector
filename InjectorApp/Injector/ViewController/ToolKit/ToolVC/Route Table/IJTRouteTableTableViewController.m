//
//  IJTRouteTableTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTRouteTableTableViewController.h"
#import "IJTRouteEntryTableViewCell.h"
#import "IJTAddRouteEntryTableViewController.h"

@interface IJTRouteTableTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *trashButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *addButton;
@property (nonatomic, strong) NSMutableArray *route4List;
@property (nonatomic, strong) NSMutableArray *route6List;

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) Reachability *cellReachability;

@property (nonatomic) BOOL isLoading;
@property (nonatomic, strong) SSARefreshControl *refreshView;
@property (nonatomic) BOOL resolveHostname;
@end

@implementation IJTRouteTableTableViewController

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
    
    /*
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        if(!getegid()) {
            [self loadRoute];
        }
    }];*/
    
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
    if([IJTNetowrkStatus supportCellular]) {
        self.cellReachability = [IJTNetowrkStatus cellReachability];
        [self.cellReachability startNotifier];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if([IJTNetowrkStatus supportWifi])
        [self.wifiReachability stopNotifier];
    if([IJTNetowrkStatus supportCellular])
        [self.cellReachability stopNotifier];
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)callback {
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        self.route4List = [[NSMutableArray alloc] init];
        self.route6List = [[NSMutableArray alloc] init];
        IJTRoutetable *route = [[IJTRoutetable alloc] init];
        if(route.errorHappened) {
            [KVNProgress dismiss];
            if(route.errorCode == 0)
                [self showErrorMessage:route.errorMessage];
            else
                [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(route.errorCode)]];
            return;
        }
        [route getAllEntriesSkipHostname:NO target:self selector:ROUTETABLE_SHOW_CALLBACK_SEL object:nil];
        [route close];
        [self.tableView reloadData];
    }];
}

- (void)gotoAddVC {
    IJTAddRouteEntryTableViewController *vc = (IJTAddRouteEntryTableViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"AddRouteEntryVC"];
    vc.delegate = self;
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
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
        [self loadRoute];
    }
}

#pragma mark route table
- (void)beganRefreshing {
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    [alert addButton:@"Yes" actionBlock:^{
        self.resolveHostname = YES;
        [self loadRoute];
    }];
    
    [alert addButton:@"No" actionBlock:^{
        self.resolveHostname = NO;
        [self loadRoute];
    }];
    
    [alert addButton:@"Nothing to do" actionBlock:^{
        [self.refreshView endRefreshing];
    }];
    [alert showInfo:@"Reslove"
           subTitle:@"Do you want to reslove hostname?"
   closeButtonTitle:nil
           duration:0.0f];
}

- (void)loadRoute {
    self.isLoading = YES;
    [KVNProgress showWithStatus:@"Loading route table..."];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        self.route4List = [[NSMutableArray alloc] init];
        self.route6List = [[NSMutableArray alloc] init];
        IJTRoutetable *route = [[IJTRoutetable alloc] init];
        if(route.errorHappened) {
            [KVNProgress dismiss];
            if(route.errorCode == 0)
                [self showErrorMessage:route.errorMessage];
            else
                [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(route.errorCode)]];
            self.isLoading = NO;
            [self.refreshView endRefreshing];
            return;
        }
        [route getAllEntriesSkipHostname:!_resolveHostname
                                  target:self
                                selector:ROUTETABLE_SHOW_CALLBACK_SEL
                                  object:nil];
        [route close];
        if(self.route4List.count == 0 && self.route6List.count == 0) {
            self.messageLabel.text = @"No Route Entry\nPull to Refresh";
        }
        [self.tableView reloadData];
        self.isLoading = NO;
        [self.refreshView endRefreshing];
        [KVNProgress dismiss];
    }];
}

ROUTETABLE_SHOW_CALLBACK_METHOD {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    NSString *timestamp = nil;
    
    if(dynamic) {
        timestamp = [IJTFormatString formatExpire:(int32_t)expire];
    }
    else {
        timestamp = @"-- --:--:--";
    }
    
    [dict setValue:destinationHostname forKey:@"DestinationHostname"];
    [dict setValue:destinationIpAddress forKey:@"DestinationIpAddress"];
    [dict setValue:gateway forKey:@"Gateway"];
    [dict setValue:[NSString stringWithFormat:@"%@ <%d>", interface, ifindex] forKey:@"Interface"];
    [dict setValue:flags forKey:@"Flags"];
    [dict setValue:@(refs) forKey:@"Refs"];
    [dict setValue:@(use) forKey:@"Use"];
    [dict setValue:@(mtu) forKey:@"Mtu"];
    [dict setValue:timestamp forKey:@"ExpireTime"];
    [dict setValue:@(dynamic) forKey:@"Dynamic"];
    
    if(type == IJTRoutetableTypeInet4) {
        [self.route4List addObject:dict];
    }
    else if(type == IJTRoutetableTypeInet6) {
        [self.route6List addObject:dict];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.route4List.count == 0 && self.route6List.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    
    if(section == 0)
        return self.route4List.count;
    else if(section == 1)
        return self.route6List.count;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [NSString stringWithFormat:@"Internet4(%lu)", (unsigned long)self.route4List.count];
    else if(section == 1)
        return [NSString stringWithFormat:@"Internet6(%lu)", (unsigned long)self.route6List.count];
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTRouteEntryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"RouteEntryCell" forIndexPath:indexPath];
    
    NSDictionary *dict = nil;
    if(indexPath.section == 0) {
        dict = self.route4List[indexPath.row];
    }
    else if(indexPath.section == 1) {
        dict = self.route6List[indexPath.row];
    }
    
    [IJTFormatUILabel dict:dict
                       key:@"DestinationIpAddress"
                     label:cell.dstIpAddressLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"DestinationHostname"
                     label:cell.dstHostnameLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Gateway"
                     label:cell.gatewayLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Interface"
                     label:cell.interfaceLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Mtu"
                     label:cell.mtuLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Refs"
                     label:cell.refsLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Use"
                     label:cell.useLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Flags"
                     label:cell.flagsLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"ExpireTime"
                     label:cell.expireLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    cell.destinationAddress = [dict valueForKey:@"DestinationIpAddress"];
    cell.gatewayAddress = [dict valueForKey:@"Gateway"];
    
    [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:11];
    }];
    
    [cell layoutIfNeeded];
    return cell;
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
        // Delete the row from the data source
        IJTRouteEntryTableViewCell *cell = (IJTRouteEntryTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        SCLAlertView *alert = [IJTShowMessage baseAlertView];
        
        [alert addButton:@"Yes" actionBlock:^{
            IJTRoutetable *route = [[IJTRoutetable alloc] init];
            if(route.errorHappened) {
                if(route.errorCode == 0) {
                    [self showErrorMessage:[NSString stringWithFormat:@"%@.", route.errorMessage]];
                }
                else {
                    [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(route.errorCode)]];
                }
                return;
            }
            
            [KVNProgress showWithStatus:@"Deleting..."];
            
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [route deleteDestination:cell.destinationAddress
                                 gateway:cell.gatewayAddress
                                  target:nil
                                selector:nil
                                  object:nil];
                
                [KVNProgress dismiss];
                if(route.errorHappened) {
                    if(route.errorCode == 0) {
                        [self showErrorMessage:[NSString stringWithFormat:@"%@.", route.errorMessage]];
                    }
                    else {
                        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(route.errorCode)]];
                    }
                    [route close];
                    return;
                }
                [route close];
                
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showSuccessMessage:@"Success"];
                    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                        [self loadRoute];
                    }];
                }];
            }];
            
            
        }];
        
        [alert showWarning:@"Warning"
                  subTitle:[NSString stringWithFormat:@"Are you sure delete: %@ => %@?", cell.destinationAddress, cell.gatewayAddress]
          closeButtonTitle:@"No"
                  duration:0];
    }
}


@end
