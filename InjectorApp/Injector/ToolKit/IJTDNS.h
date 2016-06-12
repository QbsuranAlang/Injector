//
//  IJTDNS.h
//  IJTDNS
//
//  Created by 聲華 陳 on 2015/6/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>

@interface IJTDNS : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

/**
 * DNS callback function define
 * id self
 * SEL selector
 * NSString * hostname
 * NSString * ipAddress
 * sa_family_t address type
 * id object
 */
typedef void (*DNSCallback)(id, SEL, NSString *, NSString *, sa_family_t, id);

#define DNS_CALLBACK_SEL @selector(dnsHostname:ipAddress:family:object:)

#define DNS_CALLBACK_METHOD \
- (void)dnsHostname: (NSString *)hostname \
ipAddress: (NSString *)ipAddress \
family: (sa_family_t)family \
object: (id)object

/**
 * DNS resolve callback function define
 * id self
 * SEL selector
 * NSString * resolveHostname
 * NSString * name
 * NSString * ip address
 * id object
 */
typedef void (*DNSPTRCallback)(id, SEL, NSString *, NSString *, NSString *, id);

#define DNS_PTR_CALLBACK_SEL @selector(dnsResolveHostname:ipAddress:name:object:)

#define DNS_PTR_CALLBACK_METHOD \
- (void)dnsResolveHostname: (NSString *)resolveHostname \
ipAddress: (NSString *)ipAddress \
name: (NSString *)name \
object: (id)object

/**
 * DNS list callback function define
 * id self
 * SEL selector
 * int index
 * NSString * ip address
 * id object
 */
typedef void (*DNSListCallback)(id, SEL, int, NSString *, id);

#define DNS_LIST_CALLBACK_SEL @selector(dnsServerIndex:dnsServerIpAddress:object:)

#define DNS_LIST_CALLBACK_METHOD \
-(void)dnsServerIndex: (int)index \
dnsServerIpAddress: (NSString *)ipAddress \
object: (id)object

/**
 * hostname轉成IP地址
 * @param hostname2IpAddress 要轉換的hostname
 * @param server DNS server
 * @param ipv4 or ipv6
 * @return 成功傳回0, 失敗傳回-1, 無結果傳回-2
 */
- (int)hostname2IpAddress: (NSString *)hostname
                   server: (NSString *)server
                   family: (sa_family_t)family
                  timeout: (u_int32_t)timeout
                   target: (id)target
                 selector: (SEL)selector
                   object: (id)object;

/**
 * IP地址轉成hostname
 * @param ipAddress2Hostname 要轉換的hostname
 * @param server DNS server
 * @param ipv4 or ipv6
 * @return 成功傳回0, 失敗傳回-1, 無結果傳回-2
 */
- (int)ipAddress2Hostname: (NSString *)ipAddress
                   server: (NSString *)server
                  timeout: (u_int32_t)timeout
                   target: (id)target
                 selector: (SEL)selector
                   object: (id)object;

/**
 * 開始送出封包
 * @param interval inject interval (microsecond)
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)injectWithInterval: (useconds_t)interval
                   server: (NSString *)server
                ipAddress: (NSString *)ipAddress;

- (int)readTimeout: (u_int32_t)timeout
            target: (id)target
          selector: (SEL)selector
            object: (id)object;

- (void)setReadUntilTimeout: (BOOL)enable;
/**
 * hostname轉Ip地址
 * @param family ipv4 or ipv6
 * @return 成功傳回Ip地址, 失敗傳回nil
 */
+ (NSString *)hostname2IpAddress: (NSString *)hostname family: (sa_family_t)family;

/**
 * Ip地址轉hostname
 * @return 成功傳回hostname, 失敗傳回nil
 */
+ (NSString *)ipAddress2Hostname: (NSString *)ipAddress;

/**
 * 取得所有DNS列表
 * @return 成功傳回0, 失敗傳回h_errno
 */
+ (int)getDNSListRegisterTarget: (id)target
                       selector: (SEL)selector
                         object: (id)object;
@end