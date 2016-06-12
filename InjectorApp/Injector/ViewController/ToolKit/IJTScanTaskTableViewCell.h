//
//  IJTScanTaskTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/10.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTScanTaskTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *startPortLabel;
@property (weak, nonatomic) IBOutlet UILabel *endPortLabel;
@property (weak, nonatomic) IBOutlet UILabel *randLabel;

@end
