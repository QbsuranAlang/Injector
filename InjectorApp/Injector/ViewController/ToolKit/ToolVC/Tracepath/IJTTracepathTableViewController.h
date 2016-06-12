//
//  IJTTracepathTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTTracepathTableViewController : IJTBaseViewController
@property (weak, nonatomic) IBOutlet UIView *targetView;
@property (weak, nonatomic) IBOutlet UIView *startTTLView;
@property (weak, nonatomic) IBOutlet UIView *endTTLView;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sourceSegmentedControl;
@property (weak, nonatomic) IBOutlet UIView *sourceView;
@property (weak, nonatomic) IBOutlet UIView *payloadSizeView;
@property (weak, nonatomic) IBOutlet UIView *timeoutView;
@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet UIButton *bit1Button;
@property (weak, nonatomic) IBOutlet UIButton *bit2Button;
@property (weak, nonatomic) IBOutlet UIButton *bit3Button;
@property (weak, nonatomic) IBOutlet UIButton *bit4Button;
@property (weak, nonatomic) IBOutlet UIButton *bit5Button;
@property (weak, nonatomic) IBOutlet UIButton *bit6Button;
@property (weak, nonatomic) IBOutlet UIButton *bit7Button;
@property (weak, nonatomic) IBOutlet UIButton *bit8Button;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;
@property (weak, nonatomic) IBOutlet FUISwitch *resolveHostnameSwitch;
@property (weak, nonatomic) IBOutlet UIView *startPortView;
@property (weak, nonatomic) IBOutlet UITableViewCell *endPortView;

@end
