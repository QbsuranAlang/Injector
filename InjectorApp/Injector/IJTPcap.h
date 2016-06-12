//
//  IJTPcap.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pcap.h>
@interface IJTPcap : NSObject

+ (BOOL)testPcapFilter: (NSString *)pcapFilter interface: (NSString *)interface;
+ (NSString *)errorMessageFromErrorFilter: (NSString *)pcapFilter interface: (NSString *)interface;
- (id) initInterface :(NSString *)interface
            bpfFilter:(NSString *)bpfFilter
              promisc:(BOOL)promisc
                 toms:(unsigned int)toms;

- (void)breakLoop;
- (void)closeHandle;
- (NSString *) getPcapError;

@property (nonatomic) BOOL occurError;
@property (nonatomic) pcap_t *handle;
@property (nonatomic, strong) NSString *errorMessage;

@end
