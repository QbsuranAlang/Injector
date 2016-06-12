//
//  IJTTCPFlagsTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTTCPFlagsTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *finButton;
@property (weak, nonatomic) IBOutlet UIButton *synButton;
@property (weak, nonatomic) IBOutlet UIButton *rstButton;
@property (weak, nonatomic) IBOutlet UIButton *pushButton;
@property (weak, nonatomic) IBOutlet UIButton *ackButton;
@property (weak, nonatomic) IBOutlet UIButton *urgButton;
@property (weak, nonatomic) IBOutlet UIButton *eceButton;
@property (weak, nonatomic) IBOutlet UIButton *cwrButton;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;

@property (nonatomic) NSInteger rowTag;

@end
