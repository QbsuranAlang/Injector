//
//  IJTCountryInformationTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/5/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTCountryInformationTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *countryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *regionNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *cityNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolveHostnameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *countryFlagImageView;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
