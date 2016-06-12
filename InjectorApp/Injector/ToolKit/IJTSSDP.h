//
//  IJTSSDP.h
//  IJTSSDP
//
//  Created by 聲華 陳 on 2015/8/31.
//
//

#import <Foundation/Foundation.h>

#define SSDP_MULTICAST_ADDR @"239.255.255.250"
@interface IJTSSDP : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

/**
 * SSDP callback function define
 * id self
 * SEL selector
 * NSString *source IP address
 * NSString * location
 * NSString * os
 * NSString * os version
 * NSString * upnp
 * NSString * upnp version
 * NSString * product
 * NSString * product version
 * id object
 */
typedef void (*SSDPCallback)(id, SEL, NSString *, NSString *, NSString *, NSString *, NSString *, NSString *, NSString *, NSString *, id);

#define SSDP_CALLBACK_SEL @selector(ssdpSource:location:os:osVersion:upnp:upnpVersion:product:productVersion:object:)
#define SSDP_CALLBACK_METHOD \
- (void)ssdpSource: (NSString *)sourceIpAddress \
    location: (NSString *)location \
    os: (NSString *)os \
    osVersion: (NSString *)osVersion \
    upnp: (NSString *)upnp \
    upnpVersion: (NSString *)upnpVersion \
    product: (NSString *)product \
    productVersion: (NSString *)productVersion \
    object: (id)object

/**
 * 送出封包和讀取ssdp封包
 * @param injectTargetIpAddress 目標ip
 * @param interval inject interval (microsecond)
 * @return 成功傳回0, 失敗傳回-1
 */
- (int)injectTargetIpAddress: (NSString *)ipAddress
                     timeout: (u_int32_t)timeout
                      target: (id)target
                    selector: (SEL)selector
                      object: (id)object;
@end
