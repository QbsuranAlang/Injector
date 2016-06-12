//
//  IJTFirewall.h
//  InjectorFirewall
//
//  Created by 聲華 陳 on 2015/5/25.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IJTFirewallOperator) {
    IJTFirewallOperatorAllow = 0,
    IJTFirewallOperatorBlock
};
typedef NS_ENUM(NSInteger, IJTFirewallDirection) {
    IJTFirewallDirectionInAndOut = 0,
    IJTFirewallDirectionIn,
    IJTFirewallDirectionOut
};
typedef NS_ENUM(NSInteger, IJTFirewallProtocol) {
    IJTFirewallProtocolIP = 0,
    IJTFirewallProtocolICMP = 1,
    IJTFirewallProtocolTCP = 6,
    IJTFirewallProtocolUDP = 17
};
typedef NS_ENUM(unsigned short, IJTFirewallTCPFlag) {
    IJTFirewallTCPFlagFIN = 0x01,
    IJTFirewallTCPFlagSYN = 0x02,
    IJTFirewallTCPFlagRST = 0x04,
    IJTFirewallTCPFlagPUSH = 0x08,
    IJTFirewallTCPFlagACK = 0x10,
    IJTFirewallTCPFlagURG = 0x20,
    IJTFirewallTCPFlagECE = 0x40,
    IJTFirewallTCPFlagCWR = 0x80
};

@interface IJTFirewall : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

/**
 * firewall show callback function define
 * id self
 * SEL method
 * NSString * interface
 * sa_family_t internet family
 * IJTFirewallOperator block or allow
 * IJTFirewallDirection in or out
 * IJTFirewallProtocol TCP, UDP, or ICMP
 * NSString * source ip address
 * NSString * destination ip address
 * NSString * source mask address
 * NSString * destination mask address
 * u_int16_t source start port
 * u_int16_t source end port
 * u_int16_t destination start port
 * u_int16_t destination end port
 * IJTFirewallTCPFlag tcp flag
 * IJTFirewallTCPFlag tcp flag mask
 * u_int8_t icmp type
 * u_int8_t icmp code
 * BOOL keepState keep state?
 * BOOL quick quick?
 * id object
 */
typedef void (*FirewallShowCallback)(id, SEL, NSString *, sa_family_t, IJTFirewallOperator, IJTFirewallDirection, IJTFirewallProtocol, NSString *, NSString *, NSString *, NSString *, u_int16_t, u_int16_t, u_int16_t, u_int16_t, IJTFirewallTCPFlag, IJTFirewallTCPFlag, u_int8_t, u_int8_t, BOOL, BOOL, id);

#define FIREWALL_SHOW_CALLBACK_SEL @selector(ruleAtInterface:family:op:dir:proto:src:dst:srcMask:dstMask:srcStartPort:srcEndPort:dstStartPort:dstEndPort:tcpFlags:tcpFlagsMask:icmpType:icmpCode:keepState:quick:object:)

#define FIREWALL_SHOW_CALLBACK_METHOD \
    - (void)ruleAtInterface: (NSString *)interface \
    family: (sa_family_t)family \
    op: (IJTFirewallOperator)op \
    dir: (IJTFirewallDirection) dir \
    proto: (IJTFirewallProtocol)proto \
    src: (NSString *)src \
    dst: (NSString *)dst \
    srcMask: (NSString *)srcMask \
    dstMask: (NSString *)dstMask \
    srcStartPort: (u_int16_t)srcStartPort \
    srcEndPort: (u_int16_t)srcEndPort \
    dstStartPort: (u_int16_t)dstStartPort \
    dstEndPort: (u_int16_t)dstEndPort \
    tcpFlags: (IJTFirewallTCPFlag)tcpFlags \
    tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask \
    icmpType: (u_int8_t)icmpType \
    icmpCode: (u_int8_t)icmpCode \
    keepState: (BOOL)keepState \
    quick: (BOOL)quick \
    object: (id)object

/**
 * firewall delete callback function define
 * id self
 * SEL method
 * NSString * interface
 * sa_family_t internet family
 * IJTFirewallOperator block or allow
 * IJTFirewallDirection in or out
 * IJTFirewallProtocol TCP, UDP, or ICMP
 * NSString * source ip address
 * NSString * destination ip address
 * NSString * source mask address
 * NSString * destination mask address
 * u_int16_t source start port
 * u_int16_t source end port
 * u_int16_t destination start port
 * u_int16_t destination end port
 * IJTFirewallTCPFlag tcp flag
 * IJTFirewallTCPFlag tcp flag mask
 * u_int8_t icmp type
 * u_int8_t icmp code
 * BOOL keepState keep state?
 * BOOL quick quick?
 * int errorNumber
 * id object
 */
