//
//  IJTAddArpCacheTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/14.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTAddArpCacheTableViewController : IJTBaseViewController
@property (weak, nonatomic) IBOutlet UIView *ipAddressView;
@property (weak, nonatomic) IBOutlet UIView *macAddressView;
@property (weak, nonatomic) IBOutlet FUISwitch *staticSwitch;
@property (weak, nonatomic) IBOutlet FUISwitch *publishedSwitch;
@property (weak, nonatomic) IBOutlet FUISwitch *onlySwitch;

- (IBAction)addArpCache:(id)sender;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@property (nonatomic, assign) NSObject<PassValueDelegate> *delegate;

@end
