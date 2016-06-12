//
//  IJTWhoisTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/23.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTWhoisTableViewController : IJTBaseViewController <CZPickerViewDataSource, CZPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *targetView;
@property (weak, nonatomic) IBOutlet UIView *serverView;
@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet UIView *timeoutView;

@end
