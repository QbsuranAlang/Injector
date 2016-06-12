//
//  IJTArpingTaskTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTArpingTaskTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *bssidLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
