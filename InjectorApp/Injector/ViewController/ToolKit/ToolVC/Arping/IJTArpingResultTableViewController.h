//
//  IJTArpingResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

@interface IJTArpingResultTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource>

@property (nonatomic, strong) NSString *targetIpAddress;
@property (nonatomic) NSUInteger amount;
@property (nonatomic) u_int32_t timeout;
@property (nonatomic) useconds_t interval;

@end
