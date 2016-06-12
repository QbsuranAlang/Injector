//
//  IJTNetbios.h
//  IJTNetbios
//
//  Created by 聲華 陳 on 2015/3/31.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTNetbios : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

/**
 * ping callback function define
 * id self
 * SEL method
 * NSArray * name
 * NSArray *group name
 * NSString * Unit ID
 * NSString * source IP
 * id object
 */
typedef void (*NetbiosCallback)(id, SEL, NSArray *, NSArray *, NSString *, NSString *, id);

#define NETBIOS_CALLBACK_SEL @selector(netbiosNames:groupNames:unitID:sourceIpAddress:object:)

#define NETBIOS_CALLBACK_METHOD \
    - (void)netbiosNames: (NSArray *)netbiosNames \
    groupNames:(NSArray *)groupNames \
    unitID: (NSString *)unitID \
    sourceIpAddress: (NSString *)sourceIpAddress \
    object: (id)object

/**
 * 設定掃描整個區域網路
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)setLAN;

/**
 * 設定單一目標
 * @param setOneTarget 目標IP
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)setOneTarget: (NSString *)ipAddress;

/**
 * 開始送出封包
 * @param interval inject interval (microsecond)
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)injectWithInterval: (useconds_t)interval;

- (void)setReadUntilTimeout: (BOOL)enable;
/**
 * 取得要送出的封包數
 * @return 傳回數量
 */
- (u_int64_t)getTotalInjectCount;

/**
 * 取得還有多少封包要送出
 * @return 傳回數量
 */
- (u_int64_t)getRemainInjectCount;

/**
 * 讀取netbios封包
 * @param timeout 超時
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)readTimeout: (u_int32_t)timeout
            target: (id)target
          selector: (SEL)selector
            object: (id)object;

- (NSString *)getStartIpAddress;
- (NSString *)getEndIpAddress;
- (NSString *)getCurrentIpAddress;
@end
