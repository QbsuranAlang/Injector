//
//  IJTArping.h
//  IJTArping
//
//  Created by 聲華 陳 on 2015/4/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTArping : NSObject

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
 * arping callback function define
 * id self
 * SEL method
 * struct timeval capture timestamp
 * double RTT(ms)
 * NSString * target IP address
 * NSString * target mac address
 * NSString * ethernet source address
 * id object
 */
typedef void (*ArpingCallback)(id, SEL, struct timeval, double, NSString *, NSString *, NSString *, id);

#define ARPING_CALLBACK_SEL @selector(receiveTime:RTT:ipAddress:macAddress:etherSourceAddress:object:)

#define ARPING_CALLBACK_METHOD \
    - (void)receiveTime:(struct timeval)rt \
    RTT: (double)RTT \
    ipAddress:(NSString *)ipAddress \
    macAddress: (NSString *)macAddress \
etherSourceAddress: (NSString *)etherSourceAddress \
    object: (id)object

/**
 * arping目標
 * @param arpingTargetIP 目標IP地址
 * @param timeout 超時
 * @return 成功傳回0, 失敗傳回-1, 超時傳回1
 */
- (int)arpingTargetIP: (NSString *)whereto
              timeout: (u_int32_t)timeout
               target: (id)target
             selector: (SEL)selector
               object: (id)object;

@end
