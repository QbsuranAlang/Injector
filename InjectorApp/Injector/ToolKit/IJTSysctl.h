//
//  IJTSysctl.h
//  IJTSysctl
//
//  Created by 聲華 陳 on 2015/8/1.
//
//

#import <Foundation/Foundation.h>

@interface IJTSysctl : NSObject

/**
 * 取得int類型參數
 * @return 成功傳回數值, 失敗傳回-1
 */
+ (int)sysctlValueByname: (NSString *)name;

/**
 * 設定sysctl數值
 * @param sysctlSetValue value
 * @param name full name
 * @return 成功傳回0, 失敗傳回-1
 */
+ (int)sysctlSetValue: (int)value name: (NSString *)name;

/**
 * 開啟ip forearding功能
 * @return 成功傳回0, 失敗傳回-1
 */
+ (int)setIPForwarding: (BOOL)enable;

/**
 * 取得ip forwarding狀態
 */
+ (int)ipForwarding;

/**
 * 傳回目前支援的設定
 */
+ (NSArray *)suggestSettings;

/**
 * 取得建議設定數值
 * @return 不在建議名單內傳回-1
 */
+ (int)suggestValue: (NSString *)name;

/**
 * 取得原始數值
 * @return 不在建議名單內傳回-1
 */
+ (int)oldValue: (NSString *)name;


/**
 * 盡可能增加
 * @param increaseTo 大小
 */
+ (void)increaseTo: (int)value name: (NSString *)name;
@end