typedef void (*FirewallDeleteCallback)(id, SEL, NSString *, sa_family_t, IJTFirewallOperator, IJTFirewallDirection, IJTFirewallProtocol, NSString *, NSString *, NSString *, NSString *, u_int16_t, u_int16_t, u_int16_t, u_int16_t, IJTFirewallTCPFlag, IJTFirewallTCPFlag, u_int8_t, u_int8_t, BOOL, BOOL, int, id);
#define FIREWALL_DELETE_CALLBACK_SEL @selector(deleteRuleAtInterface:family:op:dir:proto:src:dst:srcMask:dstMask:srcStartPort:srcEndPort:dstStartPort:dstEndPort:tcpFlags:tcpFlagsMask:icmpType:icmpCode:keepState:quick:errorNumber:object:)

#define FIREWALL_DELETE_CALLBACK_METHOD \
    - (void)deleteRuleAtInterface: (NSString *)interface \
    family: (sa_family_t)family \
    op: (IJTFirewallOperator)op \
    dir: (IJTFirewallDirection) dir \
    proto: (IJTFirewallProtocol)proto \
    src: (NSString *)src \
    dst: (NSString *)dst \
    srcMask: (NSString *)srcMask \
    dstMask: (NSString *)dstMask \
    srcStartPort: (u_int16_t)srcStartPort \
    srcEndPort: (u_int16_t)srcEndPort \
    dstStartport: (u_int16_t)dstStartPort \
    dstEndPort: (u_int16_t)dstEndPort \
    tcpFlags: (IJTFirewallTCPFlag)tcpFlags \
    tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask \
    icmpType: (u_int8_t)icmpType \
    icmpCode: (u_int8_t)icmpCode \
    keepState: (BOOL)keepState \
    quick: (BOOL)quick \
    errorNumber: (int)errorNumber \
    object: (id)object

