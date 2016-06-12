//
//  IJTIfconfigTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/15.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTIfconfigTableViewController.h"
#import "IJTIfconfigTableViewCell.h"
#import "IJTReviseInterfaceTableViewController.h"

@interface IJTIfconfigTableViewController ()

@property (nonatomic, strong) NSMutableArray *interfaceList;
@property (nonatomic, strong) UIBarButtonItem *editButton;

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) Reachability *cellReachability;

@property (nonatomic, strong) SSARefreshControl *refreshView;
@end

@implementation IJTIfconfigTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 100;
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
    
    self.editButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"edit.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(gotoEditVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_editButton, nil];
    
    self.messageLabel.text = @"No Network Interface";
    
    [self loadInterface];
    
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

- (void)gotoEditVC {
    IJTReviseInterfaceTableViewController *vc = (IJTReviseInterfaceTableViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ReviseInterfaceVC"];
    vc.delegate = self;
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)callback {
    [self loadInterface];
}

#pragma mark interface

- (void)beganRefreshing {
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        [self loadInterface];
    }];
}

- (void)loadInterface {
    self.interfaceList = [[NSMutableArray alloc] init];
    IJTIfconfig *ifconfig = [[IJTIfconfig alloc] init];
    if(ifconfig.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(ifconfig.errorCode)]];
        return;
    }
    
    [ifconfig getAllInterfaceRegisterTarget:self selector:IFCONFIG_SHOW_CALLBACK_SEL object:_interfaceList];
    [self.tableView reloadData];
    [self.refreshView endRefreshing];
}

IFCONFIG_SHOW_CALLBACK_METHOD {
    NSMutableArray *list = (NSMutableArray *)object;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setValue:[NSString stringWithFormat:@"%@ <%d>", interface, ifindex] forKey:@"Interface"];
    [dict setValue:address forKey:@"Address"];
    [dict setValue:netmask forKey:@"Netmask"];
    [dict setValue:dstAddress forKey:@"Destination"];
    [dict setValue:@(mtu) forKey:@"MTU"];
    [dict setValue:
     [NSString stringWithFormat:@"<%#06x>\n%@", flags, [IJTIfconfig interfaceFlags2String:flags]]
            forKey:@"Flags"];
    
    [list addObject:dict];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    [self loadInterface];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.interfaceList.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    return self.interfaceList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [NSString stringWithFormat:@"Interface(%ld)", (unsigned long)self.interfaceList.count];
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTIfconfigTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InterfaceCell" forIndexPath:indexPath];
    
    NSDictionary *dict = self.interfaceList[indexPath.row];
    
    [IJTFormatUILabel dict:dict
                       key:@"Interface"
                     label:cell.interfaceLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"MTU"
                     label:cell.mtuLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Flags"
                     label:cell.flagsLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Address"
                     label:cell.addressLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Netmask"
                     label:cell.netmaskLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Destination"
                     label:cell.dstLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:11];
    }];
    
    [cell layoutIfNeeded];
    return cell;
}

@end
