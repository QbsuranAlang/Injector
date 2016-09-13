//
//  IJTHTTP.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/12.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTHTTP.h"
#import "IJTDispatch.h"
#define BASEURL @"https://nrl.cce.mcu.edu.tw/injector/dbAccess/"

@implementation NSURLRequest (NSURLRequestWithIgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}

@end

@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation IJTHTTP

+ (void)retrieveFrom: (NSString *)path post:(NSString *)post timeout: (NSTimeInterval)timeout block:(void (^)(NSData *data))block
{
    [NSURLRequest allowsAnyHTTPSCertificateForHost: path]; //可以使用https網站
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:path];
    path = [NSString stringWithFormat:@"%@%@", BASEURL, path];
    NSURL *url = [NSURL URLWithString: path];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:url cachePolicy:
                                    NSURLRequestUseProtocolCachePolicy
                                    timeoutInterval:3];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:timeout];
    
    //設定参数
    NSData *data = [post dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[post length]]
                              forHTTPHeaderField:@"Content-Length"];
    //上傳資料
    dispatch_semaphore_t semaphore = [IJTDispatch dispatch_semaphore_create];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = timeout;
    sessionConfig.timeoutIntervalForResource = timeout;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(block)
            block(data);
        [IJTDispatch dispatch_semaphore_signal:semaphore];
    }] resume];
    [IJTDispatch dispatch_semaphore_wait:semaphore timeout:DISPATCH_TIME_FOREVER];
}

+ (void)retrieveFrom: (NSString *)path postDict:(NSDictionary *)postDict timeout: (NSTimeInterval)timeout block:(void (^)(NSData *data))block {
    [NSURLRequest allowsAnyHTTPSCertificateForHost: path]; //可以使用https網站
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:path];
    
    path = [NSString stringWithFormat:@"%@%@", BASEURL, path];
    NSURL *url = [NSURL URLWithString: path];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:url cachePolicy:
                                    NSURLRequestUseProtocolCachePolicy
                                    timeoutInterval:3];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:timeout];
    
    //設定参数
    NSData *data = [NSJSONSerialization dataWithJSONObject:postDict options:0 error:nil];
    [request setHTTPBody:data];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[data length]] forHTTPHeaderField:@"Content-Length"];
    
    //上傳資料
    dispatch_semaphore_t semaphore = [IJTDispatch dispatch_semaphore_create];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = timeout;
    sessionConfig.timeoutIntervalForResource = timeout;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(block)
            block(data);
        [IJTDispatch dispatch_semaphore_signal:semaphore];
    }] resume];
    [IJTDispatch dispatch_semaphore_wait:semaphore timeout:DISPATCH_TIME_FOREVER];
}

+ (NSString *)string2post: (NSString *)string {
    //http://www.w3schools.com/tags/ref_urlencode.asp
    NSString *output = [NSString stringWithString:string];
    NSArray *key = @[@"!", @"#", @"&", @"\'", @"(", @")", @"*", @"+", @",", @"/", @":", @";", @"=", @"?", @"@", @"[", @"]"];
    NSArray *value = @[@"%21", @"%23", @"%26", @"%27", @"%28", @"%29", @"%2A", @"%2B", @"%2C", @"%2F", @"%3A", @"%3B", @"%3D", @"%3F", @"%40", @"%5B", @"%5D"];
    for(int i = 0 ; i < key.count ; i++) {
        output = [output stringByReplacingOccurrencesOfString:key[i] withString:value[i]];
    }
    
    return output;
}

+ (NSString *)post2string: (NSString *)post {
    //http://en.wikipedia.org/wiki/Percent-encoding
    NSString *output = [NSString stringWithString:post];
    NSArray *value = @[@"!", @"#", @"&", @"\'", @"(", @")", @"*", @"+", @",", @"/", @":", @";", @"=", @"?", @"@", @"[", @"]"];
    NSArray *key = @[@"%21", @"%23", @"%26", @"%27", @"%28", @"%29", @"%2A", @"%2B", @"%2C", @"%2F", @"%3A", @"%3B", @"%3D", @"%3F", @"%40", @"%5B", @"%5D"];
    for(int i = 0 ; i < key.count ; i++) {
        output = [output stringByReplacingOccurrencesOfString:key[i] withString:value[i]];
    }
    
    return output;
}

+ (void)getFrom: (NSString *)path timeout: (NSTimeInterval)timeout block:(void (^)(NSData *data))block
{
    [NSURLRequest allowsAnyHTTPSCertificateForHost: path];
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:path]; //可以使用https網站
    NSURL *url = [NSURL URLWithString: path];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:url cachePolicy:
                                    NSURLRequestUseProtocolCachePolicy
                                    timeoutInterval:3];
    [request setTimeoutInterval:timeout];
    
    //設定参数
    
    //上傳資料
    dispatch_semaphore_t semaphore = [IJTDispatch dispatch_semaphore_create];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = timeout;
    sessionConfig.timeoutIntervalForResource = timeout;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(block)
            block(data);
        [IJTDispatch dispatch_semaphore_signal:semaphore];
    }] resume];
    [IJTDispatch dispatch_semaphore_wait:semaphore timeout:DISPATCH_TIME_FOREVER];
}

/*
+ (NSString *)getHtmlPath: (NSString *)path
{
    path = [NSString stringWithFormat:@"%@%@", BASEURL, path];
    NSURL *url = [NSURL URLWithString: path];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:url cachePolicy:
                                    NSURLRequestUseProtocolCachePolicy
                                    timeoutInterval:3];
    [NSURLRequest allowsAnyHTTPSCertificateForHost: path]; //可以使用https網站
    
    //上傳資料
    NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    return [[NSString alloc]initWithData:received encoding:NSUTF8StringEncoding];
}
 */
@end
