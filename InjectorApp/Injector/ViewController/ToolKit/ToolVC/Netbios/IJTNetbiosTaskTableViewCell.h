//
//  IJTNetbiosTaskTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/14.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTNetbiosTaskTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (weak, nonatomic) IBOutlet UILabel *targetLabel;

@end
