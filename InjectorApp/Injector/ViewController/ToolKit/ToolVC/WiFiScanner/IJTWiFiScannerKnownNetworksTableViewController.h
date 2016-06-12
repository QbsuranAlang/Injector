//
//  IJTWiFiScannerKnownNetworksTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/11/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTWiFiScannerKnownNetworksTableViewController : IJTBaseViewController

@property (nonatomic, strong) NSMutableArray *knownNetworks;
@property (nonatomic, weak) IJTWiFiScanner *scanner;

@end
