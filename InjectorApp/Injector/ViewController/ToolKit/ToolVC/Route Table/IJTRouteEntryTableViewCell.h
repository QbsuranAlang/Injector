//
//  IJTRouteEntryTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTRouteEntryTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *dstHostnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dstIpAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *gatewayLabel;
@property (weak, nonatomic) IBOutlet UILabel *interfaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *mtuLabel;
@property (weak, nonatomic) IBOutlet UILabel *refsLabel;
@property (weak, nonatomic) IBOutlet UILabel *useLabel;
@property (weak, nonatomic) IBOutlet UILabel *expireLabel;
@property (weak, nonatomic) IBOutlet UILabel *flagsLabel;

@property (nonatomic, strong) NSString *destinationAddress;
@property (nonatomic, strong) NSString *gatewayAddress;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
