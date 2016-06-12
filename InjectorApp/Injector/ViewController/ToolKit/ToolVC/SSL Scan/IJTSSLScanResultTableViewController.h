//
//  IJTSSLScanResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTSSLScanResultTableViewController : IJTBaseViewController <IJTSSLScanDelegate>

@property (nonatomic, strong) NSString *target;
@property (nonatomic) u_int16_t port;
@property (nonatomic) sa_family_t family;
@property (nonatomic) u_int32_t timeout;
@property (nonatomic) BOOL clientCipher;
@property (nonatomic) BOOL renegotiation;
@property (nonatomic) BOOL compression;
@property (nonatomic) BOOL heartbleed;
@property (nonatomic) BOOL serverCipher;
@property (nonatomic) BOOL showCertificate;
@property (nonatomic) BOOL showTrustedCAs;

@end
