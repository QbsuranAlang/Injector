//
//  IJTLANOnlineTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/31.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTLANOnlineTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *ouiLabel;
@property (weak, nonatomic) IBOutlet UIView *statusView;

@end
