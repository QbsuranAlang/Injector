//
//  IJTLocalNotification.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/11.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTLocalNotification.h"

@implementation IJTLocalNotification

+ (void)pushLocalNotificationMessage: (NSString *)message title: (NSString *)title info: (NSDictionary *)info
{
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    //1秒後通知
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    notification.fireDate = date;
    notification.alertBody = message;
    notification.alertAction = title;
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.applicationIconBadgeNumber =
    [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    notification.userInfo = info;
    notification.soundName = UILocalNotificationDefaultSoundName;
    
    //push notification
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

+ (void)registerLocalNotification
{
    UIApplication *application = [UIApplication sharedApplication];
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
}

+ (void)setBadgeNumber: (NSUInteger)number
{
    UIApplication *application = [UIApplication sharedApplication];
    application.applicationIconBadgeNumber = number;
}
@end
