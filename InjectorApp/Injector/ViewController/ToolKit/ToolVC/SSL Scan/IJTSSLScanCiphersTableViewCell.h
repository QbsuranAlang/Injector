//
//  IJTSSLScanCiphersTableViewCell.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/18.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IJTSSLScanCiphersTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitsLabel;
@property (weak, nonatomic) IBOutlet UILabel *cipherLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end
