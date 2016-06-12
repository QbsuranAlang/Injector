//
//  IJTConnectScanTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/24.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTConnectScanTableViewController : IJTBaseViewController
@property (weak, nonatomic) IBOutlet UIView *targetView;
@property (weak, nonatomic) IBOutlet UIView *startPortView;
@property (weak, nonatomic) IBOutlet UIView *endPortView;
@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet FUISwitch *randSwitch;
@property (weak, nonatomic) IBOutlet UIView *timeoutView;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (weak, nonatomic) IBOutlet UIView *intervalView;

@end
