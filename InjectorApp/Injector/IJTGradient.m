//
//  IJTGradient.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/9.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTGradient.h"
#import "IJTColor.h"
@implementation IJTGradient

+ (CAGradientLayer *)verticallyGradientColors: (NSArray *)colors
                                        frame: (CGRect)frame {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = frame;
    gradient.colors = colors;
    return gradient;
}

+ (CAGradientLayer *)horizontalGradientColors: (NSArray *)colors
                                        frame: (CGRect)frame
                                   startPoint: (CGPoint)startPoint
                                     endPoint: (CGPoint)endPoint
                                    locations: (NSArray *)locations {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = colors;
    gradient.startPoint = startPoint;
    gradient.endPoint = endPoint;
    gradient.locations = locations;
    gradient.anchorPoint = CGPointZero;
    gradient.frame = frame;
    
    return gradient;
}

+ (UIImage *)radialGradientImage:(CGRect)frame
                           outer:(UIColor*)outer
                           inner:(UIColor*)inner
                          center:(CGPoint)center
                          radius:(float)radius
{
    UIGraphicsBeginImageContext(frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    CGFloat components[8] = { 0,0,0,0,  // Start color
        0,0,0,0 }; // End color
    [outer getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
    [inner getRed:&components[4] green:&components[5] blue:&components[6] alpha:&components[7]];
    
    CGColorSpaceRef myColorspace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef myGradient = CGGradientCreateWithColorComponents (myColorspace, components, locations, num_locations);
    
    CGContextDrawRadialGradient(context, myGradient,
                                center,
                                radius,
                                center,
                                0,
                                0);
    CGContextSaveGState(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    CGGradientRelease(myGradient);
    CGColorSpaceRelease(myColorspace);
    
    return image;
}

+ (void)drawCircle: (UIView *)view color: (UIColor *)color {
    CALayer *layer = view.layer;
    CAGradientLayer *gradient = [CAGradientLayer layer];
    
    //clear
    view.layer.sublayers = nil;
    
    //圓形
    CGFloat width = CGRectGetWidth(view.bounds);
    CGFloat height = CGRectGetHeight(view.bounds);
    
    layer.cornerRadius = MIN(width, height) / 2;
    layer.masksToBounds = YES;
    //邊框
    layer.borderWidth = 1;
    layer.borderColor = [[IJTColor darker:color times:2] CGColor];
    //漸層
    gradient.frame = view.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[color CGColor],
                       (id)[[IJTColor darker:color times:2] CGColor],
                       (id)[[IJTColor lighter:color times:1] CGColor], nil]; // 由上到下的漸層顏色
    [layer insertSublayer:gradient atIndex:0];
}
@end
