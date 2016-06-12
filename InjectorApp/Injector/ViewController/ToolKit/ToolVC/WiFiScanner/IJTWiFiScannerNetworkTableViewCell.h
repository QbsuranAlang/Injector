//
//  IJTWiFiScannerNetworkTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/11/8.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTWiFiScannerNetworkTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *isAppleHotspotImageView;
@property (weak, nonatomic) IBOutlet UILabel *SSIDLabel;
@property (weak, nonatomic) IBOutlet UILabel *BSSIDLabel;
@property (weak, nonatomic) IBOutlet UIImageView *keyImageView;
@property (weak, nonatomic) IBOutlet UILabel *RSSILabel;
@property (weak, nonatomic) IBOutlet UILabel *encryptionModelLabel;
@property (weak, nonatomic) IBOutlet UILabel *channelLabel;

@end
