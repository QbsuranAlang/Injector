//
//  IJTFirewallRuleTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTFirewallRuleTableViewController : IJTBaseViewController <PassValueDelegate>

@property (nonatomic, assign) NSObject<PassValueDelegate> *delegate;
@property (nonatomic, strong) NSMutableDictionary *ruleList;
@property (nonatomic) time_t lastTime;

@end
