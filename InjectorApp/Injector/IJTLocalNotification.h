//
//  IJTLocalNotification.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/11.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface IJTLocalNotification : NSObject

+ (void)pushLocalNotificationMessage: (NSString *)message title: (NSString *)title info: (NSDictionary *)info;
+ (void)registerLocalNotification;
+ (void)setBadgeNumber: (NSUInteger)number;

@end
