//
//  IJTDetectEventTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/5/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

@interface IJTDetectEventTableViewController : IJTBaseViewController <UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSDictionary *detectEvent;
@property (nonatomic) time_t selectStart;
@property (nonatomic) time_t selectEnd;

@end
