//
//  IJTShellshockTableViewController.h
//  
//
//  Created by 聲華 陳 on 2016/1/2.
//
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTShellshockTableViewController : IJTBaseViewController <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *urlView;
@property (weak, nonatomic) IBOutlet UIView *commandView;
@property (weak, nonatomic) IBOutlet UIView *timeoutView;
@property (weak, nonatomic) IBOutlet UIView *actionView;

@end
