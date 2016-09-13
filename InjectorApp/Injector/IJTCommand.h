//
//  IJTCommand.h
//  Injector
//
//  Created by TUTU on 2016/8/25.
//  Copyright © 2016年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTCommand : NSObject

+ (void)runCommandWithArgument: (NSArray *)parameters;
+ (void)runCommandWithArguments: (char * const *)parameters;
+ (void)restartInjectorDaemon;
+ (void)uploadFlowDataInBackground: (BOOL)background;

@end
