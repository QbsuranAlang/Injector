//
//  IJTFormatUITextView.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/26.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface IJTFormatUITextView : NSObject

+ (CGFloat)textViewHeightForAttributedText: (NSAttributedString *)text andWidth: (CGFloat)width;

+ (void)textView: (UITextView *)textView
     selectRange: (NSRange)selectRange
 selectTextColor: (UIColor *)selectTextColor
selectBackgroundColor: (UIColor *)selectBackgroundColor
    inverseRange: (NSRange)inverseRange
inverseTextColor: (UIColor *)inverseTextColor
inverseBackgroundColor: (UIColor *)inverseBackgroundColor
    oneDataWidth: (NSInteger)oneDataWidth;
@end
