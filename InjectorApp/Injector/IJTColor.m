//
//  IJTColor.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTColor.h"

@implementation IJTColor

+(UIColor *) darker: (UIColor *)color times:(double)times level:(NSUInteger)level {
    const CGFloat* colors = CGColorGetComponents(color.CGColor);
    UIColor *newColor = color;
    CGFloat red = colors[0]-level/255.*times;
    CGFloat green = colors[1]-level/255.*times;
    CGFloat blue = colors[2]-level/255.*times;
    
    newColor = [UIColor colorWithRed:red > 0 ? red : 0
                               green:green > 0 ? green : 0
                                blue:blue > 0 ? blue : 0
                               alpha:1];
    colors = CGColorGetComponents(newColor.CGColor);
    return newColor;
}

+ (UIColor *)darker: (UIColor *)color times:(double)times {
    return [self darker:color times:times level:25.5];
}

+(UIColor *) lighter: (UIColor *)color times:(double)times level:(NSUInteger)level {
    const CGFloat* colors = CGColorGetComponents(color.CGColor);
    UIColor *newColor = color;
    CGFloat red = colors[0]+level/255.*times;
    CGFloat green = colors[1]+level/255.*times;
    CGFloat blue = colors[2]+level/255.*times;
    
    newColor = [UIColor colorWithRed:red < 1 ? red : 1
                               green:green < 1 ? green : 1
                                blue:blue < 1 ? blue : 1
                               alpha:1];
    colors = CGColorGetComponents(newColor.CGColor);
    return newColor;
}

+ (UIColor *)lighter: (UIColor *)color times:(double)times {
    return [self lighter:color times:times level:25.5];
}

+ (UIColor *)packetColor: (NSString *)packet {
    UIColor *color = nil;
    
    if([packet hasPrefix:@"Other"])
        color = IJTOtherColor;
    else if([packet hasPrefix:@"ARP"])
        color = IJTArpColor;
    else if([packet hasPrefix:@"IP"])
        color = IJTIpColor;
    else if([packet hasPrefix:@"ICMP"] || [packet isEqualToString:@"IGMP"])
        color = IJTIcmpIgmpColor;
    else if([packet hasPrefix:@"TCP"] || [packet hasPrefix:@"UDP"])
        color = IJTTcpUdpColor;
    else if([packet isEqualToString:@"SNAP"] || [packet isEqualToString:@"EAPOL"])
        color = [IJTColor lighter:IJTOtherColor times:2];
    else
        color = IJTOtherelseColor;
    return color;
}
@end
