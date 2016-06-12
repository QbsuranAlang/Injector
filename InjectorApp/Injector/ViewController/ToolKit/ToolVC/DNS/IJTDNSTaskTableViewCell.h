//
//  IJTDNSTaskTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/12.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTDNSTaskTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverLabel;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@end
