//
//  IJTArpoisonNoSentTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTArpoisonNoSentTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (weak, nonatomic) IBOutlet UILabel *indexLabel;
@property (weak, nonatomic) IBOutlet UILabel *notSentLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
