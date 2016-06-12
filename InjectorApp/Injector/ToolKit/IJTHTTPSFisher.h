//
//  IJTHTTPSFisher.h
//  IJTHTTPSFisher
//
//  Created by 聲華 陳 on 2015/12/1.
//
//

#import <Foundation/Foundation.h>

@protocol IJTHTTPSFisherDelegate <NSObject>

@required

/**
 * 伺服器啟動
 */
- (void)IJTHTTPSFisherServerStart;

/**
 * 伺服器停止
 */
- (void)IJTHTTPSFisherServerStop;

/**
 * 開始產生SSL key
 */
- (void)IJTHTTPSFisherGeneratingSSLKey;

/**
 * 產生public key, private key
 */
- (void)IJTHTTPSFisherGeneratedCertificate: (NSString *)certificate
                              publicKey: (NSString *)publicKey
                             privateKey: (NSString *)privateKey;

/**
 * 取回重新導向主機伺服器發生錯誤
 */
- (void)IJTHTTPSFisherRetrieveRedirectHostCertificateFailure: (NSString *)message;

/**
 * 產生key發生錯誤
 */
- (void)IJTHTTPSFisherGeneratedSSLKeyFailure;

/**
 * 開啟security server發生錯誤
 */
- (void)IJTHTTPSFisherInitSecuritySocketServerFailure: (NSString *)message;

/**
 * 儲存封包發生錯誤
 */
- (void)IJTHTTPSFisherSaveToFileFailure: (NSString *)message;

/**
 * 檔案儲存結束
 */
- (void)IJTHTTPSFisherSaveToFileDone: (NSString *)filename outputLocation: (NSString *)outputLocation;

/**
 * Client 連線建立
 */
- (void)IJTHTTPSFisherClientConnectionEstablishedIpAddress: (NSString *)ipAddress port: (u_int16_t)port;

/**
 * Client 關閉連線
 */
- (void)IJTHTTPSFisherClientConnectionClosedIpAddress: (NSString *)ipAddress port: (u_int16_t)port;

/**
 * Accept client失敗
 */
- (void)IJTHTTPSFisherAcceptClientFailure: (NSString *)message;

/**
 * 處理Client發生錯誤
 */
- (void)IJTHTTPSFisherHandleClientFailure: (NSString *)message;

/**
 * client 憑證資訊(如果有的話)
 */
- (void)IJTHTTPSFisherClientCertificateUsing: (NSString *)cipher subject: (NSString *)subject issuer: (NSString *)issuer;

/**
 * server 憑證資訊
 */
- (void)IJTHTTPSFisherServerCertificateUsing: (NSString *)cipher subject: (NSString *)subject issuer: (NSString *)issuer;

/**
 * 傳輸資料發生錯誤
 */
- (void)IJTHTTPSFisherExchangeDataFailure: (NSString *)message;

/**
 * client傳送資料
 */
- (void)IJTHTTPSFisherClientSentData: (char *)data length: (int)length;

/**
 * server傳送資料
 */
- (void)IJTHTTPSFisherServerSentData: (char *)data length: (int)length;


/**
 * 送往client資料
 */
- (void)IJTHTTPSFisherSendToClientData: (char *)data length: (int)length modify: (BOOL)modify;

/**
 * 送往server資料
 */
- (void)IJTHTTPSFisherSendToServerData: (char *)data length: (int)length modify: (BOOL)modify;

/**
 * fork失敗
 */
- (void)IJTHTTPSFisherForkFailure: (NSString *)message;

/**
 * 儲存檔案名稱
 */
- (void)IJTHTTPSFisherSavePacketFilename: (NSString *)filename;

/**
 * 接收到post資料
 */
- (void)IJTHTTPSFisherReceivePOSTData: (char *)data length: (int)length;

@end

@interface IJTHTTPSFisher : NSObject

@property (nonatomic, assign) NSObject<IJTHTTPSFisherDelegate> *delegate;

- (id)init;
- (void)open;
- (void)close;

/**
 * 設定轉向主機
 * @param redirectTo 目標ip address
 * @param hostname 主機名稱
 * @return 發生錯誤傳回-1, 成功傳回0
 */
- (int)redirectTo: (NSString *)ipAddress hostname: (NSString *)hostname;

/**
 * 儲存封包
 * @param setNeedSavefileAndFilter 封包過濾器
 */
- (void)setNeedSavefileAndFilter: (NSString *)filter;

/**
 * 開啟伺服器
 */
- (void)start;

- (void)stop;

+ (void)decodeNSData: (char *)data length: (int)length HTTPHeader: (NSArray **)header HTTPBody: (NSString **)body;
+ (NSString *)httpPost2string: (NSString *)post;

@end