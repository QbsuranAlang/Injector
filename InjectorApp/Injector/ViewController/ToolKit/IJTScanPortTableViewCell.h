//
//  IJTScanPortTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/10.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTScanPortTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *portLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;

@end
