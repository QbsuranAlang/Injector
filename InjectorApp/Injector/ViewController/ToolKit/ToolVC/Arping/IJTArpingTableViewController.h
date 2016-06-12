//
//  IJTArpingTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

@interface IJTArpingTableViewController : IJTBaseViewController
@property (weak, nonatomic) IBOutlet UIView *targetView;
@property (weak, nonatomic) IBOutlet UIView *amountView;
@property (weak, nonatomic) IBOutlet UIView *timeoutView;
@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet UIView *intervalView;

@end
