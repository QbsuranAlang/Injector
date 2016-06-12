//
//  IJTSSDPResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTSSDPResultTableViewController : IJTBaseViewController

@property (nonatomic) u_int32_t timeout;
@property (nonatomic, strong) NSString *targetIpAddress;
@property (nonatomic) NSInteger selectedIndex;

@end
