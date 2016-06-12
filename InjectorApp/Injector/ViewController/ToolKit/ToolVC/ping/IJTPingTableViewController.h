//
//  IJTPingTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

@interface IJTPingTableViewController : IJTBaseViewController
@property (weak, nonatomic) IBOutlet UIView *targetView;
@property (weak, nonatomic) IBOutlet UIView *sourceView;
@property (weak, nonatomic) IBOutlet UIView *ttlView;
@property (weak, nonatomic) IBOutlet UIView *timeoutView;
@property (weak, nonatomic) IBOutlet UIView *intervalView;
@property (weak, nonatomic) IBOutlet UIView *payloadView;
@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet UIView *amountView;
@property (weak, nonatomic) IBOutlet FUISegmentedControl *sourceSegmentedControl;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (weak, nonatomic) IBOutlet UIView *fragmentView;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *tosButtons;
@property (weak, nonatomic) IBOutlet UIButton *bit1Button;
@property (weak, nonatomic) IBOutlet UIButton *bit2Button;
@property (weak, nonatomic) IBOutlet UIButton *bit3Button;
@property (weak, nonatomic) IBOutlet UIButton *bit4Button;
@property (weak, nonatomic) IBOutlet UIButton *bit5Button;
@property (weak, nonatomic) IBOutlet UIButton *bit6Button;
@property (weak, nonatomic) IBOutlet UIButton *bit7Button;
@property (weak, nonatomic) IBOutlet UIButton *bit8Button;


@end
