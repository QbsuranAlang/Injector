//
//  IJTOpenSSL.h
//  Injector
//
//  Created by 聲華 陳 on 2015/11/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <openssl/ossl_typ.h>
@interface IJTOpenSSL : NSObject

+ (NSString *)md5FromString:(NSString *)string;

+ (NSString *)sha256FromString:(NSString *)string;

+ (NSString *)base64FromString:(NSString *)string encodeWithNewlines:(BOOL)encodeWithNewlines;

/*
 * 產生公鑰私鑰
 * @param generateCertificatePath 憑證path
 * @param publicKeyPath public key path
 * @param privateKeyPath private key path
 * @param hostname hostname
 * @param subject subject
 * @param issuer issuser
 * @param 成功傳回0, 失敗-1
 */
+ (int)generateCertificatePath: (NSString *)certificatePath
                 publicKeyPath: (NSString *)publicKeyPath
                privateKeyPath: (NSString *)privateKeyPath
                      hostname: (NSString *)hostname
                       subject: (X509_NAME *)subject
                       issuser: (X509_NAME *)issuser;

@end
