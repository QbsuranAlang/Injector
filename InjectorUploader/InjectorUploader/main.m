//
//  main.m
//  InjectorUploader
//
//  Created by 聲華 陳 on 2015/6/16.
//  Copyright (c) 2015年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IJTUploader.h"
int main (int argc, const char * argv[])
{

    @autoreleasepool
    {
        BOOL force = NO;
        //because when booting, network connection is not available immediately
        if(!(argc >= 2 && !strcmp(argv[1], "skip")))
            sleep(10);
        if(argc >= 3 && !strcmp(argv[2], "force"))
            force = YES;
        
        [IJTUploader uploadfiles: force];
    }
	return 0;
}

