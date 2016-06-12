//
//  IIJTIfconfig.h
//  IIJTIfconfig
//
//  Created by 聲華 陳 on 2015/7/5.
//
//

#import <Foundation/Foundation.h>

@interface IJTIfconfig : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;

typedef NS_ENUM(unsigned short, IJTIfconfigFlag) {
    IJTIfconfigFlagUp = 0x1,
    IJTIfconfigFlagBroadcast = 0x2,
    IJTIfconfigFlagDebug = 0x4,
    IJTIfconfigFlagLoopback = 0x8,
    IJTIfconfigFlagP2P = 0x10,
    IJTIfconfigFlagSmart = 0x20,
    IJTIfconfigFlagRunning = 0x40,
    IJTIfconfigFlagNoArp = 0x80,
    IJTIfconfigFlagPromisc = 0x100,
    IJTIfconfigFlagAllMulticast = 0x200,
    IJTIfconfigFlagOActive = 0x400,
    IJTIfconfigFlagSimplex = 0x800,
    IJTIfconfigFlagLink0 = 0x1000,
    IJTIfconfigFlagLink1 = 0x2000,
    IJTIfconfigFlagLink2 = 0x4000,
    IJTIfconfigFlagMulticast = 0x8000
};

typedef NS_ENUM(NSInteger, IJTIfconfigType) {
    IJTIfconfigTypeInet4 = 2,
    IJTIfconfigTypeLink = 18,
    IJTIfconfigTypeInet6 = 30
};

/**
 * arptable show callback function define
 * id self
 * SEL method
 * NSString * interface
 * int interface index
 * IJTIfconfigType family
 * NSString * address
 * NSString * netmask
 * NSString * dst address
 * int MTU
 * IJTIfconfigFlag flags
 * BOOL error happened
 * int error Code
 * id object
 */
typedef void (*IfconfigShowCallback)(id, SEL, NSString *, int, IJTIfconfigType, NSString *, NSString *, NSString *, int ,IJTIfconfigFlag, BOOL, int, id);

#define IFCONFIG_SHOW_CALLBACK_SEL @selector(interface:interfaceIndex:family:address:netmask:dstAddress:mtu:flags:errorHappened:errorCode:object:)

#define IFCONFIG_SHOW_CALLBACK_METHOD \
    - (void)interface: (NSString *)interface \
    interfaceIndex: (int)ifindex \
    family: (IJTIfconfigType)family \
    address: (NSString *)address \
    netmask: (NSString *)netmask \
    dstAddress: (NSString *)dstAddress \
    mtu: (int)mtu \
    flags: (IJTIfconfigFlag)flags \
    errorHappened: (BOOL)errorHappened \
    errorCode: (int)errorCode \
    object: (id)object

/**
 * 取得所有interface
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)getAllInterfaceRegisterTarget: (id)target
                            selector: (SEL)selector
                              object: (id)object;

/**
 * 修改MTU大小
 * @param setMtuAtInterface interface
 * @param mtu MTU
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)setMtuAtInterface: (NSString *)interface
                     mtu: (int)mtu;

/**
 * 取得MTU大小
 * @param getMtuAtInterface interface
 * @return 失敗傳回-1, 成功傳回MTU
 */
- (int)getMtuAtInterface: (NSString *)interface;

/**
 * 增加interface的flag
 * @param enableFlagAtInterface interface
 * @param flags flags
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)enableFlagAtInterface: (NSString *)interface
                       flags: (IJTIfconfigFlag)flags;

/**
 * 減少interface的flag
 * @param disableFlagAtInterface interface
 * @param flags flags
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)disableFlagAtInterface: (NSString *)interface
                        flags: (IJTIfconfigFlag)flags;

/**
 * 設定interface的flag
 * @param setFlagAtInterface interface
 * @param flags flags
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)setFlagAtInterface: (NSString *)interface
                    flags: (IJTIfconfigFlag)flags;
/**
 * 取得flag
 * @param getFlagAtInterface interface
 * @return 失敗傳回-1, 成功傳回flags
 */
- (IJTIfconfigFlag)getFlagAtInterface: (NSString *)interface;

/**
 * 修改網卡ipv4地址
 * @param setIpAddressAtInterface interface
 * @param address address
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)setIpAddressAtInterface: (NSString *)interface
                     ipAddress: (NSString *)address;

/**
 * interface flag轉字串
 * @param flags tcp flags
 */
+ (NSString *)interfaceFlags2String: (IJTIfconfigFlag)flags;
@end
