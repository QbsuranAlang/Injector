//
//  IJTMultiSelectTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/10.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTMultiSelectTableViewController.h"
#import "IJTMultiSelectTableViewCell.h"
#import "IJTMultiSelectedCollectionViewCell.h"
#import "IJTMultiToolViewController.h"

@interface IJTMultiSelectTableViewController ()

@property (nonatomic, strong) NSArray *systemToolArray;
@property (nonatomic, strong) NSArray *networkToolArray;
@property (nonatomic, strong) UIBarButtonItem *dismissButton;
@property (nonatomic, strong) NSMutableArray *selectedTool;
@property (nonatomic, strong) UIBarButtonItem *actionButton;

@end

@implementation IJTMultiSelectTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"close.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.actionButton = [[UIBarButtonItem alloc]
                         initWithImage:[UIImage imageNamed:@"MultiSelect.png"]
                         style:UIBarButtonItemStylePlain
                         target:self action:@selector(gotoMultiToolVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:_dismissButton, nil];
    
    self.selectedTool = [[NSMutableArray alloc] init];
    
    //collection view
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    self.collectionView.scrollEnabled = YES;
    self.collectionView.pagingEnabled = NO;
    self.collectionView.bounces = YES;
    self.collectionView.alwaysBounceHorizontal = YES;
    [self.collectionView layoutIfNeeded];
    
    UIColor *transBgColor = [IJTColor lighter:IJTInjectorIconBackgroundColor times:1];
    NSArray *colors = [NSArray arrayWithObjects:(id)[IJTColor darker:IJTInjectorIconBackgroundColor times:1 level:10].CGColor, (id)transBgColor.CGColor, nil];
    [self.view.layer insertSublayer:
     [IJTGradient horizontalGradientColors:colors
                                     frame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
                                startPoint:CGPointMake(0.0, 0.5)
                                  endPoint:CGPointMake(1.0, 0.5)
                                 locations:@[@(0), @(0.7), @(1.0)]]
                            atIndex:0];
    
    
    self.collectionViewHeightConstraint.constant = 0.0f;
    
    self.systemToolArray = [self getAllTool:[IJTBaseViewController getSystemToolArray]];
    self.networkToolArray = [self getAllTool:[IJTBaseViewController getNetworkToolArray]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoMultiToolVC {
    IJTMultiToolViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"MultiToolVC"];
    vc.selectedTools = [NSArray arrayWithArray:self.selectedTool];
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}

- (NSArray *)getAllTool: (NSArray *)array {
    NSArray *list = [[NSArray alloc] init];
    for(NSDictionary *dict in array) {
        NSString *key = [[dict allKeys] objectAtIndex:0];
        NSArray *items = [dict valueForKey:key];
        list = [list arrayByAddingObjectsFromArray:items];
    }
    return list;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0) {
        return self.systemToolArray.count;
    }
    else if(section == 1) {
        return self.networkToolArray.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTMultiSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ToolCell" forIndexPath:indexPath];
    NSString *imageName = @"";
    NSString *name = @"";
    
    if(indexPath.section == 0) {
        name = self.systemToolArray[indexPath.row];
    }
    else if(indexPath.section == 1) {
        name = self.networkToolArray[indexPath.row];
    }
    
    imageName = [name stringByAppendingString:@".png"];
    
    [IJTFormatUILabel text:name
                     label:cell.nameLabel
                      font:[UIFont systemFontOfSize:17]];
    
    cell.iconImageView.image = [UIImage imageNamed:imageName];
    
    BOOL needcheck = NO;
    for(NSString *name in self.selectedTool) {
        if([name isEqualToString:cell.nameLabel.text]) {
            needcheck = YES;
            break;
        }
    }
    if(needcheck) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [cell layoutIfNeeded];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    IJTMultiSelectTableViewCell *cell = (IJTMultiSelectTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    if(cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        for(NSUInteger i = 0 ; i < self.selectedTool.count ; i++) {
            NSString *name = self.selectedTool[i];
            if([name isEqualToString:cell.nameLabel.text]) {
                [self.collectionView performBatchUpdates:^{
                    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                    [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:i inSection:0]]];
                    [self.selectedTool removeObject:cell.nameLabel.text];
                } completion:^(BOOL finished){
                    [self.collectionView reloadData];
                }];
                break;
            }//end if match
        }//end for search
    }//end if checkmark
    else if(cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.collectionView performBatchUpdates:^{
            [self.selectedTool addObject:cell.nameLabel.text];
            [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.selectedTool.count-1 inSection:0]]];
        } completion:^(BOOL finished){
            [self.collectionView reloadData];
        }];
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedTool.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        
    }//end if none
    [self animateSelectedCollectionView];
    [self.tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return [NSString stringWithFormat:@"System(%lu)", (unsigned long)self.systemToolArray.count];
    }
    else if(section == 1) {
        return [NSString stringWithFormat:@"Network(%lu)", (unsigned long)self.networkToolArray.count];
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

#pragma mark collection view
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.selectedTool.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IJTMultiSelectedCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SelectedCell" forIndexPath:indexPath];
    
    NSString *name = self.selectedTool[indexPath.row];
    
    cell.nameLabel.text = name;
    cell.nameLabel.font = [UIFont systemFontOfSize:20];
    cell.nameLabel.adjustsFontSizeToFitWidth = YES;
    cell.nameLabel.textColor = IJTIconWhiteColor;
    cell.iconImageView.image = [UIImage imageNamed:name];
    cell.iconImageView.image = [cell.iconImageView.image imageWithColor:IJTIconWhiteColor];
    cell.removeButton.tag = indexPath.row;
    [cell.removeButton addTarget:self action:@selector(removeSelectedTool:) forControlEvents:UIControlEventTouchUpInside];
    cell.backgroundColor = [UIColor clearColor];
    cell.layer.borderColor = [[UIColor grayColor] CGColor];
    cell.layer.borderWidth = 1;
    cell.layer.cornerRadius = 10;
    
    [cell layoutIfNeeded];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100, 130);
}

- (void)removeSelectedTool: (id)sender {
    UIButton *button = sender;
    NSInteger index = button.tag;
    
    [self.collectionView performBatchUpdates:^{
        if(self.selectedTool.count > index) {
            [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
            [self.selectedTool removeObjectAtIndex:index];
        }
    } completion:^(BOOL finished) {
        [self.collectionView reloadData];
    }];
    
    [self animateSelectedCollectionView];
    [self.tableView reloadData];
}

-(void)animateSelectedCollectionView {
    if (self.selectedTool.count > 0) {
        self.collectionViewHeightConstraint.constant = 140;
    }else{
        self.collectionViewHeightConstraint.constant = 0;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
    
    /*self.navigationItem.title = [NSString stringWithFormat:@"Multi Tool%@",
                                 self.selectedTool.count == 0 ? @"(0)" :
                                 [NSString stringWithFormat:@"s(%lu)", (unsigned long)self.selectedTool.count]];
     */
    self.navigationItem.title = [NSString stringWithFormat:@"Multi Tool(%lu)", (unsigned long)self.selectedTool.count];
    if(self.selectedTool.count > 0) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_actionButton, nil];
    }
    else {
        self.navigationItem.rightBarButtonItems = nil;
    }
}

@end
