//
//  IJTDispatch.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define DISPATCH_DELAY_TIME 0.3f
typedef NS_ENUM(NSInteger, IJTDispatchPriority) {
    IJTDispatchPriorityLow = -2,
    IJTDispatchPriorityDefault = 0,
    IJTDispatchPriorityHigh = 2,
    IJTDispatchPriorityBackground = INT16_MIN
};
@interface IJTDispatch : NSObject

+ (void)dispatch_main_after: (NSTimeInterval)delay block:(void (^)(void))block;
+ (void)dispatch_global: (IJTDispatchPriority)priority block:(void (^)(void))block;
+ (void)dispatch_main: (void (^)(void))block;

+ (dispatch_semaphore_t)dispatch_semaphore_create;
+ (long)dispatch_semaphore_wait: (dispatch_semaphore_t)semaphore timeout: (dispatch_time_t)timeout;
+ (void)dispatch_semaphore_signal: (dispatch_semaphore_t)semaphore;

@end
