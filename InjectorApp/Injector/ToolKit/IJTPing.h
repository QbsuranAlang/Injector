//
//  IJTPing.h
//  IJTPing
//
//  Created by 聲華 陳 on 2015/6/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTPing : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

typedef NS_ENUM(u_int8_t, IJTPingTos) {
    IJTPingTos1 = 0x80,
    IJTPingTos2 = 0x40,
    IJTPingTos3 = 0x20,
    IJTPingTosD = 0x10,
    IJTPingTosT = 0x8,
    IJTPingTosR = 0x4,
    IJTPingTosC = 0x2,
    IJTPingTosX = 0x1
};

/**
 * ping callback function define
 * id self
 * SEL method
 * struct timeval capture timestamp
 * NSString * target
 * NSString * receive ip
 * double RTT(ms)
 * int icmp type
 * int icmp code
 * int receive length
 * id object
 */
typedef void (*PingCallback)(id, SEL, struct timeval, NSString *, NSString *, double, int, int, u_int32_t, id);

#define PING_CALLBACK_SEL @selector(receiveTime:target:replyIpAddress:RTT:icmpType:icmpCode:recvlength:object:)
#define PING_CALLBACK_METHOD \
- (void)receiveTime: (struct timeval)rt \
target: (NSString *)target \
replyIpAddress: (NSString *)replyIpAddress \
RTT: (double)rtt \
icmpType: (int)type \
icmpCode: (int)code \
recvlength: (u_int32_t)recvlength \
object: (id)object

/**
 * ping record type callback function define
 * id self
 * SEL method
 * struct timeval capture timestamp
 * NSString * receive ip
 * NSArray * record ip
 * id object
 */
typedef void (*PingRecordTypeCallback)(id, SEL, struct timeval, NSString *, NSArray *,  id);

#define PING_RECORD_TYPE_CALLBACK_SEL @selector(receiveTime:ipAddress:recordIpAddress:object:)

#define PING_RECORD_TYPE_CALLBACK_METHOD \
    - (void)receiveTime: (struct timeval)rt \
    ipAddress: (NSString *)ipAddress \
    recordIpAddress: (NSArray *)recordIpAddress \
    object: (id)object

/**
 * 設定目標
 * @param setTarget 目標, ip or hostname
 * @return 發生h_error錯誤傳回-2, 成功傳回0
 */
- (int)setTarget: (NSString *)target;

/**
 * ping目標
 * @param pingWithTtl TTL
 * @param tos type of service
 * @param fragment 是否可切割
 * @param timeout 超時時間, 單位毫秒
 * @param sourceIP source IP address
 * @param fake 來源IP是否是自己
 * @param recordRoute record route?
 * @param packetSize 封包大小
 * @return 發生error錯誤傳回-1, 成功傳回0, 超時傳回1, 送出假冒來源傳回2
 */
- (int)pingWithTtl: (u_int8_t)ttl
               tos: (IJTPingTos)tos
          fragment: (BOOL)fragment
           timeout: (u_int32_t)timeout
          sourceIP: (NSString *)sourceIP
              fake: (BOOL)fake
       recordRoute: (BOOL)recordRoute
       payloadSize: (u_int32_t)payloadSize
            target: (id)target
          selector: (SEL)selector
            object: (id)object
      recordTarget: (id)recordTarget
    recordSelector: (SEL)recordSelector
      recordObject: (id)recorObject;

/**
 * 送出icmp封包
 * @param interval 間隔
 * @return 成功傳回0,  失敗傳回-1
 */
- (int)injectWithInterval: (useconds_t)interval;

/**
 * 讀取icmp封包
 */
- (int)readTimeout: (u_int32_t)timeout
            target: (id)target
          selector: (SEL)selector
            object: (id)object;
@end

