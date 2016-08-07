//
//  main.m
//  InjectorForeground
//
//  Created by 聲華 陳 on 2015/5/14.
//  Copyright (c) 2015年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <dlfcn.h>
#include <sys/sysctl.h>

static NSString *dictionary2sting(NSDictionary *dictionary, BOOL prettyPrint)
{
    NSError *error;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:(NSJSONWritingOptions)    (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    
    if(jsondata)
        return [[NSString alloc] initWithData:jsondata encoding:NSUTF8StringEncoding];
    else
        return nil;
}
int main (int argc, const char * argv[])
{

    @autoreleasepool
    {
#if 1
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:@"ForDebug" forKey:@"Bundle ID"];
        [dict setObject:@"ForDebug" forKey:@"Process Name"];
        [dict setObject:@"ForDebug" forKey:@"Display Name"];
        [dict setObject:NO ? @"t" : @"f" forKey:@"Screen Lock"];
        NSString *jsonStr = dictionary2sting(dict, NO);
        fprintf(stdout, "%s", [jsonStr UTF8String]);
        return 0;
#else
        
        void * uikit = dlopen("/System/Library/Framework/UIKit.framework/UIKit", RTLD_LAZY);
        
        mach_port_t (*SBSSpringBoardServerPort)() =
        dlsym(uikit, "SBSSpringBoardServerPort");
        mach_port_t *p = SBSSpringBoardServerPort();
        dlclose(uikit);
        void *sbserv = dlopen("/System/Library/PrivateFrameworks/SpringBoardServices.framework/SpringBoardServices", RTLD_LAZY);
        
        bool locked;
        bool passcode;
        void* (*SBGetScreenLockStatus)(mach_port_t* port, bool *lockStatus, bool *passcodeEnabled) = dlsym(sbserv, "SBGetScreenLockStatus");
        SBGetScreenLockStatus(p, &locked, &passcode);
        
        void* (*SBDisplayIdentifierForPID)(mach_port_t* port, int pid,char * result) =
        dlsym(sbserv, "SBDisplayIdentifierForPID");
        void* (*SBFrontmostApplicationDisplayIdentifier)(mach_port_t* port,char * result) = dlsym(sbserv, "SBFrontmostApplicationDisplayIdentifier");
        dlclose(sbserv);
        
        char topapp[256];
        SBFrontmostApplicationDisplayIdentifier(p, topapp);
        NSString *bundleID = [NSString stringWithFormat:@"%s",topapp];
        NSString * (*SBSCopyLocalizedApplicationNameForDisplayIdentifier)(NSString *) =   dlsym(sbserv, "SBSCopyLocalizedApplicationNameForDisplayIdentifier");
        
        NSString *appDisplayName = SBSCopyLocalizedApplicationNameForDisplayIdentifier(bundleID);
        
        //get list of all apps from kernel
        int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
        u_int miblen = 4;
        
        size_t size;
        int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
        
        struct kinfo_proc *process = NULL;
        struct kinfo_proc *newprocess = NULL;
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:@"" forKey:@"Bundle ID"];
        [dict setObject:@"" forKey:@"Process Name"];
        [dict setObject:@"" forKey:@"Display Name"];
        [dict setObject:@"" forKey:@"Screen Lock"];
        
        do {
            size += size / 10;
            newprocess = realloc(process, size);
            if (!newprocess) {
                if (process) {
                    free(process);
                }
                goto BAD;
            }
            process = newprocess;
            st = sysctl(mib, miblen, process, &size, NULL, 0);
        } while (st == -1 && errno == ENOMEM);
        
        NSString *processName = nil;
        BOOL found = NO;
        if (st == 0){
            if (size % sizeof(struct kinfo_proc) == 0) {
                int nprocess = (int)(size / sizeof(struct kinfo_proc));
                if (nprocess) {
                    for (int i = nprocess - 1; i >= 0; i--) {
                        
                        char appid[256];
                        memset(appid, 0, sizeof(appid));
                        int intID = process[i].kp_proc.p_pid;
                        SBDisplayIdentifierForPID(p, intID, appid);
                        
                        NSString *appId = [NSString stringWithFormat:@"%s",appid];
                        
                        if (appId.length != 0 && [bundleID isEqualToString:appId]) {
                            processName = [NSString stringWithFormat:@"%s", process[i].kp_proc.p_comm];
                            [dict setObject:bundleID forKey:@"Bundle ID"];
                            [dict setObject:processName forKey:@"Process Name"];
                            [dict setObject:appDisplayName forKey:@"Display Name"];
                            [dict setObject:locked ? @"t" : @"f" forKey:@"Screen Lock"];
                            found = YES;
                            break;
                        }//end if
                    }//end for
                }//end if
            }//end if
        }//end if
        free(process);
        
        NSString *jsonStr = nil;
        if(!found) {
            [dict setObject:@"com.apple.springboard" forKey:@"Bundle ID"];
            [dict setObject:@"SpringBoard" forKey:@"Process Name"];
            [dict setObject:@"SpringBoard" forKey:@"Display Name"];
            [dict setObject:locked ? @"t" : @"f" forKey:@"Screen Lock"];
        }
        
        jsonStr = dictionary2sting(dict, NO);
        fprintf(stdout, "%s", [jsonStr UTF8String]);
        return 0;
        
    BAD:
        jsonStr = dictionary2sting(dict, NO);
        fprintf(stdout, "%s", [jsonStr UTF8String]);
        return 1;
#endif
    }//end auto release pool
    
}

