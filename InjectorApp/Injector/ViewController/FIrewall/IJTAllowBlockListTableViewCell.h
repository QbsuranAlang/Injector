//
//  IJTAllowBlockListTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/6/13.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTAllowBlockListTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *ipAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *addTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *appLabel;
@property (weak, nonatomic) IBOutlet UILabel *enableLabel;
@property (weak, nonatomic) NSString *ipAddress;
@property (nonatomic) time_t lastTime;
@property (weak, nonatomic) NSString *appName;
@property (nonatomic) BOOL enable;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
