//
//  IJTPassValueDelegate.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PassValueDelegate <NSObject>

@optional

- (void)callback;
- (void)passValue: (id)value;

@end
