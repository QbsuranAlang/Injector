//
//  IJTFormatUILabel.m
//  Injector
//
//  Created by 聲華 陳 on 2015/5/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTFormatUILabel.h"

@implementation IJTFormatUILabel

+ (void)dict: (NSDictionary *)dict
         key: (NSString *)key
      prefix: (NSString *)prefix
       label: (UILabel *)label
       color: (UIColor *)color
        font: (UIFont *)font
{
    if(key == nil)
        return;
    
    id value = [dict valueForKey:key];
    if(!value)
        value = @"N/A";
    
    if([value isKindOfClass:[NSNumber class]]) {
        value = [NSString stringWithFormat:@"%lld", [(NSNumber *)value longLongValue]];
    }
    else if([value isKindOfClass:[NSString class]]) {
        if([value isEqualToString:@""])
            value = @"N/A";
    }
    
    NSString *message = [NSString stringWithFormat:@"%@%@", prefix, value];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:message];
    NSRange range = NSMakeRange(prefix.length, message.length - prefix.length);
    [attributedString addAttribute:NSForegroundColorAttributeName
                             value:color
                             range:range];
    
    label.numberOfLines = 0;
    label.text = message;
    label.attributedText = attributedString;
    if(font != nil)
        label.font = font;
}

+ (void)dict: (NSDictionary *)dict
         key: (NSString *)key
       label: (UILabel *)label
       color: (UIColor *)color
        font: (UIFont *)font {
    [IJTFormatUILabel dict:dict
                       key:key
                    prefix:@""
                     label:label
                     color:color
                      font:font];
}

+ (void)text: (NSString *)text
       label: (UILabel *)label
       color: (UIColor *)color
        font: (UIFont *)font {
    label.text = text;
    label.textColor = color;
    label.font = font;
}

+ (void)text: (NSString *)text
       label: (UILabel *)label
        font: (UIFont *)font {
    [IJTFormatUILabel text:text
                     label:label
                     color:[UIColor blackColor]
                      font:font];
}

+ (void) sizeLabel: (UILabel *)label
            toRect: (CGRect)labelRect {
    // Set the frame of the label to the targeted rectangle
    label.frame = labelRect;
    
    // Try all font sizes from largest to smallest font size
    int fontSize = 300;
    int minFontSize = 5;
    
    // Fit label width wize
    CGSize constraintSize = CGSizeMake(label.frame.size.width, MAXFLOAT);
    
    do {
        // Set current font size
        label.font = [UIFont fontWithName:label.font.fontName size:fontSize];
        
        // Find label size for current font size
        CGRect textRect = [[label text] boundingRectWithSize:constraintSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:label.font}
                                                     context:nil];
        
        CGSize labelSize = textRect.size;
        
        // Done, if created label is within target size
        if( labelSize.height <= label.frame.size.height )
            break;
        
        // Decrease the font size and try again
        fontSize -= 2;
        
    } while (fontSize > minFontSize);
}
@end
