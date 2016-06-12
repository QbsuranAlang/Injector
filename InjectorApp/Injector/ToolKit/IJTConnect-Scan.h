//
//  IJTConnect-Scan.h
//  IJTConnect Scan
//
//  Created by 聲華 陳 on 2015/8/23.
//
//

#import <Foundation/Foundation.h>

@interface IJTConnect_Scan : NSObject

typedef NS_ENUM(u_int8_t, IJTConnect_ScanFlags) {
    IJTConnect_ScanFlagsClose = 0,
    IJTConnect_ScanFlagsOpen = 1
};

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

/**
 * connect scan callback function define
 * id self
 * SEL method
 * u_int16_t port
 * NSString * port name
 * IJTConnect_ScanFlags flags
 * id object
 */
typedef void (*ConnectScanCallback)(id, SEL, u_int16_t, NSString *, IJTConnect_ScanFlags, id);

#define CONNECTSCAN_CALLBACK_SEL @selector(port:portName:flags:object:)

#define CONNECTSCAN_CALLBACK_METHOD \
- (void)port: (u_int16_t)port \
portName: (NSString *)portName \
flags: (IJTConnect_ScanFlags)flags \
object: (id)object

/**
 * 設定目標
 * @param setTarget 目標, ip or hostname
 * @return 發生h_error錯誤傳回-2, 成功傳回0
 */
- (int)setTarget: (NSString *)target;


/**
 * 設定port
 */
- (void)setStartPort: (u_int16_t)startPort endPort: (u_int16_t)endPort;

/**
 * connect掃描
 * @param stop 停止
 * @param port 隨機
 * @param timeout 超時
 * @return 發生錯誤傳回-1, 成功0, host down傳回-2
 */
- (int)connectScanStop: (BOOL *)stop
         randomization: (BOOL)randomization
               timeout: (u_int32_t)timeout
              interval: (useconds_t)interval
                target: (id)target
              selector: (SEL)selector
                object: (id)object;

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
@end
