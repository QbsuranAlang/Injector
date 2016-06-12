//
//  IJTWeb.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTWeb : NSObject

+ (NSURLRequest *) fileRequest: (NSString *)filename ofType: (NSString *)type;

@end
