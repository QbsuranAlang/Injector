//
//  IJTIfconfigTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/15.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTIfconfigTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *interfaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *mtuLabel;
@property (weak, nonatomic) IBOutlet UILabel *flagsLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *netmaskLabel;
@property (weak, nonatomic) IBOutlet UILabel *dstLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
