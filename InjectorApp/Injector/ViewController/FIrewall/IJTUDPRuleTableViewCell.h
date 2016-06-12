//
//  IJTUDPRuleTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/6/19.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTUDPRuleTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionLabel;
@property (weak, nonatomic) IBOutlet UILabel *quickLabel;
@property (weak, nonatomic) IBOutlet UILabel *internetLabel;
@property (weak, nonatomic) IBOutlet UILabel *interfaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *keepStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UILabel *destinationLabel;
@property (weak, nonatomic) IBOutlet UILabel *srcPortLabel;
@property (weak, nonatomic) IBOutlet UILabel *dstPortLabel;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
