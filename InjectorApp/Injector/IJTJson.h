//
//  IJTJson.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/12.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTJson : NSObject

+ (NSDictionary *)file2dictionary :(NSString *)filename;
+ (NSDictionary *)json2dictionary: (NSString *)json;
/**
 * 字典轉json字串
 * @param dictionary 要轉換的字串
 * @param pretyPrint 需不需要加上newline
 * @param 成功傳回字串, 失敗傳回nil
 */
+ (NSString *)dictionary2sting: (NSDictionary *)dictionary prettyPrint: (BOOL)prettyPrint;

/**
 * 陣列轉json字串
 */
+ (NSString *)array2string: (NSArray *)array;

/**
 * json字串轉陣列
 */
+ (NSArray *)json2array: (NSString *)json;

@end
