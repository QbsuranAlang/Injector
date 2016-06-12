//
//  IJTFormatUITextView.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/26.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTFormatUITextView.h"

@implementation IJTFormatUITextView

+ (CGFloat)textViewHeightForAttributedText: (NSAttributedString *)text andWidth: (CGFloat)width {
    UITextView *calculationView = [[UITextView alloc] init];
    [calculationView setAttributedText:text];
    CGSize size = [calculationView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    return size.height;
}

+ (void)textView: (UITextView *)textView
     selectRange: (NSRange)selectRange
 selectTextColor: (UIColor *)selectTextColor
selectBackgroundColor: (UIColor *)selectBackgroundColor
    inverseRange: (NSRange)inverseRange
inverseTextColor: (UIColor *)inverseTextColor
inverseBackgroundColor: (UIColor *)inverseBackgroundColor
    oneDataWidth: (NSInteger)oneDataWidth {

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[textView attributedText]];
    
    NSInteger realLength = (inverseRange.length * oneDataWidth) + (inverseRange.length - 1);
    NSInteger realLocation = (inverseRange.location) * (oneDataWidth + 1);
    if(realLength <= 0)
        realLength = 0;
    if(realLocation <= 0)
        realLocation = 0;
    if(realLocation + realLength - 1 > attributedString.length) {
        return;
    }
    
    [attributedString addAttribute:NSBackgroundColorAttributeName
                             value:inverseBackgroundColor
                             range:NSMakeRange(realLocation, realLength)];
    
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:inverseTextColor
                             range:NSMakeRange(realLocation, realLength)];
    
    
    realLength = (selectRange.length * oneDataWidth) + (selectRange.length - 1);
    realLocation = (selectRange.location) * (oneDataWidth + 1);
    if(realLength <= 0)
        realLength = 0;
    if(realLocation <= 0)
        realLocation = 0;
    if(realLocation + realLength - 1 > attributedString.length) {
        return;
    }
    
    [attributedString addAttribute:NSBackgroundColorAttributeName
                             value:selectBackgroundColor
                             range:NSMakeRange(realLocation, realLength)];
    
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:selectTextColor
                             range:NSMakeRange(realLocation, realLength)];
    
    textView.attributedText = attributedString;
}

@end
