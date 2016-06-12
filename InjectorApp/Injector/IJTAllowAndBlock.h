//
//  IJTAllowAndBlock.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface IJTAllowAndBlock : NSObject

+ (NSString *)allowFilename;
+ (NSString *)blockFilename;
+ (NSString *)firewallFilename;
+ (NSArray *)allowList;
+ (NSArray *)blockList;
+ (NSDictionary *)firewallList;
+ (BOOL)exsitInAllow: (NSString *)ipAddress;
+ (BOOL)exsitInBlock: (NSString *)ipAddress;
+ (BOOL)newAllow: (NSString *)ipAddress time: (time_t)time displayName: (NSString *)displayName enable: (BOOL)enable;
+ (BOOL)newBlock: (NSString *)ipAddress time: (time_t)time displayName: (NSString *)displayName enable: (BOOL)enable target: (id)target;
+ (BOOL)setEnableAllow: (BOOL)enable ipAddress: (NSString *)ipAddress;
+ (BOOL)setEnableBlock: (BOOL)enable ipAddress: (NSString *)ipAddress target: (id)target;
+ (BOOL)removeAllowIpAddress: (NSString *)ipAddress;
+ (BOOL)removeBlockIpAddress: (NSString *)ipAddress target: (id)target;
+ (NSArray *)createAllowWithJson: (NSString *)json;
+ (NSArray *)createBlockWithJson: (NSString *)json;
+ (BOOL)allowMoveToBlock: (NSString *)ipAddress target: (id)target;
+ (BOOL)blockMoveToAllow: (NSString *)ipAddress target: (id)target;
+ (BOOL)restoreAllowList: (NSArray *)allowList target: (id)target;
+ (BOOL)restoreBlockList: (NSArray *)blockList target: (id)target;
+ (BOOL)restoreFirewallList: (NSDictionary *)firewallList target: (id)target;

@end
