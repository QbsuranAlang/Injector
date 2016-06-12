//
//  IJTSSLScanTaskTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTSSLScanTaskTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *hostnameLabel;
@property (weak, nonatomic) IBOutlet UILabel *clientCipherLabel;
@property (weak, nonatomic) IBOutlet UILabel *compressionLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverCipherLabel;
@property (weak, nonatomic) IBOutlet UILabel *trustedCAsLabel;
@property (weak, nonatomic) IBOutlet UILabel *renegotiationLabel;
@property (weak, nonatomic) IBOutlet UILabel *heartbleedLabel;
@property (weak, nonatomic) IBOutlet UILabel *showCertificateLabel;

@end
