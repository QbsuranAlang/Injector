//
//  IJTAddFilterTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

@interface IJTAddFilterTableViewController : IJTBaseViewController

@property (weak, nonatomic) IBOutlet UIView *nameView;
@property (weak, nonatomic) IBOutlet UIView *pcapFilterView;
@property (weak, nonatomic) IBOutlet UILabel *wifiLabel;
@property (weak, nonatomic) IBOutlet CSAnimationView *wifiView;
@property (weak, nonatomic) IBOutlet UILabel *cellLabel;
@property (weak, nonatomic) IBOutlet CSAnimationView *cellView;
@property (weak, nonatomic) IBOutlet FUIButton *addButton;
@property (nonatomic, assign) NSObject<PassValueDelegate> *delegate;

@end
