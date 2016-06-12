//
//  IJTFilterTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/2/28.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTFilterTableViewController.h"
#import "IJTFilterTableViewCell.h"
#import "IJTFilterInformationViewController.h"
#import "IJTSnifferTableViewController.h"
#import "IJTAddFilterTableViewController.h"
@interface IJTFilterTableViewController ()

@property (nonatomic, strong) NSMutableArray *nameArray;
@property (nonatomic, strong) NSMutableArray *pcapFilterArray;
@property (nonatomic) NSUInteger defaultFilterCount;
@property (nonatomic) BOOL supportCellular;
@property (nonatomic) BOOL supportWifi;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) Reachability *cellReachability;

@property (nonatomic, strong) UIBarButtonItem *trashButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *infoButton;
@property (nonatomic, strong) UIBarButtonItem *addButton;

@property (nonatomic, strong) SSARefreshControl *refreshView;
@end

@implementation IJTFilterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    if(self.nowType == IJTPacketReaderTypeWiFi)
        self.navigationItem.title = @"Filter(Wi-Fi)";
    else if(self.nowType == IJTPacketReaderTypeCellular)
        self.navigationItem.title = @"Filter(Cellular)";
    
    //check support
    self.supportCellular = [IJTNetowrkStatus supportCellular];
    self.supportWifi = [IJTNetowrkStatus supportWifi];
    
    //set add button
    self.addButton = [[UIBarButtonItem alloc]
                      initWithImage:[UIImage imageNamed:@"plus.png"]
                      style:UIBarButtonItemStylePlain
                      target:self action:@selector(addVC)];
    
    //set information button
    self.infoButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"question.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(filterInformation)];
    
    //set edit button
    self.trashButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"trash.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(editAction:)];
    
    self.doneButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                       target:self
                       action:@selector(editAction:)];
    
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects:_addButton, _trashButton, nil];
    
    //set back button clear
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc]
     initWithTitle:@""
     style:UIBarButtonItemStylePlain
     target:nil
     action:nil];
    
    self.backButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"left.png"]
                       style:UIBarButtonItemStylePlain
                       target:self action:@selector(back:)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:_backButton, _infoButton, nil];
    
    [self reloadPcapFilter];
    
    //refresh control
    self.refreshView = [[SSARefreshControl alloc] initWithScrollView:self.tableView andRefreshViewLayerType:SSARefreshViewLayerTypeOnScrollView];
    self.refreshView.delegate = self;
    
    [self checkCellForKey:self.pcapFilter];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //reachability
    [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
    if(self.supportWifi) {
        self.wifiReachability = [IJTNetowrkStatus wifiReachability];
        [self.wifiReachability startNotifier];
    }
    if(self.supportCellular) {
        self.cellReachability = [IJTNetowrkStatus cellReachability];
        [self.cellReachability startNotifier];
    }
    [self.view startCanvasAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if(self.supportWifi) {
        [self.wifiReachability stopNotifier];
    }
    if(self.supportCellular) {
        [self.cellReachability stopNotifier];
    }
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addVC {
    UINavigationController *navController = [self.storyboard instantiateViewControllerWithIdentifier:@"AddFilterNavVC"];
    IJTFilterTableViewController *addVC = (IJTFilterTableViewController *)[navController.viewControllers firstObject];
    addVC.delegate = self;
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)back: (id)sender {
     [self.navigationController popViewControllerAnimated:YES];
}

- (void)editAction: (id)sender {
    UIBarButtonItem *button = sender;
    if(button == self.trashButton) {
        button = self.doneButton;
        [self.tableView setEditing:YES animated:YES];
        self.backButton.enabled = NO;
        self.infoButton.enabled = NO;
        self.addButton.enabled = NO;
        
        [self showInfoMessage:@"Only not default filter expression can be deleted."];
        //[self showInformationMessageOneOrNot:@"Only not default filter expression can be deleted." key:@"ShowDeleteFilterInformation"];
    }
    else if(button == self.doneButton){
        button = self.trashButton;
        [self.tableView setEditing:NO animated:YES];
        self.backButton.enabled = YES;
        self.infoButton.enabled = YES;
        self.addButton.enabled = YES;
    }
    else
        return;
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    [array replaceObjectAtIndex:1 withObject:button];
    self.navigationItem.rightBarButtonItems = array;
}

- (void)filterInformation {
    //set filter information vc
    UIViewController *filterInformationVC =
    [self.storyboard instantiateViewControllerWithIdentifier:@"FilterInformationVC"];
    [self.navigationController pushViewController:filterInformationVC animated:YES];
}

- (void)beganRefreshing {
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        [self reloadWholeTableView];
        [self.refreshView endRefreshing];
    }];
}
#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    [self.tableView reloadData];
}

#pragma mark - Table view data source
- (void)reloadWholeTableView
{
    [self reloadPcapFilter];
    [self.tableView reloadData];
}

