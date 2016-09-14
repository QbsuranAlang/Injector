//
//  IJTCommand.m
//  Injector
//
//  Created by TUTU on 2016/8/25.
//  Copyright © 2016年 Qbsuran Alang. All rights reserved.
//

#import "IJTCommand.h"
#import "IJTDispatch.h"
#import <spawn.h>
#import <Reachability.h>
#import "IJTPreference.h"
extern char **environ;
@implementation IJTCommand : NSObject

+ (void)runCommandWithArgument: (NSArray *)parameters {
    
    pid_t pid;
    char **argv = calloc([parameters count] + 1, sizeof(char *));
    if(!argv) {
        return;
    }//end if
    for(int i = 0 ; i < [parameters count] ; i++) {
        NSString *s = [parameters objectAtIndex:i];
        argv[i] = calloc([s length] + 1, sizeof(char));
        if(argv[i]) {
            memmove(argv[i], [s UTF8String], [s length]);
        }//end if
    }//end for
    argv[[parameters count]] = NULL; //last one must be NULL
    
    posix_spawn(&pid, argv[0], NULL, NULL, argv, environ);
    waitpid(pid, NULL, 0);
    
    for(int i = 0 ; i < [parameters count] + 1; i++) { //include last one
        if(argv[i]) {
            free(argv[i]);
        }//end if
    }//end for
    free(argv);
    
}//end runCommandWithArgument

+ (void)runCommandWithArguments: (char * const *)parameters {
    pid_t pid;
    posix_spawn(&pid, parameters[0], NULL, NULL, parameters, environ);
    waitpid(pid, NULL, 0);
}//end runCommandWithArguments

+ (void)restartInjectorDaemon {
    NSString *plistPath = @"/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorKillDaemon.plist";
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    [dict setObject:@(NO) forKey:@"Disabled"]; //enable, let launchctl useable
    [dict setObject:@(YES) forKey:@"RunAtLoad"]; //enable, let launchctl useable
    [dict writeToFile:plistPath atomically:YES];
    
    NSArray *parameters = @[@"/bin/launchctl", @"load", plistPath];
    [IJTCommand runCommandWithArgument:parameters]; //kill first
    
    [dict setObject:@(YES) forKey:@"Disabled"]; //disable, let launchctl useless
    [dict setObject:@(NO) forKey:@"RunAtLoad"]; //enable, let launchctl useable
    [dict writeToFile:plistPath atomically:YES];
    
    //start daemon
    parameters = @[@"/bin/launchctl", @"load", @"/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorDaemon.plist"];
    sleep(1);
    [IJTCommand runCommandWithArgument:parameters];
}//end restartInjectorDaemon

+ (void)uploadFlowDataInBackground: (BOOL)background {
    NSArray *parameters = nil;
    if(background) {
        parameters = @[@"/bin/launchctl", @"unload", @"/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorUploader.plist"];
        [IJTCommand runCommandWithArgument:parameters];
        parameters = @[@"/bin/launchctl", @"load", @"/Library/LaunchDaemons/tw.edu.mcu.cce.nrl.InjectorUploader.plist"];
        [IJTCommand runCommandWithArgument:parameters];
    }//end if
    else {
        parameters = @[@"/Applications/Injector.app/InjectorUploader", @"skip", @"force"];
        [IJTCommand runCommandWithArgument:parameters];
    }//end else
}//end uploadFlowDataInBackground

@end