/**
 * 取得所有防火牆規則
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)getAllRulesRegisterTarget: (id)target
                        selector: (SEL)selector
                          object: (id)object;

/**
 * 刪除一筆防火牆規則, from or to any, set addr and mask to 0.0.0.0
 * @param addRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcStartPort source start port
 * @param srcEndPort source end port
 * @param dstStartPort destination start port
 * @param dstEndPort destination end port
 * @param icmpType icmp type
 * @param icmpCode icmp code
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteRuleAtInterface: (NSString *)interface
                          op: (IJTFirewallOperator)op
                         dir: (IJTFirewallDirection)dir
                       proto: (IJTFirewallProtocol)proto
                      family: (sa_family_t)family
                     srcAddr: (NSString *)srcAddr
                     dstAddr: (NSString *)dstAddr
                     srcMask: (NSString *)srcMask
                     dstMask: (NSString *)dstMask
                srcStartPort: (u_int16_t)srcStartPort
                  srcEndPort: (u_int16_t)srcEndPort
                dstStartPort: (u_int16_t)dstStartPort
                  dstEndPort: (u_int16_t)dstEndPort
                    tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                    icmpType: (u_int8_t)icmpType
                    icmpCode: (u_int8_t)icmpCode
                   keepState: (BOOL)keepState
                       quick: (BOOL)quick;

/**
 * 刪除TCP或UDP規則(port有範圍的), from or to any, set addr and mask to 0.0.0.0
 * @param deleteTCPOrUDPRuleAtInterface 網路介面
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcStartPort source start port
 * @param srcEndPort source end port
 * @param dstStartPort destination start port
 * @param dstEndPort destination end port
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteTCPOrUDPRuleAtInterface: (NSString *)interface
                                  op: (IJTFirewallOperator)op
                                 dir: (IJTFirewallDirection)dir
                               proto: (IJTFirewallProtocol)proto
                              family: (sa_family_t)family
                             srcAddr: (NSString *)srcAddr
                             dstAddr: (NSString *)dstAddr
                             srcMask: (NSString *)srcMask
                             dstMask: (NSString *)dstMask
                        srcStartPort: (u_int16_t)srcStartPort
                          srcEndPort: (u_int16_t)srcEndPort
                        dstStartPort: (u_int16_t)dstStartPort
                          dstEndPort: (u_int16_t)dstEndPort
                            tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                        tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                           keepState: (BOOL)keepState
                               quick: (BOOL)quick;

/**
 * 刪除TCP或UDP規則(port無範圍的), from or to any, set addr and mask to 0.0.0.0
 * @param deleteTCPOrUDPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcPort source port
 * @param dstPort destination port
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteTCPOrUDPRuleAtInterface: (NSString *)interface
                                  op: (IJTFirewallOperator)op
                                 dir: (IJTFirewallDirection)dir
                               proto: (IJTFirewallProtocol)proto
                              family: (sa_family_t)family
                             srcAddr: (NSString *)srcAddr
                             dstAddr: (NSString *)dstAddr
                             srcMask: (NSString *)srcMask
                             dstMask: (NSString *)dstMask
                             srcPort: (u_int16_t)srcPort
                             dstPort: (u_int16_t)dstPort
                            tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                        tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                           keepState: (BOOL)keepState
                               quick: (BOOL)quick;

/**
 * 刪除TCP或UDP規則(source port有範圍的), from or to any, set addr and mask to 0.0.0.0
 * @param deleteTCPOrUDPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcStartPort source start port
 * @param srcEndPort source end port
 * @param dstPort destination port
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteTCPOrUDPRuleAtInterface: (NSString *)interface
                                  op: (IJTFirewallOperator)op
                                 dir: (IJTFirewallDirection)dir
                               proto: (IJTFirewallProtocol)proto
                              family: (sa_family_t)family
                             srcAddr: (NSString *)srcAddr
                             dstAddr: (NSString *)dstAddr
                             srcMask: (NSString *)srcMask
                             dstMask: (NSString *)dstMask
                        srcStartPort: (u_int16_t)srcStartPort
                          srcEndPort: (u_int16_t)srcEndPort
                             dstPort: (u_int16_t)dstPort
                            tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                        tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                           keepState: (BOOL)keepState
                               quick: (BOOL)quick;

/**
 * 刪除TCP或UDP規則(destination port有範圍的), from or to any, set addr and mask to 0.0.0.0
 * @param deleteTCPOrUDPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcPort source port
 * @param dstStartPort destination start port
 * @param dstEndPort destination end port
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteTCPOrUDPRuleAtInterface: (NSString *)interface
                                  op: (IJTFirewallOperator)op
                                 dir: (IJTFirewallDirection)dir
                               proto: (IJTFirewallProtocol)proto
                              family: (sa_family_t)family
                             srcAddr: (NSString *)srcAddr
                             dstAddr: (NSString *)dstAddr
                             srcMask: (NSString *)srcMask
                             dstMask: (NSString *)dstMask
                             srcPort: (u_int16_t)srcPort
                        dstStartPort: (u_int16_t)dstStartPort
                          dstEndPort: (u_int16_t)dstEndPort
                            tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                        tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                           keepState: (BOOL)keepState
                               quick: (BOOL)quick;

/**
 * 刪除ICMP規則, from or to any, set addr and mask to 0.0.0.0
 * @param deleteICMPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param icmpType icmp type
 * @param icmpCode icmp code
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteICMPRuleAtInterface: (NSString *)interface
                              op: (IJTFirewallOperator)op
                             dir: (IJTFirewallDirection)dir
                         srcAddr: (NSString *)srcAddr
                         dstAddr: (NSString *)dstAddr
                         srcMask: (NSString *)srcMask
                         dstMask: (NSString *)dstMask
                        icmpType: (u_int8_t)icmpType
                        icmpCode: (u_int8_t)icmpCode
                       keepState: (BOOL)keepState
                           quick: (BOOL)quick;

/**
 * 刪除IP規則, from or to any, set addr and mask to 0.0.0.0
 * @param deleteTCPOrUDPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteRuleAtInterface: (NSString *)interface
                          op: (IJTFirewallOperator)op
                         dir: (IJTFirewallDirection)dir
                      family: (sa_family_t)family
                     srcAddr: (NSString *)srcAddr
                     dstAddr: (NSString *)dstAddr
                     srcMask: (NSString *)srcMask
                     dstMask: (NSString *)dstMask
                   keepState: (BOOL)keepState
                       quick: (BOOL)quick;

/**
 * 刪除所有防火牆規則
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)deleteAllRulesRegisterTarget: (id)target
                           selector: (SEL)selector
                             object: (id)object;

#pragma mark add rule
/**
 * 新增規則, from or to any, set addr and mask to 0.0.0.0
 * @param addRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcStartPort source start port
 * @param srcEndPort source end port
 * @param dstStartPort destination start port
 * @param dstEndPort destination end port
 * @param tcpFlags tcp filter flags
 * @param tcpFlagsMask tcp filter flags mask
 * @param icmpType icmp type
 * @param icmpCode icmp code
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addRuleAtInterface: (NSString *)interface
                       op: (IJTFirewallOperator)op
                      dir: (IJTFirewallDirection)dir
                    proto: (IJTFirewallProtocol)proto
                   family: (sa_family_t)family
                  srcAddr: (NSString *)srcAddr
                  dstAddr: (NSString *)dstAddr
                  srcMask: (NSString *)srcMask
                  dstMask: (NSString *)dstMask
             srcStartPort: (u_int16_t)srcStartPort
               srcEndPort: (u_int16_t)srcEndPort
             dstStartPort: (u_int16_t)dstStartPort
               dstEndPort: (u_int16_t)dstEndPort
                 tcpFlags: (IJTFirewallTCPFlag)tcpFlags
             tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                 icmpType: (u_int8_t)icmpType
                 icmpCode: (u_int8_t)icmpCode
                keepState: (BOOL)keepState
                    quick: (BOOL)quick;

/**
 * 增加TCP或UDP規則(port有範圍的), from or to any, set addr and mask to 0.0.0.0
 * @param addTCPOrUDPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcStartPort source start port
 * @param srcEndPort source end port
 * @param dstStartPort destination start port
 * @param dstEndPort destination end port
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addTCPOrUDPRuleAtInterface: (NSString *)interface
                               op: (IJTFirewallOperator)op
                              dir: (IJTFirewallDirection)dir
                            proto: (IJTFirewallProtocol)proto
                           family: (sa_family_t)family
                          srcAddr: (NSString *)srcAddr
                          dstAddr: (NSString *)dstAddr
                          srcMask: (NSString *)srcMask
                          dstMask: (NSString *)dstMask
                     srcStartPort: (u_int16_t)srcStartPort
                       srcEndPort: (u_int16_t)srcEndPort
                     dstStartPort: (u_int16_t)dstStartPort
                       dstEndPort: (u_int16_t)dstEndPort
                         tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                     tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                        keepState: (BOOL)keepState
                            quick: (BOOL)quick;
/**
 * 增加TCP或UDP規則(port無範圍的), from or to any, set addr and mask to 0.0.0.0
 * @param addTCPOrUDPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcPort source port
 * @param dstPort destination port
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addTCPOrUDPRuleAtInterface: (NSString *)interface
                               op: (IJTFirewallOperator)op
                              dir: (IJTFirewallDirection)dir
                            proto: (IJTFirewallProtocol)proto
                           family: (sa_family_t)family
                          srcAddr: (NSString *)srcAddr
                          dstAddr: (NSString *)dstAddr
                          srcMask: (NSString *)srcMask
                          dstMask: (NSString *)dstMask
                          srcPort: (u_int16_t)srcPort
                          dstPort: (u_int16_t)dstPort
                         tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                     tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                        keepState: (BOOL)keepState
                            quick: (BOOL)quick;

/**
 * 增加TCP或UDP規則(source port有範圍的), from or to any, set addr and mask to 0.0.0.0
 * @param addTCPOrUDPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcStartPort source start port
 * @param srcEndPort source end port
 * @param dstPort destination port
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addTCPOrUDPRuleAtInterface: (NSString *)interface
                               op: (IJTFirewallOperator)op
                              dir: (IJTFirewallDirection)dir
                            proto: (IJTFirewallProtocol)proto
                           family: (sa_family_t)family
                          srcAddr: (NSString *)srcAddr
                          dstAddr: (NSString *)dstAddr
                          srcMask: (NSString *)srcMask
                          dstMask: (NSString *)dstMask
                     srcStartPort: (u_int16_t)srcStartPort
                       srcEndPort: (u_int16_t)srcEndPort
                          dstPort: (u_int16_t)dstPort
                         tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                     tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                        keepState: (BOOL)keepState
                            quick: (BOOL)quick;

/**
 * 增加TCP或UDP規則(destination port有範圍的), from or to any, set addr and mask to 0.0.0.0
 * @param addTCPOrUDPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param srcPort source port
 * @param dstStartPort destination start port
 * @param dstEndPort destination end port
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addTCPOrUDPRuleAtInterface: (NSString *)interface
                               op: (IJTFirewallOperator)op
                              dir: (IJTFirewallDirection)dir
                            proto: (IJTFirewallProtocol)proto
                           family: (sa_family_t)family
                          srcAddr: (NSString *)srcAddr
                          dstAddr: (NSString *)dstAddr
                          srcMask: (NSString *)srcMask
                          dstMask: (NSString *)dstMask
                          srcPort: (u_int16_t)srcPort
                     dstStartPort: (u_int16_t)dstStartPort
                       dstEndPort: (u_int16_t)dstEndPort
                         tcpFlags: (IJTFirewallTCPFlag)tcpFlags
                     tcpFlagsMask: (IJTFirewallTCPFlag)tcpFlagsMask
                        keepState: (BOOL)keepState
                            quick: (BOOL)quick;

/**
 * 增加ICMP規則, from or to any, set addr and mask to 0.0.0.0
 * @param addICMPRuleAtInterface inerface
 * @param op allow or block
 * @param dir in or out
 * @param proto protocol
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param icmpType icmp type
 * @param icmpCode icmp code
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addICMPRuleAtInterface: (NSString *)interface
                           op: (IJTFirewallOperator)op
                          dir: (IJTFirewallDirection)dir
                      srcAddr: (NSString *)srcAddr
                      dstAddr: (NSString *)dstAddr
                      srcMask: (NSString *)srcMask
                      dstMask: (NSString *)dstMask
                     icmpType: (u_int8_t)icmpType
                     icmpCode: (u_int8_t)icmpCode
                    keepState: (BOOL)keepState
                        quick: (BOOL)quick;

/**
 * 增加IP規則, from or to any, set addr and mask to 0.0.0.0
 * @param addTCPOrUDPRuleAtInterface interface
 * @param op allow or block
 * @param dir in or out
 * @param family AF_INET or 0
 * @param srcAddr source address
 * @param dstAddr destination address
 * @param srcMask source mask address
 * @param dstMask destination mask address
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)addRuleAtInterface: (NSString *)interface
                       op: (IJTFirewallOperator)op
                      dir: (IJTFirewallDirection)dir
                   family: (sa_family_t)family
                  srcAddr: (NSString *)srcAddr
                  dstAddr: (NSString *)dstAddr
                  srcMask: (NSString *)srcMask
                  dstMask: (NSString *)dstMask
                keepState: (BOOL)keepState
                    quick: (BOOL)quick;

#pragma mark other rule
/**
 * block整個interface
 * @param blockAtInterface interface
 * @param family AF_INET or 0
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)blockAtInterface: (NSString *)interface
                 family: (sa_family_t)family
              keepState: (BOOL)keepState
                  quick: (BOOL)quick;

/**
 * allow整個interface
 * @param allowAtInterface interface
 * @param family AF_INET or 0
 * @param keepState keep state?
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)allowAtInterface: (NSString *)interface
                 family: (sa_family_t)family
              keepState: (BOOL)keepState
                  quick: (BOOL)quick;

/**
 * 對一個IP完全封鎖
 * @param blockAtInterface interface
 * @param family AF_INET or 0
 * @param ipAddress 要封鎖的IP
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)blockAtInterface: (NSString *)interface
                 family: (sa_family_t)family
              ipAddress: (NSString *)ipAddress
                  quick: (BOOL)quick;

/**
 * 對一個IP解除封鎖
 * @param blockAtInterface interface
 * @param family AF_INET or 0
 * @param ipAddress 要允許的IP
 * @param quick quick?
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)allowAtInterface: (NSString *)interface
                 family: (sa_family_t)family
              ipAddress: (NSString *)ipAddress
                  quick: (BOOL)quick;

/**
 * 產生規則檔案在/var/root/Injector/pf.conf
 * @return 失敗傳回-1, 成功傳回0
 */
//- (int)generateRuleFile;


/**
 * 從/var/root/Injector/pf.conf讀取規則
 * @return 失敗傳回-1, 成功傳回0
 */
//- (int)readFromFile;


/**
 * tail firewall rule by expression text
 * @param rule raw text rule
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)tailRuleByExpression: (NSString *)rule;

/**
 * 開啟防火牆
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)enableFirewall;

/**
 * 關閉防火牆
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)disableFirewall;

/**
 * 清除防火牆
 * @return 失敗傳回-1, 成功傳回0
 */
- (int)clearFirewall;

/**
 * tcp flag轉字串
 * @param flags tcp flags
 */
+ (NSString *)tcpFlags2String: (IJTFirewallTCPFlag)flags;

@end
