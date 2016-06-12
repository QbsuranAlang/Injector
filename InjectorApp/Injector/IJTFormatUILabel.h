//
//  IJTFormatUILabel.h
//  Injector
//
//  Created by 聲華 陳 on 2015/5/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface IJTFormatUILabel : NSObject

+ (void)dict: (NSDictionary *)dict
         key: (NSString *)key
      prefix: (NSString *)prefix
       label: (UILabel *)label
       color: (UIColor *)color
        font: (UIFont *)font;

+ (void)dict: (NSDictionary *)dict
         key: (NSString *)key
       label: (UILabel *)label
       color: (UIColor *)color
        font: (UIFont *)font;

+ (void)text: (NSString *)text
       label: (UILabel *)label
       color: (UIColor *)color
        font: (UIFont *)font;


+ (void)text: (NSString *)text
       label: (UILabel *)label
        font: (UIFont *)font;

+ (void) sizeLabel: (UILabel *)label
            toRect: (CGRect)labelRect;
@end
