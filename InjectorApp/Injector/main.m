//
//  main.m
//  Injector
//
//  Created by 聲華 陳 on 2015/2/27.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
int main(int argc, char * argv[]) {
    @autoreleasepool {
        /*don't use this, it will casue SpringBoard crash !  *
         *setuid(0);                                         *
         *setgid(0);                                         */
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}