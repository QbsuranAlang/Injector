//
//  IJTWOL.h
//  IJTWOL
//
//  Created by 聲華 陳 on 2015/6/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTWOL : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

/**
 * WOL callback function define
 * id self
 * SEL method
 * struct timeval sent time
 * NSString * mac address
 * NSString * destination address
 * id object
 */
typedef void (*WOLCallback)(id, SEL, struct timeval, NSString *, NSString *, id);

#define WOL_CALLBACK_SEL @selector(timestamp:macAddress:destinationAddress:object:)

#define WOL_CALLBACK_METHOD \
    - (void)timestamp: (struct timeval)sentTime \
    macAddress: (NSString *)macAddress \
    destinationAddress: (NSString *)destinationAddress \
    object: (id)object

/**
 * 送出WOL封包(LAN)
 * @param wakeUpMacAddress 要喚醒的目標mac地址
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)wakeUpMacAddress: (NSString *)macAddress
                 target: (id)target
               selector: (SEL)selector
                 object: (id)object;

/**
 * 送出WOL封包(WAN)
 * @param wakeUpIpAddress 要喚醒的目標ip地址
 * @param macAddress 目標mac地址
 * @param port 要使用的port number
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)wakeUpIpAddress: (NSString *)ipAddress
            macAddress: (NSString *)macAddress
                  port: (u_int16_t)port
                target: (id)target
              selector: (SEL)selector
                object: (id)object;

@end
