//
//  IJTDNSpoofSentTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTDNSpoofSentTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *sentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *queryHostnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *replyIpAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *sourceIpAddressLabel;

@end
