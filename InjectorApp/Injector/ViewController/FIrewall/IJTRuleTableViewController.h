//
//  IJTRuleTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/6/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTRuleTableViewController : IJTBaseViewController

@property (nonatomic, assign) NSObject<PassValueDelegate> *delegate;
@property (nonatomic, strong) NSMutableArray *ruleList;
@property (nonatomic) time_t lastTime;
@property (nonatomic) IJTFirewallOperator op;

@end