- (void)reloadPcapFilter
{
    [self clearArray];
    [self readPcapFilterFromPlist];
    [self readPcapFilterFromFile];
}

- (void)clearArray
{
    self.nameArray = [[NSMutableArray alloc] init];
    self.pcapFilterArray = [[NSMutableArray alloc] init];
    self.defaultFilterCount = 0;
}

- (void)readPcapFilterFromPlist
{
    NSString *path = nil;
    //if([[[NSBundle mainBundle] bundleIdentifier] containsString:@"debug"]) {
    if(geteuid()) {
        path = [[NSBundle mainBundle] pathForResource:@"DefaultPcapFilter" ofType:@"plist"];
    }
    else {
        path = @"/Applications/Injector.app/DefaultPcapFilter.plist";
    }
    
    
    NSDictionary *defaultPcapFilter = [[NSDictionary alloc] initWithContentsOfFile:path];
    self.nameArray = [NSMutableArray arrayWithArray:[defaultPcapFilter valueForKey:@"name"]];
    self.pcapFilterArray = [NSMutableArray arrayWithArray:[defaultPcapFilter valueForKey:@"pcapFilter"]];
    self.defaultFilterCount = [self.nameArray count];
}

- (void)readPcapFilterFromFile {
    NSString *path = nil;
    //if([[[NSBundle mainBundle] bundleIdentifier] containsString:@"debug"]) {
    if(geteuid()) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        path = [NSString stringWithFormat:@"%@/%@", basePath, @"PcapFiler"];
    }
    else {
        path = @"/var/root/Injector/PcapFiler";
    }
    
    NSArray *pcapFilter = [NSArray arrayWithContentsOfFile:path];
    for(NSDictionary *dict in pcapFilter) {
        [self.nameArray addObject:[dict valueForKey:@"name"]];
        [self.pcapFilterArray addObject:[dict valueForKey:@"pcapFilter"]];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.nameArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"FilterDetailCell";
    IJTFilterTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    
    cell.nameLabel.text = [self.nameArray objectAtIndex:indexPath.row];
    cell.nameLabel.font = [UIFont boldSystemFontOfSize:17];
    
    [IJTFormatUILabel text:[self.pcapFilterArray objectAtIndex:indexPath.row]
                     label:cell.pcapFilterLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:14]];
    
    cell.wifiLabel.font = [UIFont systemFontOfSize:14];
    cell.cellLabel.font = [UIFont systemFontOfSize:14];
    
    BOOL ok = NO;
    
    if(self.supportWifi) {
        ok = [IJTPcap testPcapFilter:cell.pcapFilterLabel.text interface:@"en0"];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        if(ok) {
            [dict setValue:@"Yes" forKey:@"ok"];
            [IJTGradient drawCircle:cell.wifiView color:IJTOkColor];
        }
        else {
            [dict setValue:@"No" forKey:@"ok"];
            [IJTGradient drawCircle:cell.wifiView color:IJTErrorColor];
        }
        [IJTFormatUILabel dict:dict
                           key:@"ok"
                        prefix:@"Wi-Fi : "
                         label:cell.wifiLabel
                         color:IJTValueColor
                          font:nil];
        cell.wifiOK = ok;
    }//end if
    else {
        cell.wifiOK = NO;
        [cell.wifiView removeFromSuperview];
        [cell.wifiLabel removeFromSuperview];
    }//end else
    
    if(self.supportCellular) {
        ok = [IJTPcap testPcapFilter:cell.pcapFilterLabel.text interface:@"pdp_ip0"];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        if(ok) {
            [dict setValue:@"Yes" forKey:@"ok"];
            [IJTGradient drawCircle:cell.cellView color:IJTOkColor];
        }
        else {
            [dict setValue:@"No" forKey:@"ok"];
            [IJTGradient drawCircle:cell.cellView color:IJTErrorColor];
        }
        
        [IJTFormatUILabel dict:dict
                           key:@"ok"
                        prefix:@"Cellular : "
                         label:cell.cellLabel
                         color:IJTValueColor
                          font:nil];
        cell.cellOK = ok;
    }//end if support gprs
    else {
        cell.cellOK = NO;
        [cell.cellView removeFromSuperview];
        [cell.cellLabel removeFromSuperview];
    }
    
    UITapGestureRecognizer *singleFingerTap1 =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(startAnimation:)];
    UITapGestureRecognizer *singleFingerTap2 =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(startAnimation:)];
    [cell.wifiView addGestureRecognizer:singleFingerTap1];
    [cell.cellView addGestureRecognizer:singleFingerTap2];
    
    [cell layoutIfNeeded];
    return cell;
}

