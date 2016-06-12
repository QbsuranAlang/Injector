//
//  IJTPacketFieldTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/26.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTPacketReader.h"
@interface IJTPacketFieldTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *fieldNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *fieldValueLabel;

@property (nonatomic) IJTPacketReaderProtocol protocol;
@property (nonatomic) NSUInteger dataLength;

@end
