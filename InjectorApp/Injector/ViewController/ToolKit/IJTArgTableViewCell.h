//
//  IJTArgTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/12.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTArgTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *controlView;
@property (nonatomic, strong) UILabel *messageLabel;

@end
