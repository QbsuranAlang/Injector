//
//  UIImage+IJTImageText.h
//  Injector
//
//  Created by 聲華 陳 on 2015/5/19.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (IJTImageText)

+(UIImage*)drawText:(NSString*)text inImage:(UIImage*)image atPoint:(CGPoint)point;
+(UIImage *)blankImage: (CGSize)size;

@end
