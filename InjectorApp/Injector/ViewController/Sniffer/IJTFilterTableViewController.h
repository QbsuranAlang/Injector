//
//  IJTFilterTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/2/28.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

@interface IJTFilterTableViewController : IJTBaseViewController <PassValueDelegate, SSARefreshControlDelegate>

@property (nonatomic, assign) NSObject<PassValueDelegate> *delegate;
@property (nonatomic, weak) NSString *pcapFilter;
@property (nonatomic) IJTPacketReaderType nowType;

@end
