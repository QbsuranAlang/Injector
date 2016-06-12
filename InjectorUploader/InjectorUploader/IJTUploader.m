//
//  IJTUploader.m
//  InjectorUploader
//
//  Created by 聲華 陳 on 2015/6/16.
//
//

#import "IJTUploader.h"
#include "curl/curl.h"
#import <Reachability.h>
#define PREFERENCELOADER @"/var/mobile/Library/Preferences/tw.edu.mcu.cce.nrl.InjectorPreferenceLoader.plist"
#define PREFERENCELOADER_DEFAULT @"/Library/PreferenceBundles/InjectorPreferenceLoader.bundle/InjectorPreferenceLoader.plist"
#define FLOW_RECEIVE_URL "https://nrl.cce.mcu.edu.tw/injector/dbAccess/InsertPacketFlow.php"
@implementation IJTUploader

static NSArray *arrayOfFoldersInFolder(NSString *folder) {
    NSError *error;
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:&error];
    if(error) {
        NSLog(@"%@", error.localizedDescription);
    }
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for(NSString *file in directoryContents) {
        [arr addObject:[NSString stringWithFormat:@"%@%@", folder, file]];
    }
    
    return error ? nil : arr;
}

+ (void) uploadfiles: (BOOL)froce
{
    if(!froce) {
        id object = plistObject(@"SwitchViaWiFi", 2);
        BOOL switchViaWiFi = YES;
        if(object != nil)
            switchViaWiFi = [object boolValue];
        
        if(switchViaWiFi &&
           [Reachability reachabilityForLocalWiFi].currentReachabilityStatus == NotReachable) {
            printf("wait to wifi\n");
            return;
        }
    }
    
    NSArray *files = arrayOfFoldersInFolder(@"/var/root/Injector/PacketFlowTemp/");
    if(files.count == 0)
        return;
    
    curl_global_init(CURL_GLOBAL_SSL);
    CURL *curlupdatehandle = curl_easy_init();
    if(!curlupdatehandle)
        return;
    
    curl_easy_setopt(curlupdatehandle, CURLOPT_URL, FLOW_RECEIVE_URL);
    curl_easy_setopt(curlupdatehandle, CURLOPT_POST, 1L);
    curl_easy_setopt(curlupdatehandle, CURLOPT_HTTPAUTH, CURLAUTH_ANY);
    curl_easy_setopt(curlupdatehandle, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(curlupdatehandle, CURLOPT_USERAGENT, curl_version());
    curl_easy_setopt(curlupdatehandle, CURLOPT_SSL_VERIFYHOST, 0L);
    curl_easy_setopt(curlupdatehandle, CURLOPT_SSL_VERIFYPEER, 0L);
    
    for(NSString *file in files) {
        FILE *fp = fopen([file UTF8String], "r+");
        char temp[2048];
        if(fp) {
            fgets(temp, sizeof(temp) - 1, fp);
            fclose(fp);
        }
        else
            continue;
        
        curl_easy_setopt(curlupdatehandle, CURLOPT_POSTFIELDS, temp);
        
        if(CURLE_OK == curl_easy_perform(curlupdatehandle)) {
            remove([file UTF8String]);
            printf("remove %s\n", [file UTF8String]);
        }//end if ok
        else
            printf("fail to remove %s\n", [file UTF8String]);
    }//end for
    
    curl_easy_cleanup(curlupdatehandle);
    curl_global_cleanup();
}

static id plistObject(NSString *key, int index)
{
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

@end
