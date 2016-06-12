//
//  IJTArpoisonResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/6.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

@interface IJTArpoisonResultTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource>

@property (nonatomic) NSUInteger targetType;
@property (nonatomic, strong) NSString *singleAddress;
@property (nonatomic) NSUInteger senderType;
@property (nonatomic, strong) NSString *senderIpAddress;
@property (nonatomic, strong) NSString *senderMacAddress;
@property (nonatomic) NSUInteger opCode;
@property (nonatomic) NSUInteger injectRows;
@property (nonatomic) useconds_t interval;
@property (nonatomic, strong) NSString *startIpAddress;
@property (nonatomic, strong) NSString *endIpAddress;
@property (nonatomic) BOOL twoWay;

@end
