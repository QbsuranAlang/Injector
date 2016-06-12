//
//  IJTArpScanTaskTableViewCell
//  Injector
//
//  Created by 聲華 陳 on 2015/8/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTArpScanTaskTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *injectRangeLabel;
@property (weak, nonatomic) IBOutlet UILabel *bssidLabel;
@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;


@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
