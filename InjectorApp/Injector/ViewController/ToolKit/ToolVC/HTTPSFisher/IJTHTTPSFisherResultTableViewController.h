//
//  IJTHTTPSFisherResultTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTHTTPSFisherResultTableViewController : IJTBaseViewController <IJTHTTPSFisherDelegate>

@property (nonatomic, strong) NSString *rediectHostname;
@property (nonatomic, strong) NSString *redirectIpAddress;
@property (nonatomic) BOOL savepackets;
//@property (nonatomic) BOOL displayHeader;
//@property (nonatomic) BOOL displayBody;

@end
