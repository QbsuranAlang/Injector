//
//  IJTLANDetailTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

typedef NS_ENUM(u_int16_t, IJTLANStatusFlags) {
    IJTLANStatusFlagsMyself = 0x0001,
    IJTLANStatusFlagsGateway = 0x0002,
    IJTLANStatusFlagsArping = 0x0004,
    IJTLANStatusFlagsDNS = 0x0008,
    IJTLANStatusFlagsMDNS = 0x0010,
    IJTLANStatusFlagsNetbios = 0x0020,
    IJTLANStatusFlagsPing = 0x0040,
    IJTLANStatusFlagsSSDP = 0x0080,
    IJTLANStatusFlagsLLMNR = 0x0100,
    IJTLANStatusFlagsFirewalled = 0x0200,
    IJTLANStatusFlagsArpoison = 0x0400,
};

@interface IJTLANDetailTableViewController : IJTBaseViewController

@property (nonatomic, strong) NSMutableDictionary *dict;
@end
