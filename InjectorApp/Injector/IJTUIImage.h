//
//  IJTUIImage.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface IJTUIImage : NSObject

//+ (UIImage *)cropImage:(UIImage *)photoimage;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end
