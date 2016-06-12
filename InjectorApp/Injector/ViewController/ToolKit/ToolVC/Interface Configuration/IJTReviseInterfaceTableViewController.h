//
//  IJTReviseInterfaceTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/15.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTReviseInterfaceTableViewController : IJTBaseViewController <CZPickerViewDataSource, CZPickerViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, assign) NSObject<PassValueDelegate> *delegate;
@property (weak, nonatomic) IBOutlet UIView *selectInterfaceView;
@property (weak, nonatomic) IBOutlet UITableViewCell *mtuView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet FUIButton *modifyButton;

@end
