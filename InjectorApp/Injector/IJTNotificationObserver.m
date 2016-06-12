//
//  IJTNotificationObserver.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTNotificationObserver.h"
#import <Reachability.h>
@implementation IJTNotificationObserver

+ (void)reachabilityAddObserver:(id)observer selector: (SEL)selector
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:kReachabilityChangedNotification object:nil];
}

+ (void)reachabilityRemoveObserver:(id)observer {
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:kReachabilityChangedNotification object:nil];
}

+ (void)addObserver: (id)observer
           selector: (SEL)selector
               name: (NSString *)name
             object: (id)object {
    NSNotificationCenter *notification = [NSNotificationCenter defaultCenter];
    [notification addObserver:observer selector:selector name:name object:observer];
}

+ (void)removeObserver: (id)observer
                  name: (NSString *)name
                object: (id)object {
    NSNotificationCenter *notification = [NSNotificationCenter defaultCenter];
    [notification removeObserver:observer name:name object:object];
}

+ (void)postNotificationName: (NSString *)name object :(id)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:object];
}

@end
