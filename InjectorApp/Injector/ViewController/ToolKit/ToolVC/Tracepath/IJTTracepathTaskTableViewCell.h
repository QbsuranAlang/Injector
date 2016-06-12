//
//  IJTTracepathTaskTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTTracepathTaskTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *ttlRangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *portRangeLabel;


@property (weak, nonatomic) IBOutlet UILabel *tosLabel;
@property (weak, nonatomic) IBOutlet UILabel *payloadSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *resloveIpAddressLabel;


@end
