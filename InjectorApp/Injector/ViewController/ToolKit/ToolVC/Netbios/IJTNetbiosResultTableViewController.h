//
//  IJTNetbiosResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/14.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTNetbiosResultTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource>

@property (nonatomic, strong) NSString *singleIpAddress;
@property (nonatomic) u_int32_t timeout;
@property (nonatomic) useconds_t interval;
@property (nonatomic) NSInteger selectedIndex;

@end
