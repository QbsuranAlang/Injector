//
//  IJTArpingArpFrameTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTArpingArpFrameTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *indexLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *rttLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *macAddressLabel;


@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
