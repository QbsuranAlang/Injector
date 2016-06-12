//
//  IJTWiFiScannerKnownNetworkTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/11/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTWiFiScannerKnownNetworkTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *SSIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *BSSIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;

@end
