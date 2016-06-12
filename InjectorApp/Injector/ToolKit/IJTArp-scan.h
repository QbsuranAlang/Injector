//
//  IJTArp-scan.h
//  IJTArp-scan
//
//  Created by 聲華 陳 on 2015/4/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface IJTArp_scan : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

/**
 * 初始化
 * @param initWithInterface network interface
 */
- (id)initWithInterface: (NSString *)interface;
- (void)dealloc;
/**
 * 開啟interface
 * @param open network interface
 */
- (void)open: (NSString *)interface;
- (void)close;

/**
 * arp scan callback function define
 * id self
 * SEL method
 * struct timeval capture timestamp
 * NSString * target IP address
 * NSString * target mac address
 * NSString * ethernet source address
 * id object
 */
typedef void (*ArpscanCallback)(id, SEL, struct timeval, NSString *, NSString *, NSString *, id);

#define ARPSCAN_CALLBACK_SEL @selector(recvTime:ipAddress:macAddress:etherSourceAddress:object:)

#define ARPSCAN_CALLBACK_METHOD \
    - (void)recvTime: (struct timeval)rt \
    ipAddress: (NSString *)ipAddress \
    macAddress: (NSString *)macAddress \
    etherSourceAddress: (NSString *)etherSourceAddress \
    object: (id)object

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
 * 設定掃描整個區域網路
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)setLAN;

/**
 * 開始送出封包
 * @param interval inject interval (microsecond)
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)injectWithInterval: (useconds_t)interval;


/**
 * 讀取arp封包
 * @param timeout 超時
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)readTimeout: (u_int32_t)timeout
            target: (id)target
          selector: (SEL)selector
            object: (id)object;

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
