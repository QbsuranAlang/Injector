//
//  IJTWOLResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTWOLResultTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource>

@property (nonatomic, strong) NSString *targetMacAddress;
@property (nonatomic, strong) NSString *targetIpAddress;
@property (nonatomic) u_int16_t targetPortNumber;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) useconds_t interval;
@property (nonatomic) NSUInteger amount;
@end
