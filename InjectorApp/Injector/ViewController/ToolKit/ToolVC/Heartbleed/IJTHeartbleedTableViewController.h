//
//  IJTHeartbleedTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTHeartbleedTableViewController : IJTBaseViewController
@property (weak, nonatomic) IBOutlet UIView *targetView;
@property (weak, nonatomic) IBOutlet UIView *portView;
@property (weak, nonatomic) IBOutlet FUISegmentedControl *typeSegmentedControl;
@property (weak, nonatomic) IBOutlet UIView *timeoutView;
@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet UIView *displayView;

@end
