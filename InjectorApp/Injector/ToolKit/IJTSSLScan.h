//
//  IJTSSLScan.h
//  IJTSSLScan
//
//  Created by 聲華 陳 on 2015/12/14.
//
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>

@protocol IJTSSLScanDelegate <NSObject>

@required

/**
 * 開socket發生錯誤
 */
- (void)IJTSSLScanCreateSocketFailure: (NSString *)message;

/**
 * 解析hostname發生錯誤
 */
- (void)IJTSSLScanResolveHostnameFailure: (NSString *)message;

/**
 * 超時
 */
- (void)IJTSSLScanConnectTimeout;

/**
 * 填寫Cipher發生錯誤
 */
- (void)IJTSSLScanPopulateCipherFailure: (NSString *)message;

/**
 * 支持的cipher類型
 */
- (void)IJTSSLScanSupportedClientCiphers: (NSArray *)ciphers;

/**
 * 測試renegotiation發生錯誤
 */
- (void)IJTSSLScanTestRenegotiationFailure: (NSString *)message;

/**
 * 測試renegotiation結果
 */
- (void)IJTSSLScanTestRenegotiationResultMessage: (NSString *)message insecure: (BOOL)insecure;

/**
 * 測試compression發生錯誤
 */
- (void)IJTSSLScanTestCompressionFailure: (NSString *)message;

/**
 * 測試compression結果
 */
- (void)IJTSSLScanTestCompressionResultMessage: (NSString *)message disable: (BOOL)disable;

/**
 * 測試heartbleed發生錯誤
 */
- (void)IJTSSLScanTestHeartbleedFailure: (NSString *)message;

/**
 * 測試heartBleed結果
 */
- (void)IJTSSLScanTestHeartbleedResultVersion: (NSString *)version vulnerable: (BOOL)vulnerable;

/**
 * 測試Supported server ciphers發生錯誤
 */
- (void)IJTSSLScanTestSupportedServerCiphersFailure: (NSString *)message;

/**
 * 測試protocol ciphers結果
 */
- (void)IJTSSLScanTestSupportedServerCiphersResultVersion: (NSString *)version preferred: (BOOL)preferred bits: (int)bits cipherId: (NSString *)cipherId cipher: (NSString *)cipher cipher_details: (NSString *)cipher_details;

/**
 * 顯示憑證發生錯誤
 */
- (void)IJTSSLScanShowCertificateFailure: (NSString *)message;

/**
 * 顯示憑證
 */
- (void)IJTSSLScanShowCertificate: (NSString *)certificate verion: (long)version serialNumber: (NSString *)serialNumber signatureAlgorithm :(NSString *)signatureAlgorithm issuer: (NSString *)issuer notValidBefore: (NSString *)notValidBefore notValidAfter: (NSString *)notValidAfter subject: (NSString *)subject publicKeyAlgorithm: (NSString *)publicKeyAlgorithm publicKeyLength: (int)publicKeyLength publicKeyType: (NSString *)publicKeyType publicKeyString: (NSString *)publicKeyString x509v3Extensions: (NSString *)x509v3Extensions verifyCertificate: (NSString *)verifyCertificate;

/**
 * 顯示信任的憑證發生錯誤
 */
- (void)IJTSSLScanShowTrustedCAsFailure: (NSString *)message;

/**
 * 顯示信任的憑證
 */
- (void)IJTSSLScanShowTrustedCAs: (NSArray *)CAs;

@end

@interface IJTSSLScan : NSObject

@property (nonatomic, assign) NSObject<IJTSSLScanDelegate> *delegate;

- (id)init;

/**
 * 設定目標
 * @param setTarget 目標, ip or hostname
 * @param port port
 * @param family AF_INET, AF_INET6
 * @param timeout 超時
 * @return 發生錯誤傳回-1, 成功傳回0
 */
- (int)setTarget: (NSString *)target port: (u_int16_t)port family: (sa_family_t)family timeout: (u_int32_t)timeout;

/**
 * 掃描
 * @return 發生錯誤傳回-1, 成功傳回0
 */
- (int)scan;

/**
 * 停止
 */
- (void)stop;

/**
 * 設定掃描項目
 */
- (void)setGetSupportedClient: (BOOL)getSupportedClient
           testRenegotiation: (BOOL)testRenegotiation
             testCompression: (BOOL)testCompression
              testHeartbleed: (BOOL)testHeartbleed
         testServerSupported: (BOOL)testServerSupported
             showCertificate: (BOOL)showCertificate
              showTrustedCAs: (BOOL)showTrustedCAs;

@end
