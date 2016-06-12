//
//  IJTArptable.h
//  IJTArptable
//
//  Created by 聲華 陳 on 2015/4/11.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTArptable : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;
@property (nonatomic, strong) NSString *errorMessage;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

typedef NS_ENUM(unsigned char, IJTArptableSockType) {
    IJTArptableSockTypeEther = 0x06,
    IJTArptableSockTypeTokenRing = 0x09,
    IJTArptableSockTypeVLAN = 0x87,
    IJTArptableSockTypeFirewall = 0x90,
    IJTArptableSockTypeFddi = 0xf,
    IJTArptableSockTypeATM = 0x25,
    IJTArptableSockTypeBridge = 0xd1
};

/**
 * arptable show callback function define
 * id self
 * SEL method
 * NSString * hostname
 * NSString * ip address
 * NSString * mac address
 * NSString * interface
 * time_t expire time
 * BOOL is dynamic cache
 * BOOL is proxy only
 * BOOL is ifscope
 * NSString * netmask
 * IJTArptableSockType sdl_type
 * id object
 */
typedef void (*ArptableShowCallback)(id, SEL, NSString *, NSString *, NSString *, NSString *, const time_t, BOOL, BOOL, BOOL, NSString *, IJTArptableSockType, id);

#define ARPTABLE_SHOW_CALLBACK_SEL @selector(arpHostname:ipAddress:macAddress:interface:expireTime:dynamic:proxy:ifscope:netmask:sdl_type:object:)

#define ARPTABLE_SHOW_CALLBACK_METHOD \
    - (void)arpHostname: (NSString *)hostname \
    ipAddress: (NSString *)ipAddress \
    macAddress: (NSString *)macAddress \
    interface: (NSString *)interface \
    expireTime: (u_int32_t)expireTime \
    dynamic: (BOOL)dynamic \
    proxy: (BOOL)proxy \
    ifscope: (BOOL)ifscope \
    netmask: (NSString *)netmask \
    sdl_type: (IJTArptableSockType)sdl_type \
    object: (id)object

/**
 * arptable delete callback function define
 * NSString * ip
 * BOOL error happened
 * int errno
 * NSString * errorMessage
 */
typedef void (*ArptableDeleteCallback)(id, SEL, NSString *, BOOL, int, NSString *, id);

#define ARPTABLE_DELETE_CALLBACK_SEL @selector(deleteIpAddress:errorHappened:errorNumber:errorMessage:object:)

#define ARPTABLE_DELETE_CALLBACK_METHOD \
    - (void)deleteIpAddress: (NSString *)ipAddress \
    errorHappened: (BOOL)errorHappened \
    errorNumber: (int)errorNumber \
    errorMessage: (NSString *)errorMessage \
    object: (id)object

/**
 * 取得所有arp entry
 * @param getAllEntriesSkipHostname 略過hostname
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)getAllEntriesSkipHostname: (BOOL)skipHostname
                          target: (id)target
                        selector: (SEL)selector
                          object: (id)object;
/**
 * 取得特定Ip的mac address
 * @param getMacAddressByIpAddress 要搜尋的IP地址
 * @return 成功傳回mac地址, 失敗傳回nil
 */
- (NSString *)getMacAddressByIpAddress: (NSString *)ipAddress;

/**
 * 取得特定mac address的Ip
 * @param getIpAddressByMacAddress 要搜尋的mac地址
 * @return 成功傳回ip地址, 失敗傳回nil
 */
- (NSString *)getIpAddressByMacAddress: (NSString *)macAddress;


/**
 * sdl type轉成字串
 */
+ (NSString *)sdltype2string: (IJTArptableSockType)type;

/**
 * 刪除所有arp entry
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteAllEntriesRegisterTarget: (id)target
                             selector: (SEL)selector
                               object: (id)object;

/**
 * 刪除特定IP
 * @param deleteIpAddress 要刪除的IP地址
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteIpAddress: (NSString *)ipAddress;

/**
 * 新增一筆arp entry
 * @param addIpAddress 新增的IP address
 * @param macAddress 要新增的mac address
 * @param isstatic 靜態
 * @param ispublished 發布
 * @param isonly only
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addIpAddress: (NSString *)ipAddress
         macAddress: (NSString *)macAddress
           isstatic: (BOOL)isstatic
        ispublished: (BOOL)ispublished
             isonly: (BOOL)isonly;

@end
