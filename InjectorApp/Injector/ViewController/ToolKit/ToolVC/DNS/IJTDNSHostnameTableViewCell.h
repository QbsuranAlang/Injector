//
//  IJTDNSHostnameTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/13.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTDNSHostnameTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *hostnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolveHostnameLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
