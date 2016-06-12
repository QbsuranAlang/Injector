//
//  IJTUIImage.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTUIImage.h"

@implementation IJTUIImage

/*
+ (UIImage *)cropImage:(UIImage *)photoimage {
    CGFloat width = photoimage.size.width;
    CGFloat height = photoimage.size.height;
    CGImageRef imgRef = photoimage.CGImage;
    CGImageRef finalImgRef =
    CGImageCreateWithImageInRect(imgRef, CGRectMake(0, height/4., MIN(width, height), MIN(width, height)));
    UIImage *image = [UIImage imageWithCGImage:finalImgRef];
    CGImageRelease(finalImgRef);
    return image;
}*/

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
