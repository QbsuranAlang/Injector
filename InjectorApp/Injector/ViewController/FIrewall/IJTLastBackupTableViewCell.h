//
//  IJTLastBackupTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/6/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTLastBackupTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemsLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
