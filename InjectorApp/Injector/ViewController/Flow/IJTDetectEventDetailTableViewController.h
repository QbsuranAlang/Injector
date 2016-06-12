//
//  IJTDetectEventDetailTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/5/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTDetectEventDetailTableViewController : IJTBaseViewController <PNChartDelegate>

@property (nonatomic, strong) NSMutableDictionary *detectEventDetail;

@end
