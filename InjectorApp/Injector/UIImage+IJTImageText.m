//
//  UIImage+IJTImageText.m
//  Injector
//
//  Created by 聲華 陳 on 2015/5/19.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "UIImage+IJTImageText.h"
#import "IJTColor.h"

@implementation UIImage (IJTImageText)

+(UIImage*)drawText:(NSString*)text inImage:(UIImage*)image atPoint:(CGPoint)point {
    NSMutableAttributedString *textStyle = [[NSMutableAttributedString alloc] initWithString:text];
    
    // text color
    [textStyle addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, textStyle.length)];
    
    // text font
    [textStyle addAttribute:NSFontAttributeName
                      value:[UIFont fontWithName:@"KlavikaLightCaps-SC" size:30]
                      range:NSMakeRange(0, textStyle.length)];
    
    [textStyle addAttribute:NSForegroundColorAttributeName
                      value:IJTWhiteColor
                      range:NSMakeRange(0, textStyle.length)];
    
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor whiteColor] set];
    
    // add text onto the image
    [textStyle drawInRect:CGRectIntegral(rect)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+(UIImage *)blankImage: (CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return blank;
}

@end
