//
//  IJTShowMessage.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SCLAlertView.h>
#import <FlatUIKit.h>
@interface IJTShowMessage : NSObject

+ (SCLAlertView *)baseAlertView;
+ (FUIAlertView *)baseAlertViewWithTitle:(NSString *)title
                                 message:(NSString *)message
                                delegate:(id<FUIAlertViewDelegate>)delegate
                       cancelButtonTitle:(NSString *)cancelButtonTitle
                       otherButtonTitles:(NSString *)otherButtonTitles, ...;
@end
