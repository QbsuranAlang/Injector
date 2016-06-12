//
//  IJTToolPickerCollectionViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/9.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FlatUIKit.h>
@interface IJTToolPickerCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *backgroundColorView;
//@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet FUIButton *pickButton;
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;

@end
