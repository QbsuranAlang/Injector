//
//  IJTValueChecker.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTValueChecker : NSObject

+ (BOOL)checkIpv4Address: (NSString *)ipAddress;
+ (BOOL)checkIpv6Address: (NSString *)ipAddress;
+ (BOOL)checkNetmask: (NSString *)netmask;
+ (BOOL)checkPort: (NSString *)port;
+ (BOOL)checkPortWithRange: (NSString *)port;
+ (BOOL)checkUint8: (NSString *)string;
+ (BOOL)checkUint16: (NSString *)string;
+ (BOOL)checkAllDigit: (NSString *)string;
+ (BOOL)checkMacAddress: (NSString *)macAddress;
+ (BOOL)checkSlash: (NSString *)slash;
+ (BOOL)check2ByteHexString: (NSString *)type;
+ (BOOL)check4ByteHexString: (NSString *)type;
+ (BOOL)checkBit: (NSString *)bitString width: (int)width;
+ (BOOL)checkURL: (NSString *)urlString;

@end
