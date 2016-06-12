//
//  IJTSYNScanResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/12.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTSYNScanResultTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource>

@property (nonatomic, strong) NSString *target;
@property (nonatomic) u_int16_t startPort;
@property (nonatomic) u_int16_t endPort;
@property (nonatomic) BOOL randomization;
@property (nonatomic) u_int32_t timeout;
@property (nonatomic) useconds_t interval;

@end
