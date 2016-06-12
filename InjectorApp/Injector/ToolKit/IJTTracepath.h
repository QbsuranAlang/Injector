//
//  IJTTracepath.h
//  IJTTracepath
//
//  Created by 聲華 陳 on 2015/4/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#define TRACEPATH_MAXSIZE 65535-20-8
#define TRACEPATH_MIN_PORT 33434
#define TRACEPATH_MAX_PORT 33534
@interface IJTTracepath : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

typedef NS_ENUM(u_int8_t, IJTTracepathTos) {
    IJTTracepathTos1 = 0x80,
    IJTTracepathTos2 = 0x40,
    IJTTracepathTos3 = 0x20,
    IJTTracepathTosD = 0x10,
    IJTTracepathTosT = 0x8,
    IJTTracepathTosR = 0x4,
    IJTTracepathTosC = 0x2,
    IJTTracepathTosX = 0x1
};

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

/**
 * tracepath timeout callback function define
 * id self
 * SEL method
 * int numberOfUDP
 * int TTL
 * struct timeval timestamp
 * id object
 */
typedef void (*TracepathTimeoutCallback)(id, SEL, int, int, struct timeval, id);

#define TRACEPATH_CALLBACK_TIMEOUT_SEL @selector(numberOfUDP:timeoutTTL:timestamp:object:)

#define TRACEPATH_CALLBACK_TIMEOUT_METHOD \
    - (void)numberOfUDP: (int)numberOfUDP \
    timeoutTTL: (int)TTL \
    timestamp: (struct timeval)timestamp \
    object: (id)object

/**
 * tracepath callback function define
 * id self
 * SEL method
 * int number of udp
 * BOOL found
 * NSString * IP address
 * NSString * hostname
 * double RTT
 * int TTL
 * int icmp type
 * int icmp code
 * int recv length
 * id object
 */
typedef void (*TracepathCallback)(id, SEL, int, BOOL, NSString *, NSString *, double, int, int, int, int, id);

#define TRACEPATH_CALLBACK_SEL @selector(numberOfUDP:found:ipAddress:hostname:RTT:TTL:type:code:recvlength:object:)

#define TRACEPATH_CALLBACK_METHOD \
    - (void)numberOfUDP:(int)numberOfUDP \
    found:(BOOL)found \
    ipAddress: (NSString *)ipAddress \
    hostname: (NSString *)hostname \
    RTT: (double)RTT \
    TTL: (int)TTL \
    type: (int)type \
    code: (int)code \
    recvlength: (int)recvlength \
    object: (id)object

/**
 * 設定目標
 * @param setTarget 目標, ip or hostname
 * @return 發生h_error錯誤傳回-2, 成功傳回0
 */
- (int)setTarget: (NSString *)target;

/**
 * 設定port
 * @param setStartPort 起始port
 * @param endPort 結束port
 */
- (void)setStartPort: (u_int16_t)startPort endPort: (u_int16_t)endPort;
/**
 * trace目標
 * @param traceStartTTL 開始的TTL
 * @param maxTTL 最大的TTL
 * @param tos type of service
 * @param timeout 超時
 * @param sourceIP 來源IP
 * @param payloadSize payload長度
 * @param stop 停止
 * @param skipHostname 不解析主機
 * @return 發生錯誤傳回-1, 成功0
 */
- (int)traceStartTTL: (u_int8_t)startTTL
              maxTTL: (u_int8_t)maxTTL
                 tos: (u_int8_t)tos
             timeout: (u_int32_t)timeout
            sourceIP: (NSString *)sourceIP
         payloadSize: (u_int32_t)payload
                stop: (BOOL *)stop
        skipHostname: (BOOL)skipHostname
          targetRecv: (id)targetRecv
        selectorRecv: (SEL)selectorRecv
          objectRecv: (id)objectRecv
       targetTimeout: (id)targetTimeout
     selectorTimeout: (SEL)selectorTimeout
       objectTimeout: (id)objectTimeout;


@end
