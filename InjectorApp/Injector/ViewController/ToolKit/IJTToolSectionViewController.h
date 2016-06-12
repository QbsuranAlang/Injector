//
//  IJTToolSectionViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/12/18.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"

typedef NS_ENUM(NSInteger, IJTToolSectionViewControllerType) {
    IJTToolSectionViewControllerTypeSystem = 0,
    IJTToolSectionViewControllerTypeNetwork
};

@interface IJTToolSectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) IJTToolSectionViewControllerType type;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
