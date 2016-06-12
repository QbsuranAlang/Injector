//
//  IJTMultiToolViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/11.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTMultiToolViewController : UIViewController <RNFrostedSidebarDelegate>

@property (nonatomic, strong) NSArray *selectedTools;

@end
