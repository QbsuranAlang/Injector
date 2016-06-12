//
//  IJTShellshockResultTableViewController.h
//  
//
//  Created by 聲華 陳 on 2016/1/2.
//
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTShellshockResultTableViewController : IJTBaseViewController

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *commands;
@property (nonatomic) u_int32_t timeout;

@end
