//
//  IJTACK-Scan.h
//  IJTACK Scan
//
//  Created by 聲華 陳 on 2015/9/10.
//
//

#import <Foundation/Foundation.h>

@interface IJTACK_Scan : NSObject

typedef NS_ENUM(u_int8_t, IJTACK_ScanFlags) {
    IJTACK_ScanFlagsUnfiltered = 0,
    IJTACK_ScanFlagsFiltered = 0x01
};

/**
 * ack scan callback function define
 * id self
 * SEL method
 * u_int16_t port
 * NSString *name
 * IJTUDP_ScanFlags flags
 * id object
 */
typedef void (*ACKScanCallback)(id, SEL, u_int16_t, NSString *, IJTACK_ScanFlags, id);

#define ACKSCAN_CALLBACK_SEL @selector(ackScanPort:portName:flags:object:)

#define ACKSCAN_CALLBACK_METHOD \
- (void)ackScanPort: (u_int16_t)port \
portName: (NSString *)portName \
flags: (IJTACK_ScanFlags)flags \
object: (id)object


@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

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
 * 開始送出封包
 * @param injectWithInterval inject interval (microsecond)
 * @param randomization port 隨機
 * @param stop 停止
 * @param timeout udp read timeout
 * @return 成功傳回0, 失敗傳回-1, host down傳回-2
 */
- (int)injectWithInterval: (useconds_t)interval
            randomization: (BOOL)randomization
                     stop: (BOOL *)stop
                  timeout: (u_int32_t)timeout
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




//firewall
- (in_addr_t)openSniffer;

- (int)injectTarget: (NSString *)target
               stop: (BOOL *)stop
               port: (u_int16_t)port
             src_ip: (in_addr_t)src_ip;

- (NSArray *)readPort: (u_int16_t)port
              timeout: (u_int32_t)timeout ;
@end
