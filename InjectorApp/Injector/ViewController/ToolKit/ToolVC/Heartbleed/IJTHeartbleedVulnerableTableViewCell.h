//
//  IJTHeartbleedVulnerableTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTHeartbleedVulnerableTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *lengthLabel;
@property (weak, nonatomic) IBOutlet UILabel *asciiDumpLabel;
@property (weak, nonatomic) IBOutlet UILabel *hexDumpLabel;

@end
