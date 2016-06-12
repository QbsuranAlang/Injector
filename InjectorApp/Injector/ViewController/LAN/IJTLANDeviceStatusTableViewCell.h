//
//  IJTLANDeviceStatusTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/9.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTLANDeviceStatusTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *booleanLabel;
@property (weak, nonatomic) IBOutlet UIView *statusView;

@end
