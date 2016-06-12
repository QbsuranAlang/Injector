//
//  IJTTCP-Flooding.h
//  IJTTCP Flooding
//
//  Created by 聲華 陳 on 2015/9/8.
//
//

#import <Foundation/Foundation.h>

@interface IJTTCP_Flooding : NSObject

/**
 * tcp flooding callback function define
 * id self
 * SEL method
 * NSString * target IP address
 * u_int16_t target port
 * NSString * source IP address
 * u_int16_t source port
 * id object
 */
typedef void (*TCPFloodingCallback)(id, SEL, NSString *, u_int16_t, NSString *, u_int16_t, id);

#define TCPFLOODING_CALLBACK_SEL @selector(floodingTarget:targetPort:source:sourcePort:object:)

#define TCPFLOODING_CALLBACK_METHOD \
- (void)floodingTarget: (NSString *)target \
targetPort: (u_int16_t)targetPort \
source: (NSString *)source \
sourcePort: (u_int16_t)sourcePort \
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
 * @pram 目的port
 * @return 發生h_error錯誤傳回-2, 成功傳回0
 */
- (int)setTarget: (NSString *)target
 destinationPort: (u_int16_t)port;

/**
 * 送出TCP syn封包
 * @param floodingSourceIpAddress 來源ip, nil等於隨機
 * @param sourcePort 來源port, 0等於隨機
 */
- (int)floodingSourceIpAddress: (NSString *)sourceIpAddress
                    sourcePort: (u_int16_t)sourcePort
                        target: (id)target
                      selector: (SEL)selector
                        object: (id)object;
@end
