//
//  IJTNetworkStatusTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/6.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTNetworkStatusTableViewController : IJTBaseViewController <SSARefreshControlDelegate>
@property (weak, nonatomic) IBOutlet UILabel *gatewayLabel;
@property (weak, nonatomic) IBOutlet UILabel *externalIPLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentIPLabel;
@property (weak, nonatomic) IBOutlet UILabel *wifiConnectedLabel;
@property (weak, nonatomic) IBOutlet UIView *wifiConnectedView;
@property (weak, nonatomic) IBOutlet UILabel *wifiIPLabel;
@property (weak, nonatomic) IBOutlet UILabel *wifiMacLabel;
@property (weak, nonatomic) IBOutlet UILabel *bssidLabel;
@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (weak, nonatomic) IBOutlet UILabel *ouiLabel;
@property (weak, nonatomic) IBOutlet UILabel *netmaskLabel;
@property (weak, nonatomic) IBOutlet UILabel *broadcastLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellConnectedLabel;
@property (weak, nonatomic) IBOutlet UIView *cellConnectedView;
@property (weak, nonatomic) IBOutlet UILabel *cellIPLabel;
@property (weak, nonatomic) IBOutlet UILabel *carrierNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *countryCodeLabel;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *nameLabels;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *valueLabels;

@end
