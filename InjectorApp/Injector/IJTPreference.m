//
//  IJTPreference.m
//  Injector
//
//  Created by TUTU on 2016/9/14.
//  Copyright © 2016年 Qbsuran Alang. All rights reserved.
//

#import "IJTPreference.h"

@implementation IJTPreference : NSObject

#define PREFERENCELOADER @"/var/mobile/Library/Preferences/tw.edu.mcu.cce.nrl.InjectorPreferenceLoader.plist"
#define PREFERENCELOADER_DEFAULT @"/Library/PreferenceBundles/InjectorPreferenceLoader.bundle/InjectorPreferenceLoader.plist"

static id plistObject(NSString *key, int index) {
    NSDictionary *plist =
    [[NSDictionary alloc] initWithContentsOfFile:PREFERENCELOADER];
    id object = nil;
    
    if(plist) {
        object = [plist valueForKey:key];
    }
    
    if(object == nil) {
        plist = [[NSDictionary alloc] initWithContentsOfFile:PREFERENCELOADER_DEFAULT];
        NSArray *items = [plist valueForKey:@"items"];
        object = [items[index] valueForKey:@"default"];
    }
    
    return object;
}

+ (BOOL)viaWiFi {
    id object = plistObject(@"SwitchViaWiFi", 2);
    BOOL switchViaWiFi = YES;
    if(object != nil)
        switchViaWiFi = [object boolValue];
    return switchViaWiFi;
}//end viaWiFi

@end
