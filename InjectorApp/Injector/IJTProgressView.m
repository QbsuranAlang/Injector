//
//  IJTProgressView.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTProgressView.h"
#import "IJTColor.h"
#import "UIColor+Crayola.h"

@implementation IJTProgressView

+ (ASProgressPopUpView *)baseProgressPopUpView {
    ASProgressPopUpView *progressView;
    progressView = [[ASProgressPopUpView alloc] initWithFrame:CGRectMake(25, 0, SCREEN_WIDTH - 50, 50)];
    progressView.font = [UIFont systemFontOfSize:28];
    progressView.popUpViewCornerRadius = 12.0;
    progressView.popUpViewAnimatedColors = @[IJTFlowColor, IJTSnifferColor, IJTLANColor, IJTToolsColor, IJTFirewallColor, IJTSupportColor];
    [progressView showPopUpViewAnimated:YES];
    return progressView;
}
@end
