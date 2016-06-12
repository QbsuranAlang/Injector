//
//  IJTDatabase.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/24.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTDatabase : NSObject

/**
 * 搜尋mac address oui
 * @return oui廠商
 */
+ (NSString *)oui: (NSString *)macAddress;

+ (NSArray *)ouiArray: (NSArray *)macAddresses;

/**
 * port information
 * @param port getservbyport return string
 * @return port information
 */
+ (NSString *)port: (NSString *)portName;
@end
