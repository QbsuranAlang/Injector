//
//  IJTLANScanTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

@interface IJTLANScanTableViewController : IJTBaseViewController <ASProgressPopUpViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSString *startIp;
@property (nonatomic, strong) NSString *endIp;
@property (nonatomic, strong) NSString *ssid;
@property (nonatomic, strong) NSString *bssid;
@property (nonatomic) BOOL startScan;
@property (nonatomic, assign) NSObject<PassValueDelegate> *delegate;
@property (nonatomic, strong) NSArray *historyArray;

@end
