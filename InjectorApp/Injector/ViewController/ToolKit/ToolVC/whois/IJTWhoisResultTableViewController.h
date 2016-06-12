//
//  IJTWhoisResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/23.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTWhoisResultTableViewController : IJTBaseViewController

@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSString *server;
@property (nonatomic) u_int32_t timeout;

@end
