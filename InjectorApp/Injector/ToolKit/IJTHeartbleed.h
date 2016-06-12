//
//  IJTHeartbleed.h
//  IJTHeartbleed
//
//  Created by 聲華 陳 on 2015/12/19.
//
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>

@protocol IJTHeartbleedDelegate <NSObject>

@required
/**
 * 開socket發生錯誤
 */
- (void)IJTHeartbleedCreateSocketFailure: (NSString *)message;

/**
 * 解析hostname發生錯誤
 */
- (void)IJTHeartbleedResolveHostnameFailure: (NSString *)message;

/**
 * 超時
 */
- (void)IJTHeartbleedConnectTimeout;

/**
 * 測試heartbleed發生錯誤
 */
- (void)IJTHeartbleedTestHeartbleedFailure: (NSString *)message;

/**
 * 測試heartBleed結果
 */
- (void)IJTHeartbleedTestHeartbleedResultVersion: (NSString *)version vulnerable: (BOOL)vulnerable data: (char *)data length: (u_int16_t)length;

@end

@interface IJTHeartbleed : NSObject

@property (nonatomic, assign) NSObject<IJTHeartbleedDelegate> *delegate;

- (id)init;

/**
 * 設定目標
 * @param setTarget 目標, ip or hostname
 * @param port port
 * @param family AF_INET, AF_INET6
 * @param timeout 超時
 * @return 發生錯誤傳回-1, 成功傳回0
 */
- (int)setTarget: (NSString *)target port: (u_int16_t)port family: (sa_family_t)family timeout: (u_int32_t)timeout;

/**
 * 測試
 * @return 發生錯誤傳回-1, 成功傳回0
 */
- (int)exploit;

/**
 * 停止
 */
- (void)stop;

@end
