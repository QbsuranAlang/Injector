//
//  IJTNotificationObserver.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTNotificationObserver : NSObject

+ (void)reachabilityAddObserver :(id)observer selector :(SEL)selector;
+ (void)reachabilityRemoveObserver:(id)observer;
+ (void)postNotificationName: (NSString *)name object :(id)object;

+ (void)addObserver: (id)observer
           selector: (SEL)selector
               name: (NSString *)name
             object: (id)object;

+ (void)removeObserver: (id)observer
                  name: (NSString *)name
                object: (id)object;

@end
