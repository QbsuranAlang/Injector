//
//  IJTSupportSwitchTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/9/6.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FlatUIKit.h>
@interface IJTSupportSwitchTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet FUISwitch *enableSwitch;

@end
