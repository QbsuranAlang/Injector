//
//  IJTTracepathHopsTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTTracepathHopsTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (weak, nonatomic) IBOutlet UILabel *indexLabel;


@property (weak, nonatomic) IBOutlet UILabel *ipAddress1Label;
@property (weak, nonatomic) IBOutlet UILabel *hostname1Label;
@property (weak, nonatomic) IBOutlet UILabel *rtt1Label;
@property (weak, nonatomic) IBOutlet UILabel *length1Label;
@property (weak, nonatomic) IBOutlet UILabel *length1TextLabel;
@property (weak, nonatomic) IBOutlet UILabel *rtt1TextLabel;
@property (weak, nonatomic) IBOutlet UILabel *hostname1TextLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipAddress1TextLabel;



@property (weak, nonatomic) IBOutlet UILabel *ipAddress2Label;
@property (weak, nonatomic) IBOutlet UILabel *hostname2Label;
@property (weak, nonatomic) IBOutlet UILabel *rtt2Label;
@property (weak, nonatomic) IBOutlet UILabel *length2Label;
@property (weak, nonatomic) IBOutlet UILabel *length2TextLabel;
@property (weak, nonatomic) IBOutlet UILabel *rtt2TextLabel;
@property (weak, nonatomic) IBOutlet UILabel *hostname2TextLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipAddress2TextLabel;

@property (weak, nonatomic) IBOutlet UILabel *ipAddress3Label;
@property (weak, nonatomic) IBOutlet UILabel *hostname3Label;
@property (weak, nonatomic) IBOutlet UILabel *rtt3Label;
@property (weak, nonatomic) IBOutlet UILabel *length3Label;
@property (weak, nonatomic) IBOutlet UILabel *length3TextLabel;
@property (weak, nonatomic) IBOutlet UILabel *rtt3TextLabel;
@property (weak, nonatomic) IBOutlet UILabel *hostname3TextLabel;
@property (weak, nonatomic) IBOutlet UILabel *ipAddress3TextLabel;

@end
