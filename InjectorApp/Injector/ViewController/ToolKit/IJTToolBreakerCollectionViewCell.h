//
//  IJTToolBreakerCollectionViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/14.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FlatUIKit.h>
@interface IJTToolBreakerCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *itemsLabel;
@property (weak, nonatomic) IBOutlet FUIButton *pickButton;

@end
