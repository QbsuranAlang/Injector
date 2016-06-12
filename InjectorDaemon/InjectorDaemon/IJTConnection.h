//
//  IJTConnection.h
//  InjectorDaemon
//
//  Created by 聲華 陳 on 2015/9/17.
//
//

#import <Foundation/Foundation.h>

@interface IJTConnection : NSObject

- (id)init;
- (void)addObserver;

+ (NSString *)BSSID;
@end
