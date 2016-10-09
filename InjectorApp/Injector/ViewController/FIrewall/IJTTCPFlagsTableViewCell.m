//
//  IJTTCPFlagsTableViewCell.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTTCPFlagsTableViewCell.h"
#import "IJTBaseViewController.h"

@implementation IJTTCPFlagsTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    
    CGFloat width = (SCREEN_WIDTH - (self.buttons.count - 1))/self.buttons.count;
    
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        NSLayoutConstraint *constraint =
        [NSLayoutConstraint constraintWithItem:button
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1 constant:width];
        [button addConstraint:constraint];
        
        [button setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [button setSelected:NO];
        button.adjustsImageWhenHighlighted = NO;
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        [self imageTopTitleBottom:button];
    }];
}

-(void)imageTopTitleBottom:(UIButton *)button
{
    // the space between the image and text
    CGFloat spacing = 3.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = button.imageView.image.size;
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
    button.imageEdgeInsets = UIEdgeInsetsMake(- (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
}

-(void)buttonTapped:(UIButton *)button {
    button.selected = !button.selected;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
@end