- (void) startAnimation: (UITapGestureRecognizer *)recognizer
{
    CSAnimationView *animation = (CSAnimationView *)recognizer.view;
    [animation startCanvasAnimation];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //check when load data complete
    [self checkCellForKey:self.pcapFilter];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [NSString stringWithFormat:@"Filter(%lu)", (unsigned long)self.nameArray.count];
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    IJTFilterTableViewCell *checkedCell = (IJTFilterTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    if(self.nowType == IJTPacketReaderTypeWiFi)
        [checkedCell.wifiView startCanvasAnimation];
    else
        [checkedCell.cellView startCanvasAnimation];
    self.pcapFilter = checkedCell.pcapFilterLabel.text;
    //check when select
    [self checkCellForKey:self.pcapFilter];
    //check status
    
    if(self.nowType == IJTPacketReaderTypeWiFi) {
        if([self.wifiReachability currentReachabilityStatus] == NotReachable) {
            [self showWarningMessage:@"No Wi-Fi connection."];
        }
        else {
            if(!checkedCell.wifiOK) {
                [self showWarningMessage:[IJTPcap errorMessageFromErrorFilter:self.pcapFilter interface:@"en0"]];
            }
        }
    }
    else if(self.nowType == IJTPacketReaderTypeCellular) {
        if([self.cellReachability currentReachabilityStatus] == NotReachable) {
            [self showWarningMessage:@"No Cellular connection."];
        }
        else {
            if(!checkedCell.cellOK) {
                [self showWarningMessage:[IJTPcap errorMessageFromErrorFilter:self.pcapFilter interface:@"pdp_ip0"]];
            }
        }
    }
    
    [self.delegate passValue:checkedCell.pcapFilterLabel.text];
}

- (void)checkCellForKey :(NSString *)key
{
    for (NSInteger section = 0, sectionCount = self.tableView.numberOfSections; section < sectionCount; ++section) {
        for (NSInteger row = 0, rowCount = [self.tableView numberOfRowsInSection:section]; row < rowCount; ++row) {
            IJTFilterTableViewCell *cell =
            (IJTFilterTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            if([cell.pcapFilterLabel.text isEqualToString:key])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell startCanvasAnimation];
}

- (void)checkCellForIndex :(NSUInteger)index
{
    for (NSInteger section = 0, sectionCount = self.tableView.numberOfSections; section < sectionCount; ++section) {
        for (NSInteger row = 0, rowCount = [self.tableView numberOfRowsInSection:section]; row < rowCount; ++row) {
            IJTFilterTableViewCell *cell =
            (IJTFilterTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            if(index == row)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row < self.defaultFilterCount) {
        
        [self showInfoMessage:@"Only custom filter expression can be deleted."];
        
        return UITableViewCellEditingStyleNone;
    }
    else {
        
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    [array replaceObjectAtIndex:1 withObject:self.trashButton];
    self.navigationItem.rightBarButtonItems = array;
    self.backButton.enabled = YES;
    self.infoButton.enabled = YES;
    self.addButton.enabled = YES;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if(indexPath.row < self.defaultFilterCount)
        return NO;
    else
        return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        SCLAlertView *alert = [IJTShowMessage baseAlertView];
        
        __block IJTFilterTableViewCell *cell = (IJTFilterTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        __block NSInteger index = indexPath.row;
        
        [alert addButton:@"Yes" actionBlock:^(void) {
            NSString *name = [self.nameArray objectAtIndex:index];
            NSString *filter = [self.pcapFilterArray objectAtIndex:index];
            NSString *path = nil;
            if(geteuid()) {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
                path = [NSString stringWithFormat:@"%@/%@", basePath, @"PcapFiler"];
            }
            else {
                path = @"/var/root/Injector/PcapFiler";
            }
            
            NSMutableArray *pcapFilter = [NSMutableArray arrayWithContentsOfFile:path];
            NSDictionary *needDelete = nil;
            for(NSDictionary *dict in pcapFilter) {
                
                if([[dict valueForKey:@"name"] isEqualToString:name] &&
                   [[dict valueForKey:@"pcapFilter"] isEqualToString:filter]) {
                    needDelete = dict;
                    break;
                }
            }
            
            if(needDelete) {
                [pcapFilter removeObject:needDelete];
            }
            [pcapFilter writeToFile:path atomically:YES];
            
            //after delete, reload tableview
            [self reloadWholeTableView];
            [self passNowSelected];
        }];
        
        [alert showWarning:@"Warning"
                  subTitle:[NSString stringWithFormat:@"Are you sure delete: %@(%@)?", cell.nameLabel.text, cell.pcapFilterLabel.text]
          closeButtonTitle:@"No"
                  duration:0];
        
    }
}

- (void)callback {
    [self reloadWholeTableView];
}

- (void)passNowSelected {
    for (NSInteger section = 0, sectionCount = self.tableView.numberOfSections; section < sectionCount; ++section) {
        for (NSInteger row = 0, rowCount = [self.tableView numberOfRowsInSection:section]; row < rowCount; ++row) {
            IJTFilterTableViewCell *cell =
            (IJTFilterTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            if(cell.accessoryType == UITableViewCellAccessoryCheckmark) {
                [self.delegate passValue:cell.pcapFilterLabel.text];
                return;
            }
        }
    }
}
@end
