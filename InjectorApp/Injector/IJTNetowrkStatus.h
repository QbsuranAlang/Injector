//
//  IJTNetowrkStatus.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Reachability.h>
@interface IJTNetowrkStatus : NSObject

+ (BOOL)supportCellular;
+ (BOOL)supportWifi;
+ (BOOL)checkInterface: (NSString *)interface;
+ (Reachability *)wifiReachability;
+ (Reachability *)cellReachability;
+ (NSString *)getWiFiNetworkAndSlash: (int *)slash;
+ (NSArray *)getWiFiNetworkStartAndEndIpAddress;

+ (NSString *)currentIPAddress: (NSString *)interface;
+ (NSString *)wifiMacAddress;
@end
