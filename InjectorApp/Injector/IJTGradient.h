//
//  IJTGradient.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/9.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface IJTGradient : NSObject

+ (CAGradientLayer *)verticallyGradientColors: (NSArray *)colors
                                        frame: (CGRect)frame;

+ (CAGradientLayer *)horizontalGradientColors: (NSArray *)colors
                                        frame: (CGRect)frame
                                   startPoint: (CGPoint)startPoint
                                     endPoint: (CGPoint)endPoint
                                    locations: (NSArray *)locations;


/**
 * radial gradient
 * @param radialGradientImage image frame
 * @param outer outer color
 * @param inner inner color
 * @param center where is center point
 * @param radius draw radius
 */
+ (UIImage *)radialGradientImage:(CGRect)frame
                           outer:(UIColor*)outer
                           inner:(UIColor*)inner
                          center:(CGPoint)center
                          radius:(float)radius;

+ (void)drawCircle: (UIView *)view color: (UIColor *)color;
@end
