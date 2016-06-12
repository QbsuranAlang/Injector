//
//  IJTTracepathResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTTracepathResultTableViewController : IJTBaseViewController

@property (nonatomic, strong) NSString *target;
@property (nonatomic, strong) NSString *sourceIpAddress;
@property (nonatomic) u_int8_t startTTL;
@property (nonatomic) u_int8_t endTTL;
@property (nonatomic) IJTTracepathTos tos;
@property (nonatomic) u_int16_t payloadSize;
@property (nonatomic) u_int32_t timeout;
@property (nonatomic) BOOL resolveHostname;
@property (nonatomic) u_int16_t startPort;
@property (nonatomic) u_int16_t endPort;

@end
