//
//  IJTTCPFloodingResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/8.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTTCPFloodingResultTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource>

@property (nonatomic, strong) NSString *targetIpAddress;
@property (nonatomic) u_int16_t targetPort;
@property (nonatomic, strong) NSString *sourceIpAddress;
@property (nonatomic) u_int16_t sourcePort;
@property (nonatomic) NSUInteger amount;
@property (nonatomic) useconds_t interval;
@end
