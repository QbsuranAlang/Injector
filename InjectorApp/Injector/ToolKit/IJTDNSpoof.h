//
//  IJTDNSpoof.h
//  IJTDNSpoof
//
//  Created by 聲華 陳 on 2015/11/24.
//
//

#import <Foundation/Foundation.h>
#import <resolv.h>
@interface IJTDNSpoof : NSObject

/**
 * DNS spoof callback function define
 * id self
 * SEL selector
 * NSString * source IP address
 * NSString * query name
 * NSString * spoof ip address
 * ns_type address type
 * struct timeval receive time
 * id object
 */
typedef void (*DNSpoofCallback)(id, SEL, NSString *, NSString *, NSString *, ns_type, struct timeval, id);

#define DNSPOOF_LIST_CALLBACK_SEL @selector(dnspoofSource:queryName:spoofIpAddress:type:recvTime:object:)

#define DNSPOOF_LIST_CALLBACK_METHOD \
- (void)dnspoofSource: (NSString *)sourceIpAddress \
queryName: (NSString *)queryName \
spoofIpAddress: (NSString *)spoofIpAddress \
type: (ns_type)type \
recvTime: (struct timeval)recvTime \
object: (id)object

@property (nonatomic) BOOL errorHappened;
@property (nonatomic, strong) NSString *errorMessage;
@property (nonatomic, strong) NSMutableArray *paternArray;

- (id)init;
- (void)dealloc;
- (void)close;


/**
 * 讀取DNS表
 * @param string format
 * Hostname Type IpAddress
 * www.facebook.com A 127.0.0.1
 * *.facebook.com A 127.0.0.1
 * www.facebook.com AAAA ::1
 */
- (void)readPattern: (NSString *)string;

/**
 * 檢查pattrn中幾項合法
 * @return 合法數量
 */
+ (NSUInteger)checkPattern: (NSString *)string;

/**
 * 打開嗅探器
 * 失敗傳回-1, 並設定errorMessage, 成功傳回0
 */
- (int)openSniffer;

- (void)stop;

/**
 * 開啟spoof
 * @return 失敗傳回-1, 成功0
 */
- (int)startRegisterTarget: (id)target
                  selector: (SEL)selector
                    object: (id)object;
@end
