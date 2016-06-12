//
//  IJTHeartbleedResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTHeartbleedResultTableViewController : IJTBaseViewController <IJTHeartbleedDelegate>

@property (nonatomic, strong) NSString *target;
@property (nonatomic) u_int16_t port;
@property (nonatomic) u_int32_t timeout;
@property (nonatomic) sa_family_t family;
@property (nonatomic) u_int16_t displayLength;

@end
