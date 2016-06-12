//
//  IJTShowMessage.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTShowMessage.h"
#import <FlatUIKit.h>
@implementation IJTShowMessage

+ (SCLAlertView *)baseAlertView {
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
    alert.hideAnimationType = SlideOutToCenter;
    alert.showAnimationType = SlideInFromCenter;
    alert.backgroundType = Blur;
    alert.labelTitle.font = [UIFont boldSystemFontOfSize:20];
    alert.viewText.font = [UIFont systemFontOfSize:14];
    return alert;
}

+ (FUIAlertView *)baseAlertViewWithTitle:(NSString *)title
                                 message:(NSString *)message
                                delegate:(id<FUIAlertViewDelegate>)delegate
                       cancelButtonTitle:(NSString *)cancelButtonTitle
                       otherButtonTitles:(NSString *)otherButtonTitles, ... {
    FUIAlertView *alertView = [[FUIAlertView alloc] initWithTitle:title
                                                          message:message
                                                         delegate:delegate
                                                cancelButtonTitle:cancelButtonTitle
                                                otherButtonTitles:otherButtonTitles, nil];
    
    alertView.titleLabel.textColor = [UIColor cloudsColor];
    alertView.titleLabel.font = [UIFont boldFlatFontOfSize:16];
    alertView.messageLabel.textColor = [UIColor cloudsColor];
    alertView.messageLabel.font = [UIFont flatFontOfSize:14];
    alertView.backgroundOverlay.backgroundColor = [[UIColor cloudsColor] colorWithAlphaComponent:0.8];
    alertView.alertContainer.backgroundColor = [UIColor midnightBlueColor];
    alertView.defaultButtonColor = [UIColor cloudsColor];
    alertView.defaultButtonShadowColor = [UIColor asbestosColor];
    alertView.defaultButtonFont = [UIFont boldFlatFontOfSize:16];
    alertView.defaultButtonTitleColor = [UIColor asbestosColor];
    
    return alertView;
}
@end
