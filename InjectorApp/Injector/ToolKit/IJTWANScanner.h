//
//  IJTWANScanner.h
//  IJTWANScanner
//
//  Created by 聲華 陳 on 2015/11/16.
//
//

#import <Foundation/Foundation.h>

@interface IJTWANScanner : NSObject

typedef NS_ENUM(u_int16_t, IJTWANStatusFlags) {
    //IJTWANStatusFlagsMyself = 0x0001,
    //IJTWANStatusFlagsGateway = 0x0002,
    IJTWANStatusFlagsDNS = 0x0001,
    IJTWANStatusFlagsNetbios = 0x0002,
    IJTWANStatusFlagsPing = 0x0004,
    IJTWANStatusFlagsFirewalled = 0x0008
};

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)close;

- (NSString *)getStartIpAddress;
- (NSString *)getEndIpAddress;
- (NSString *)getCurrentIpAddress;

/**
 * 設定掃描範圍
 * @param scafrom 開始IP地址
 * @param to 結束IP地址
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)setFrom: (NSString *)startIpAddress
            to: (NSString *)endIpAddress;

/**
 * 設定掃描IP/slash
 * @param scanNetwork IP/slash的Ip部分
 * @param slash IP/slash的slash部分
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)setNetwork: (NSString *)network
            slash: (int)slash;


/**
 * 設定過濾器
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)setFilterExpression;

/**
 * 開始掃瞄
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)injectWithInterval: (useconds_t)interval;

/**
 * 讀取封包
 * @param timeout 超時
 * @return online list
 */
- (NSArray *)read;

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

@end
