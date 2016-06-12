//
//  IJTArpScanResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/19.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTArpScanResultTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource>

@property (nonatomic) int scanType;
@property (nonatomic) u_int32_t timeout;
@property (nonatomic) useconds_t interval;
@property (nonatomic, strong) NSString *networkAddress;
@property (nonatomic) int slash;
@property (nonatomic, strong) NSString *startIpAddress;
@property (nonatomic, strong) NSString *endIpAddress;

@end
