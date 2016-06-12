//
//  IJTLANHistoryTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTLANHistoryTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeLabel;

@end
