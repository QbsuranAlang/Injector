//
//  IJTRoutetable.h
//  IJTRoutetable
//
//  Created by 聲華 陳 on 2015/6/6.
//
//

#import <Foundation/Foundation.h>
@interface IJTRoutetable : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;
@property (nonatomic, strong) NSString *errorMessage;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

typedef NS_ENUM(NSInteger, IJTRoutetableType) {
    IJTRoutetableTypeBoth = 0,
    IJTRoutetableTypeInet4 = 2,
    IJTRoutetableTypeInet6 = 30
};

/**
 * route table show callback function define
 * id self
 * SEL method
 * IJTRoutetableType address type
 * NSString * destination hostname
 * NSString * destination ip address
 * NSString * gateway
 * NSString * interface
 * u_short interface index
 * NSString * flags
 * int32_t refs
 * u_int32_t use
 * u_int32_t mtu
 * time_t expire time
 * BOOL dynamic ?
 * id object
 */
typedef void (*RoutetableShowCallback)(id, SEL, IJTRoutetableType, NSString *, NSString *, NSString *, NSString *, u_short, NSString *, int32_t, u_int32_t, u_int32_t, const time_t, BOOL, id);

#define ROUTETABLE_SHOW_CALLBACK_SEL @selector(routeType:destinationHostname:destinaitonIpAddress:gateway:interface:ifindex:flags:refs:use:mtu:expire:dynamic:object:)

#define ROUTETABLE_SHOW_CALLBACK_METHOD \
    - (void)routeType: (IJTRoutetableType)type \
    destinationHostname: (NSString *)destinationHostname \
    destinaitonIpAddress: (NSString *)destinationIpAddress \
    gateway: (NSString *)gateway \
    interface: (NSString *)interface \
    ifindex: (u_short)ifindex \
    flags: (NSString *)flags \
    refs: (int32_t)refs \
    use: (u_int32_t)use \
    mtu: (u_int32_t)mtu \
    expire: (time_t)expire \
    dynamic: (BOOL)dynamic \
    object: (id)object

/**
 * 取得所有route
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)getAllEntriesSkipHostname: (BOOL)skipHostname
                          target: (id)target
                        selector: (SEL)selector
                          object: (id)object;

/**
 * 取得特定gateway的route
 * @param getDestinationByGateway gateway
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)getGatewayByDestinationIpAddress: (NSString *)destination
                                 target: (id)target
                               selector: (SEL)selector
                                 object: (id)object;

/**
 * route table delete callback function define
 * id self
 * SEL method
 * IJTRoutetableType address type
 * NSString * destination hostname
 * NSString * destination ip address
 * NSString * gateway
 * NSString * interface
 * BOOL error happened
 * int errno
 * NSString * errorMessage
 * id object
 */
typedef void (*RoutetableDeleteCallback)(id, SEL, NSString *, NSString *, NSString *, BOOL, int, NSString *, id);

#define ROUTETABLE_DELETE_CALLBACK_SEL @selector(deleteNetwork:hostname:gateway:errorHappened:errorNumber:errorMessage:object:)

#define ROUTETABLE_DELETE_CALLBACK_METHOD \
    - (void)deleteNetwork: (NSString *)network \
    hostname: (NSString *)hostname \
    gateway: (NSString *)gateway \
    errorHappened: (BOOL)errorHappened \
    errorNumber: (int)errorNumber \
    errorMessage: (NSString *)errorMessage \
    object: (id)object

/**
 * 刪除所有route
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteAllEntriesRegisterTarget: (id)target
                             selector: (SEL)selector
                               object: (id)object;

/**
 * 刪除一筆route
 * @param deleteDestinatio route destination presentation, like 127
 * @param gateway gateway presentation, like: default
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteDestination: (NSString *)destination
                 gateway: (NSString *)gateway
                  target: (id)target
                selector: (SEL)selector
                  object: (id)object;

/**
 * 新增一筆路由
 * @param addRouteNetwork 新增網域
 * @param netmask network mask
 * @param gateway gateway
 * @param dynamic need dynamic ?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addRouteNetwork: (NSString *)network
               netmask: (NSString *)netmask
               gateway: (NSString *)gateway
               dynamic: (BOOL)dynamic;

/**
 * 新增一筆路由
 * @param addRouteHost 新增目的
 * @param gateway gateway
 * @param dynamic need dynamic ?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addRouteHost: (NSString *)host
            gateway: (NSString *)gateway
            dynamic: (BOOL)dynamic;

@end
