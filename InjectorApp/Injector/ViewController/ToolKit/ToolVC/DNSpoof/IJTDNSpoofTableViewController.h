//
//  IJTDNSpoofTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTDNSpoofTableViewController : IJTBaseViewController <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *dnsPatternView;
@property (weak, nonatomic) IBOutlet UIView *actionView;

@end
