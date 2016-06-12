//
//  IJTDetectEventTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/5/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTDetectEventTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *ipAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *countryCodeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *countryFlagView;
@property (weak, nonatomic) IBOutlet UILabel *detectTimesLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
