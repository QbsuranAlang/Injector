//
//  IJTFilterTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/2/28.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Canvas.h>
@interface IJTFilterTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *pcapFilterLabel;
@property (weak, nonatomic) IBOutlet CSAnimationView *wifiView;
@property (weak, nonatomic) IBOutlet CSAnimationView *cellView;
@property (weak, nonatomic) IBOutlet UILabel *wifiLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellLabel;
@property (nonatomic) BOOL wifiOK;
@property (nonatomic) BOOL cellOK;

@end
