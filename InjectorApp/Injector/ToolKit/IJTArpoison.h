//
//  IJTArpoison.h
//  IJTArpoison
//
//  Created by 聲華 陳 on 2015/4/18.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTArpoison : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;
@property (nonatomic, strong) NSString *errorMessage;

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
 * arp poison callback function define
 * id self
 * SEL method
 * NSString *target IP
 * NSString *what IP change
 * NSString *change to what mac
 * struct timeval sent timestamp
 * id object
 */
typedef void (*ArpoisonCallback)(id, SEL, NSString *, NSString *, NSString *, NSString *, struct timeval, id);

#define ARPOISON_CALLBACK_SEL @selector(targetIpAddress:targetMacAddress:changeIpAddress:chageMacAddress:sentTimestamp:object:)

#define ARPOISON_CALLBACK_METHOD \
    - (void)targetIpAddress: (NSString *)targetIpAddress \
    targetMacAddress: (NSString *)targetMacAddress \
    changeIpAddress: (NSString *)changeIpAddress \
    chageMacAddress: (NSString *)changeMacAddress \
    sentTimestamp: (struct timeval)sentTimestamp \
    object: (id)object

typedef NS_ENUM(NSInteger, IJTArpoisonArpOp) {
    IJTArpoisonArpOpRequest = 1,
    IJTArpoisonArpOpReply = 2
};


- (NSString *)getStartIpAddress;
- (NSString *)getEndIpAddress;
- (NSString *)getCurrentIpAddress;
- (NSString *)getSkipIpAddress;
/**
 * 設定掃描範圍
 * @param scafrom 開始IP地址
 * @param to 結束IP地址
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)setFrom: (NSString *)startIpAddress
            to: (NSString *)endIpAddress;

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
 * 送出封包
 * @return 成功傳回0, 失敗傳回-1, 目前目標找不到mac address傳回-2
 */
- (int)injectRegisterTarget: (id)target
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

/**
 * 設定arp操作類型
 * @param setArpOperation 操作類型
 */
- (void)setArpOperation: (IJTArpoisonArpOp)op;

/**
 * 設定雙向
 * @param setTwoWayEnabled YES, NO
 */
- (void)setTwoWayEnabled: (BOOL)enabled;

/**
 * 設定sender參數
 * @param setSenderIpAddress sender ip address
 * @param senderMacAddress sender mac address
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)setSenderIpAddress: (NSString *)ipAddress senderMacAddress: (NSString *)macAddress;

/**
 * 準備開始送出
 */
- (void)readyToInject;

/**
 * 儲存ARP表
* @return 成功傳回0, 失敗傳回-1
 */
- (int)storeArpTable;


- (void)moveToNext;
@end
