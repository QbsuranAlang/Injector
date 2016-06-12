//
//  IJTMDNSResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTMDNSResultTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource>


@property (nonatomic) NSInteger typeSelectedIndex;
@property (nonatomic) NSInteger targetSelectedIndex;
@property (nonatomic, strong) NSString *type;
@property (nonatomic) u_int32_t timeout;
@property (nonatomic) useconds_t interval;
@property (nonatomic, strong) NSString *target;
//@property (nonatomic) BOOL isLAN;

@end
