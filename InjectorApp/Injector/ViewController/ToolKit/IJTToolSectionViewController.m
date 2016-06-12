//
//  IJTToolSectionViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/12/18.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTToolSectionViewController.h"
#import "IJTToolBreakerCollectionViewCell.h"
#import "IJTToolPickerViewController.h"
@interface IJTToolSectionViewController ()

@property (nonatomic, strong) NSArray *titleArray;
@property (nonatomic, strong) NSDictionary *titleDictionary;


@end

@implementation IJTToolSectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    if(self.type == IJTToolSectionViewControllerTypeSystem) {
        self.titleLabel.text = @"System Tool";
        self.titleArray = [self getKeys:[IJTBaseViewController getSystemToolArray]];
        self.titleDictionary = [self getDictionary:[IJTBaseViewController getSystemToolArray]];
    }
    else if(self.type == IJTToolSectionViewControllerTypeNetwork) {
        self.titleLabel.text = @"Network Tool";
        self.titleArray = [self getKeys:[IJTBaseViewController getNetworkToolArray]];
        self.titleDictionary = [self getDictionary:[IJTBaseViewController getNetworkToolArray]];
    }
    
    self.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.titleLabel.textColor = IJTWhiteColor;
    
    [(EBCardCollectionViewLayout *)_collectionView.collectionViewLayout setOffset:UIOffsetMake(10, 10)];
    [(EBCardCollectionViewLayout *)_collectionView.collectionViewLayout setLayoutType:EBCardCollectionLayoutVertical];
    
    self.collectionView.pagingEnabled = NO;
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.scrollEnabled = YES;
    self.collectionView.showsVerticalScrollIndicator = YES;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.view.backgroundColor = IJTToolsColor;
    /*[self.view.layer insertSublayer:
     [IJTGradient verticallyGradientColors:
      [NSArray arrayWithObjects:(id)[[IJTColor darker:IJTToolsColor times:1] CGColor], (id)[[IJTColor lighter:IJTToolsColor times:3] CGColor], nil]
                                     frame:self.view.frame]
                            atIndex:0];*/
    
    [self.dismissButton addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
    //color button image
    UIImage *image = [self.dismissButton.currentImage imageWithColor:IJTIconWhiteColor];
    [self.dismissButton setImage:image forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoToolsVC: (id)sender {
    FUIButton *button = sender;
    NSString *title = self.titleArray[button.tag];
    NSArray *toolsArray = [_titleDictionary valueForKey:title];
    IJTToolPickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ToolPickerVC"];
    vc.type = self.type;
    vc.toolsArray = toolsArray;
    vc.toolTitle = title;
    [self.navigationController pushViewController:vc animated:YES];
}

- (NSArray *)getKeys: (NSArray *)array {
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    for(NSDictionary *dict in array) {
        [keys addObject:[[dict allKeys] objectAtIndex:0]];
    }
    return keys;
}

- (NSDictionary *)getDictionary: (NSArray *)array {
    NSMutableDictionary *dict2 = [[NSMutableDictionary alloc] init];
    for(NSDictionary *dict in array) {
        NSString *key = [[dict allKeys] objectAtIndex:0];
        NSArray *value = [dict valueForKey:key];
        [dict2 setValue:value forKey:key];
    }
    return dict2;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.titleArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    IJTToolBreakerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BreakerCell" forIndexPath:indexPath];
    
    NSString *title = _titleArray[indexPath.row];
    cell.titleLabel.textColor = IJTIconWhiteColor;
    cell.titleLabel.adjustsFontSizeToFitWidth = YES;
    cell.titleLabel.numberOfLines = 1;
    
    cell.backgroundColor = [UIColor clearColor];
    
    cell.layer.borderWidth = 3.0;
    cell.layer.borderColor = [IJTIconWhiteColor CGColor];
    cell.layer.cornerRadius = 15;
    
    NSArray *array = [self.titleDictionary valueForKey:title];
    NSMutableString *string = [[NSMutableString alloc] init];
    for(NSString *s in array) {
        [string appendFormat:@"%@\n", s];
    }
    cell.itemsLabel.text = string;
    
    cell.itemsLabel.adjustsFontSizeToFitWidth = YES;
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@(%lu)", title, (unsigned long)array.count];
    
    cell.pickButton.tag = indexPath.row;
    cell.pickButton.buttonColor = IJTInjectorIconBackgroundColor;
    cell.pickButton.shadowColor = [IJTColor darker:IJTInjectorIconBackgroundColor times:2];
    [cell.pickButton addTarget:self action:@selector(gotoToolsVC:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell layoutIfNeeded];
    return cell;
}

- (BOOL)shouldAutorotate {
    [_collectionView.collectionViewLayout invalidateLayout];
    
    return [super shouldAutorotate];
}

@end
