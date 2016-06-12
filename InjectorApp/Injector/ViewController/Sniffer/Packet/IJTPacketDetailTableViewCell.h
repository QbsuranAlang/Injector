//
//  IJTPacketDetailTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/24.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTPacketDetailTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *numberLabel;
@property (weak, nonatomic) IBOutlet UILabel *interfaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *arrivalLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameLengthLabel;
@property (weak, nonatomic) IBOutlet UILabel *captureLengthLabel;
@property (weak, nonatomic) IBOutlet UILabel *protocolLabel;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *dataLabels;

@end
