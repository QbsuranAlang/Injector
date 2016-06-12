//
//  IJTNetworkStatusTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/6.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTNetworkStatusTableViewController.h"

@interface IJTNetworkStatusTableViewController ()

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) Reachability *cellReachability;
@property (nonatomic, strong) SSARefreshControl *refreshView;
@property (nonatomic, strong) NSThread *connectionThread;

@end

@implementation IJTNetworkStatusTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 44;
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
    
    self.navigationItem.leftBarButtonItem = self.dismissButton;
    
    
    [self.valueLabels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger index, BOOL *stop) {
        label.textColor = IJTValueColor;
        label.adjustsFontSizeToFitWidth = YES;
        label.font = [UIFont systemFontOfSize:11];
    }];
    
    [self.nameLabels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger index, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:11];
    }];
    
    self.wifiConnectedView.backgroundColor = [UIColor clearColor];
    self.cellConnectedView.backgroundColor = [UIColor clearColor];
    
    //refresh control
    self.refreshView = [[SSARefreshControl alloc] initWithScrollView:self.tableView andRefreshViewLayerType:SSARefreshViewLayerTypeOnScrollView];
    self.refreshView.delegate = self;
    
    
    [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
    if([IJTNetowrkStatus supportWifi]) {
        self.wifiReachability = [IJTNetowrkStatus wifiReachability];
        [self.wifiReachability startNotifier];
    }
    if([IJTNetowrkStatus supportCellular]) {
        self.cellReachability = [IJTNetowrkStatus cellReachability];
        [self.cellReachability startNotifier];
    }
    [self reachabilityChanged:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if([IJTNetowrkStatus supportWifi])
        [self.wifiReachability stopNotifier];
    if([IJTNetowrkStatus supportCellular])
        [self.cellReachability stopNotifier];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)getExternalIP {
    NSString *external = [ALNetwork externalIPAddress];
    if(external == nil) {
        self.externalIPLabel.text = @"Try again";
    }
    else {
        self.externalIPLabel.text = external;
    }
    
    [self.refreshView endRefreshing];
}
- (void)getConnection {
    
    [NSThread detachNewThreadSelector:@selector(getExternalIP) toTarget:self withObject:nil];
    
    
    IJTRoutetable *route = [[IJTRoutetable alloc] init];
    NSMutableArray *gateways = [[NSMutableArray alloc] init];
    if(route.errorHappened) {
        if(route.errorHappened) {
            [KVNProgress dismiss];
            if(route.errorCode == 0)
                [self showErrorMessage:route.errorMessage];
            else
                [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(route.errorCode)]];
        }
        self.gatewayLabel.text = @"Try again";
    }//end if route fail
    else {
        [route getAllEntriesSkipHostname:YES
                                  target:self
                                selector:ROUTETABLE_SHOW_CALLBACK_SEL
                                  object:gateways];
        [route close];
    }
    if(gateways.count > 0) {
        self.gatewayLabel.text = [gateways firstObject];
    }
    else {
        self.gatewayLabel.text = @"Try again";
    }
}

ROUTETABLE_SHOW_CALLBACK_METHOD {
    NSMutableArray *list = (NSMutableArray *)object;
    [list addObject:gateway];
}

