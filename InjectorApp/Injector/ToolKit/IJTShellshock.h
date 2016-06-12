//
//  IJTShellshock.h
//  
//
//  Created by 聲華 陳 on 2016/1/1.
//
//

#import <Foundation/Foundation.h>

@interface IJTShellshock : NSObject

- (id)init;
- (void)dealloc;

/**
 * exploit 測試
 * @param url 網址
 * @param command 指令
 * @param timeout timeout
 * @param error string
 * @return 結果
 */
- (NSString *)exploitURL: (NSString *)urlString command: (NSString *)command timeout: (u_int32_t)timeout error: (NSString **)error;
@end
