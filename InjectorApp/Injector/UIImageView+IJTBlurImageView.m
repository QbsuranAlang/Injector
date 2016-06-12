//
//  UIImageView+IJTBlurImageView.m
//  Injector
//
//  Created by 聲華 陳 on 2015/5/19.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "UIImageView+IJTBlurImageView.h"

@implementation UIImageView (IJTBlurImageView)

-(void)blurWithAlpha:(CGFloat)alpha radius: (CGFloat)radius {
    UIImageView *input = self;
    CIContext *context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];
    CIImage *inputImage = [[CIImage alloc] initWithImage:input.image];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    [filter setValue:[NSNumber numberWithFloat:radius] forKey:@"inputRadius"];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef cgImage = [context createCGImage:result fromRect:[result extent]];
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    input.image = image;
    input.alpha = alpha;
}

@end
