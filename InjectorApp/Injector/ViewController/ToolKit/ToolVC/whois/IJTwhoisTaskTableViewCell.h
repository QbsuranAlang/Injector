//
//  IJTwhoisTaskTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/23.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTwhoisTaskTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverLabel;

@end
