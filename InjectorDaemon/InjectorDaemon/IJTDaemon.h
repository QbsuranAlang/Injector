//
//  IJTDaemon.h
//  InjectorDaemon
//
//  Created by 聲華 陳 on 2015/4/12.
//
//

#import <Foundation/Foundation.h>
#import <netinet/ip.h>
#import <pcap.h>
#import <dlfcn.h>
#import "curl/curl.h"
#define FLOW_RECEIVE_URL "https://nrl.cce.mcu.edu.tw/injector/dbAccess/InsertPacketFlow.php"

@interface IJTDaemon : NSObject

@property (nonatomic) BOOL ok;
- (id)initWithInterface: (NSString *)interface;
- (void) start;
id plistObject(NSString *key, int index);

@end