#pragma mark refresh delegate
- (void)beganRefreshing {
    [self reachabilityChanged:nil];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    self.gatewayLabel.text = @"Waiting...";
    self.externalIPLabel.text = @"Waiting...";
    
    self.connectionThread = [[NSThread alloc] initWithTarget:self selector:@selector(getConnection) object:nil];
    [self.connectionThread start];
    
    self.currentIPLabel.text = [ALNetwork currentIPAddress];
    
    //wifi
    NSString *bssid = [ALNetwork BSSID];
    if(bssid == nil) {
        self.bssidLabel.text = @"N/A";
        self.ouiLabel.text = @"N/A";
    }
    else {
        self.bssidLabel.text = bssid;
        self.ouiLabel.text = [IJTDatabase oui:bssid];
    }
    
    NSString *ssid = [ALNetwork SSID];
    if(ssid == nil) {
        self.ssidLabel.text = @"N/A";
    }
    else {
        self.ssidLabel.text = ssid;
    }
    
    [self.wifiConnectedView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if(self.wifiReachability.currentReachabilityStatus != NotReachable) {
        [self drawCircle:self.wifiConnectedView ok:YES];
        self.wifiConnectedLabel.text = @"Yes";
    }
    else {
        [self drawCircle:self.wifiConnectedView ok:NO];
        self.wifiConnectedLabel.text = @"No";
    }
    
    NSString *wifiAddress = [IJTNetowrkStatus currentIPAddress:@"en0"];
    if(wifiAddress == nil)
        self.wifiIPLabel.text = @"N/A";
    else
        self.wifiIPLabel.text = wifiAddress;
    self.wifiMacLabel.text = [IJTNetowrkStatus wifiMacAddress];
    
    NSString *netmask = [ALNetwork WiFiNetmaskAddress];
    if(netmask == nil)
        self.netmaskLabel.text = @"N/A";
    else
        self.netmaskLabel.text = netmask;
    
    NSString *broadcast = [ALNetwork WiFiBroadcastAddress];
    if(broadcast == nil)
        self.broadcastLabel.text = @"N/A";
    else
        self.broadcastLabel.text = broadcast;
    
    //cell
    [self.cellConnectedView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if(self.cellReachability.currentReachabilityStatus != NotReachable) {
        [self drawCircle:self.cellConnectedView ok:YES];
        self.cellConnectedLabel.text = @"Yes";
    }
    else {
        [self drawCircle:self.cellConnectedView ok:NO];
        self.cellConnectedLabel.text = @"No";
    }
    NSString *cellAddress = [IJTNetowrkStatus currentIPAddress:@"pdp_ip0"];
    if(cellAddress == nil)
        self.cellIPLabel.text = @"N/A";
    else
        self.cellIPLabel.text = cellAddress;
    NSString *carrierName = [ALCarrier carrierName];
    if(carrierName == nil)
        self.carrierNameLabel.text = @"N/A";
    else
        self.carrierNameLabel.text = carrierName;
    NSString *isoCountryCode = [ALCarrier carrierISOCountryCode];
    if(isoCountryCode == nil)
        self.countryCodeLabel.text = isoCountryCode;
    else
        self.countryCodeLabel.text = isoCountryCode;
    
    [self.tableView layoutIfNeeded];
}

#pragma mark - Table view data source

#pragma mark animation
- (void) startAnimation: (UITapGestureRecognizer *)recognizer {
    CSAnimationView *animation = (CSAnimationView *)recognizer.view;
    [animation startCanvasAnimation];
}

- (void)drawCircle: (UIView *)view ok:(BOOL)ok {
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(startAnimation:)];
    
    CSAnimationView *animationView = [[CSAnimationView alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
    
    animationView.backgroundColor = [UIColor clearColor];
    
    animationView.duration = 0.5;
    animationView.delay    = 0;
    animationView.type     = CSAnimationTypeMorph;
    [animationView addGestureRecognizer:singleFingerTap];
    
    if(ok) {
        [IJTGradient drawCircle:animationView color:IJTOkColor];
    }
    else {
        [IJTGradient drawCircle:animationView color:IJTErrorColor];
    }
    [view addSubview:animationView];
    [animationView startCanvasAnimation];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell startCanvasAnimation];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if(![IJTNetowrkStatus supportWifi] && ![IJTNetowrkStatus supportCellular]) {
        if(section == 1)
            return .1;
        else if(section == 2)
            return .1;
    }
    if(![IJTNetowrkStatus supportWifi]) {
        if(section == 1)
            return .1;
    }
    if(![IJTNetowrkStatus supportCellular]) {
        if(section == 2)
            return .1;
    }
    
    return [super tableView:tableView heightForHeaderInSection:section];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(![IJTNetowrkStatus supportWifi] && ![IJTNetowrkStatus supportCellular]) {
        if(section == 1 || section == 2)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }
    if(![IJTNetowrkStatus supportWifi]) {
        if(section == 1)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }
    if(![IJTNetowrkStatus supportCellular]) {
        if(section == 2)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }
    return [super tableView:tableView viewForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    if(![IJTNetowrkStatus supportWifi] && ![IJTNetowrkStatus supportCellular]) {
        if(section == 1)
            return .1;
        else if(section == 2)
            return .1;
    }
    if(![IJTNetowrkStatus supportWifi]) {
        if(section == 1)
            return .1;
    }
    if(![IJTNetowrkStatus supportCellular]) {
        if(section == 2)
            return .1;
    }
    
    return [super tableView:tableView heightForFooterInSection:section];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if(![IJTNetowrkStatus supportWifi] && ![IJTNetowrkStatus supportCellular]) {
        if(section == 1 || section == 2)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }
    if(![IJTNetowrkStatus supportWifi]) {
        if(section == 1)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }
    if(![IJTNetowrkStatus supportCellular]) {
        if(section == 2)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }
    return [super tableView:tableView viewForFooterInSection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 3;
    if(![IJTNetowrkStatus supportWifi] && ![IJTNetowrkStatus supportCellular]) {
        if(section == 1)
            return 0;
        else if(section == 2)
            return 0;
    }
    if(![IJTNetowrkStatus supportWifi]) {
        if(section == 1)
            return 0;
    }
    if(![IJTNetowrkStatus supportCellular]) {
        if(section == 2)
            return 0;
    }
    if(section == 1)
        return 8;
    else if(section == 2)
        return 4;
    
    return 0;
}

@end
