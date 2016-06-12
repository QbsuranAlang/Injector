//
//  IJTWeb.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWeb.h"

@implementation IJTWeb

+ (NSURLRequest *) fileRequest: (NSString *)filename ofType: (NSString *)type
{
    return [NSURLRequest requestWithURL:
            [NSURL fileURLWithPath:
             [[NSBundle mainBundle] pathForResource:filename ofType:type]]];
}

@end
