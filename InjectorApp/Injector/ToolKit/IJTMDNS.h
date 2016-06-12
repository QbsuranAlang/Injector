//
//  IJTMDNS.h
//  IJTMDNS
//
//  Created by 聲華 陳 on 2015/8/15.
//
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>

#define MDNS_MULTICAST_ADDR @"224.0.0.251"
@interface IJTMDNS : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

/**
 * MDNS callback function define
 * id self
 * SEL selector
 * NSString * hostname
 * NSString * ipAddress
 * sa_family_t address type
 * id object
 */
typedef void (*MDNSCallback)(id, SEL, NSString *, NSString *, sa_family_t, id);

#define MDNS_CALLBACK_SEL @selector(mdnsHostname:ipAddress:family:object:)

#define MDNS_CALLBACK_METHOD \
- (void)mdnsHostname: (NSString *)hostname \
ipAddress: (NSString *)ipAddress \
family: (sa_family_t)family \
object: (id)object

/**
 * MDNS resolve callback function define
 * id self
 * SEL selector
 * NSString * resolveHostname
 * NSString * name
 * NSString * ip address
 * id object
 */
typedef void (*MDNSPTRCallback)(id, SEL, NSString *, NSString *, NSString *, id);

#define MDNS_PTR_CALLBACK_SEL @selector(mdnsResolveHostname:name:ipAddress:object:)

#define MDNS_PTR_CALLBACK_METHOD \
- (void)mdnsResolveHostname: (NSString *)resolveHostname \
name: (NSString *)name \
ipAddress: (NSString *)ipAddress \
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

- (void)setReadUntilTimeout: (BOOL)enable;

- (NSString *)getStartIpAddress;
- (NSString *)getEndIpAddress;
- (NSString *)getCurrentIpAddress;

/**
 * hostname轉成IP地址
 * @param hostname2IpAddress 要轉換的hostname
 * @param ipv4 or ipv6
 * @param timeout 超時
 * @return 成功傳回0, 失敗傳回-1, 無結果傳回-2, 超時傳回1
 */
- (int)hostname2IpAddress: (NSString *)hostname
                   family: (sa_family_t)family
                  timeout: (u_int32_t)timeout
                   target: (id)target
                 selector: (SEL)selector
                   object: (id)object;

/**
 * IP地址轉成hostname
 * @param ipAddress2Hostname 要轉換的hostname
 * @param ipv4 or ipv6
 * @param timeout 超時
 * @return 成功傳回0, 失敗傳回-1, 無結果傳回-2, 超時傳回1
 *
- (int)ipAddress2Hostname: (NSString *)ipAddress
                   family: (sa_family_t)family
                  timeout: (u_int32_t)timeout
                   target: (id)target
                 selector: (SEL)selector
                   object: (id)object;*/

@end
