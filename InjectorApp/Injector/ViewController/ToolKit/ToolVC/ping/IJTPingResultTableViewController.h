//
//  IJTPingResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/21.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTPingResultTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource>

@property (nonatomic, strong) NSString *targetIpAddress;
@property (nonatomic, strong) NSString *sourceIpAddress;
@property (nonatomic) BOOL fragment;
@property (nonatomic) IJTPingTos tos;
@property (nonatomic) u_int8_t ttl;
@property (nonatomic) u_int16_t payloadSize;
@property (nonatomic) NSUInteger amount;
@property (nonatomic) u_int32_t timeout;
@property (nonatomic) useconds_t interval;
@property (nonatomic) BOOL fakeMe;

@end
