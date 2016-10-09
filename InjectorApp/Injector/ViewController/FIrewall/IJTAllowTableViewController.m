//
//  IJTAllowTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/6/13.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTAllowTableViewController.h"
#import "IJTAllowBlockListTableViewCell.h"
#import "IJTRuleTableViewController.h"

@interface IJTAllowTableViewController ()

@property (nonatomic, strong) NSArray *allowList;

@property (nonatomic, strong) NSString *serialNumber;

@property (nonatomic, strong) CNPGridMenu *gridMenu;

@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *detailButton;

@property (nonatomic, strong) SSARefreshControl *refreshView;
@end

@implementation IJTAllowTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //self size
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"close.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.detailButton =
    [[UIBarButtonItem alloc]
     initWithImage:[UIImage imageNamed:@"other_tool.png"]
     style:UIBarButtonItemStylePlain
     target:self action:@selector(showFunction)];
    
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects:_detailButton, nil];
    
    self.doneButton =
    [[UIBarButtonItem alloc]
     initWithBarButtonSystemItem:UIBarButtonSystemItemDone
     target:self action:@selector(doneAction)];
    
    self.serialNumber = [IJTID serialNumber];
    
    CNPGridMenuItem *ruleButton = [[CNPGridMenuItem alloc] init];
    ruleButton.icon = [UIImage imageNamed:@"show_rule.png"];
    ruleButton.title = @"What I Backup";
    
    CNPGridMenuItem *addButton = [[CNPGridMenuItem alloc] init];
    addButton.icon = [UIImage imageNamed:@"add_row.png"];
    addButton.title = @"Add an IP Address";
    
    CNPGridMenuItem *deleteButton = [[CNPGridMenuItem alloc] init];
    deleteButton.icon = [UIImage imageNamed:@"trash_big.png"];
    deleteButton.title = @"Delete IP Addresses";
    
    CNPGridMenuItem *backupButton = [[CNPGridMenuItem alloc] init];
    backupButton.icon = [UIImage imageNamed:@"backup.png"];
    backupButton.title = @"Backup All";
    
    CNPGridMenuItem *restoreButton = [[CNPGridMenuItem alloc] init];
    restoreButton.icon = [UIImage imageNamed:@"restore.png"];
    restoreButton.title = @"Restore All";
    
    CNPGridMenuItem *closeButton = [[CNPGridMenuItem alloc] init];
    closeButton.icon = [UIImage imageNamed:@"close_big.png"];
    closeButton.title = @"Close";
    
    self.gridMenu = [[CNPGridMenu alloc] initWithMenuItems:@[addButton, deleteButton, ruleButton, backupButton, restoreButton, closeButton]];
    self.gridMenu.delegate = self;
    
    self.messageLabel.text = @"No Allow Information";
    
#if 0
    //refresh control
    self.refreshView = [[SSARefreshControl alloc] initWithScrollView:self.tableView andRefreshViewLayerType:SSARefreshViewLayerTypeOnScrollView];
    self.refreshView.delegate = self;
#else
    //
    self.navigationItem.title = @"Allow [deprecated]";
    self.detailButton =
    [[UIBarButtonItem alloc]
     initWithImage:[UIImage imageNamed:@"other_tool.png"]
     style:UIBarButtonItemStylePlain
     target:self action:@selector(showDeprecatedMessage)];
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects:_detailButton, nil];
    self.messageLabel.text = @"The Function is Deprecated";
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //[self refresh];
    [self showDeprecatedMessage];
}

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)goRuleVC {
    [KVNProgress showWithStatus:@"Retrieving..."];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        
        [IJTHTTP retrieveFrom:@"BackupRestoreFirewall.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@&Action=GET&Type=Allow", self.serialNumber]
                      timeout:5
                        block:^(NSData *data){
                            time_t lasttime = -1;
                            NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            [IJTDispatch dispatch_main:^{
                                [KVNProgress dismiss];
                            }];
                            
                            NSDictionary *dict = nil;
                            if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                                lasttime = -1;
                            }
                            else {
                                dict = [IJTJson json2dictionary:jsonstring];
                                if(dict) {
                                    NSString *time = [dict valueForKey:@"AllowTime"];
                                    lasttime = [time intValue];
                                }
                                else {
                                    lasttime = -2;
                                }
                            }
                            if(lasttime == -1) {
                                [self showInfoMessage:@"You didn\'t backup before."];
                            }
                            else if(lasttime == -2) {
                                [self showErrorMessage:@"Retrieve last time backup error, try again?"];
                            }
                            else if(dict) {
                                NSString *allow = [dict valueForKey:@"Allow"];
                                NSArray *ruleList = [IJTJson json2array:allow];
                                UINavigationController *ruleNavVC = (UINavigationController *)
                                [self.storyboard instantiateViewControllerWithIdentifier:@"RuleNavVC"];
                                ruleNavVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                                IJTRuleTableViewController *ruleVC = (IJTRuleTableViewController *)[ruleNavVC.viewControllers firstObject];
                                ruleVC.delegate = self;
                                ruleVC.ruleList = [NSMutableArray arrayWithArray:ruleList];
                                ruleVC.lastTime = lasttime;
                                ruleVC.op = IJTFirewallOperatorAllow;
                                [self.navigationController presentViewController:ruleNavVC animated:YES completion:nil];
                            }
                        }];
    }];
}

- (void)beganRefreshing {
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        [self refresh];
        [self.refreshView endRefreshing];
    }];
}
#pragma mark functions
- (void)refresh {
    self.allowList = [IJTAllowAndBlock allowList];
    [self.tableView reloadData];
}

- (void)showFunction {
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    if(self.tableView.editing == YES) {
        [self.tableView setEditing:NO animated:YES];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [self presentGridMenu:self.gridMenu animated:YES completion:nil];
        }];
    }
    else {
        [self presentGridMenu:self.gridMenu animated:YES completion:nil];
    }
}

- (void)gridMenu:(CNPGridMenu *)menu didTapOnItem:(CNPGridMenuItem *)item {
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    [self dismissGridMenuAnimated:YES completion:^{
        if([item.title hasPrefix:@"Add"]) {
            [self addAllow];
        }
        else if([item.title hasPrefix:@"Delete"]) {
            if(self.allowList.count <= 0) {
                [self showInfoMessage:@"There is no allow information."];
                return;
            }
            
            [self.tableView setEditing:YES animated:YES];
            self.dismissButton.enabled = NO;
            self.tabBarController.tabBar.userInteractionEnabled = NO;
            
            NSMutableArray *array = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
            [array replaceObjectAtIndex:0 withObject:self.doneButton];
            self.navigationItem.rightBarButtonItems = array;
        }
        else if([item.title hasPrefix:@"What"]) {
            [self showDeprecatedMessage];
            //[self goRuleVC];
        }
        else if([item.title hasPrefix:@"Backup"]) {
            [self showDeprecatedMessage];
            //[self backupAction];
        }
        else if([item.title hasPrefix:@"Restore"]) {
            [self showDeprecatedMessage];
            //[self restoreAction];
        }
    }];
}

- (void)doneAction {
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    [array replaceObjectAtIndex:0 withObject:self.detailButton];
    self.navigationItem.rightBarButtonItems = array;
    
    [self.tableView setEditing:NO animated:YES];
    self.dismissButton.enabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
}

- (void)backupAction {
    [KVNProgress showWithStatus:@"Retrieving last time backup..."];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        
        [IJTHTTP retrieveFrom:@"BackupRestoreFirewall.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@&Action=GET&Type=Allow", self.serialNumber]
                      timeout:5
                        block:^(NSData *data){
                            time_t lasttime = -1;
                            NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            [IJTDispatch dispatch_main:^{
                                [KVNProgress dismiss];
                            }];
                            
                            if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                                lasttime = -1;
                            }
                            else {
                                NSDictionary *dict = [IJTJson json2dictionary:jsonstring];
                                if(dict) {
                                    NSString *time = [dict valueForKey:@"AllowTime"];
                                    lasttime = [time intValue];
                                }
                                else {
                                    lasttime = -2;
                                }
                            }
                            
                            NSString *timestring = nil;
                            if(lasttime == -1 || lasttime == -2) {
                                timestring = @"Never";
                            }
                            else {
                                timestring = [IJTFormatString formatTime:lasttime];
                            }
                            
                            if(lasttime == -2) {
                                [self showErrorMessage:@"Retrieve last time backup error, try again?"];
                            }
                            else {
                                [IJTDispatch dispatch_main:^{
                                    
                                    SCLAlertView *alert = [IJTShowMessage baseAlertView];
                                    [alert addButton:@"Yes" actionBlock:^(void) {
                                        [IJTDispatch dispatch_main:^{
                                            [KVNProgress showWithStatus:@"Posting..."];
                                        }];
                                        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                                            NSString *allowContents = [IJTJson array2string:self.allowList];
                                            allowContents = [IJTHTTP string2post:allowContents];
                                            
                                            [IJTHTTP retrieveFrom:@"BackupRestoreFirewall.php"
                                                             post:[NSString stringWithFormat:@"SerialNumber=%@&Action=SET&Type=Allow&Value=%@", self.serialNumber, allowContents]
                                                          timeout:5
                                                            block:^(NSData *data){
                                                                NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                                                                [IJTDispatch dispatch_main:^{
                                                                    [KVNProgress dismiss];
                                                                }];
                                                                if([jsonstring integerValue] == IJTStatusServerSuccess) {
                                                                    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                                                                        [self showSuccessMessage:@"Success"];
                                                                    }];
                                                                }
                                                                else {
                                                                    [self showErrorMessage:@"Error when posting, try again?"];
                                                                }
                                                            }];
                                        }];
                                    }];
                                    
                                    if(self.allowList.count <= 0) {
                                        [alert showWarning:@"Backup"
                                                  subTitle:[NSString stringWithFormat:@"Allow list is empty.\nLast time back : %@.", timestring]
                                          closeButtonTitle:@"No"
                                                  duration:0];
                                    }
                                    else {
                                        [alert showInfo:@"Backup"
                                               subTitle:[NSString stringWithFormat:@"Last time backup : %@.", timestring]
                                       closeButtonTitle:@"No"
                                               duration:0];
                                    }
                                }];
                            }
                            
                        
                        }];
        
    }];
}

- (void)restoreAction {
    [KVNProgress showWithStatus:@"Retrieving last time backup..."];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        [IJTHTTP retrieveFrom:@"BackupRestoreFirewall.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@&Action=GET&Type=Allow", self.serialNumber]
                      timeout:5
                        block:^(NSData *data){
                            time_t lasttime = -1;
                            NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            [IJTDispatch dispatch_main:^{
                                [KVNProgress dismiss];
                            }];
                            
                            NSDictionary *dict = nil;
                            if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                                lasttime = -1;
                            }
                            else {
                                dict = [IJTJson json2dictionary:jsonstring];
                                if(dict) {
                                    NSString *time = [dict valueForKey:@"AllowTime"];
                                    lasttime = [time intValue];
                                }
                                else {
                                    lasttime = -2;
                                }
                            }
                            
                            NSString *timestring = nil;
                            if(lasttime == -1 || lasttime == -2) {
                                timestring = @"Never";
                            }
                            else {
                                timestring = [IJTFormatString formatTime:lasttime];
                            }
                            
                            if(lasttime == -2) {
                                [self showErrorMessage:@"Retrieve last time backup error, try again?"];
                            }
                            else {
                                [IJTDispatch dispatch_main:^{
                                    SCLAlertView *alert = [IJTShowMessage baseAlertView];
                                    NSString *closeButton = @"OK";
                                    if(lasttime != -1) {
                                        [alert addButton:@"Yes" actionBlock:^(void) {
                                            NSString *allow = [dict valueForKey:@"Allow"];
                                            [IJTAllowAndBlock restoreAllowList:[IJTAllowAndBlock createAllowWithJson:allow] target:self];
                                            self.allowList = [IJTAllowAndBlock allowList];
                                            
                                            [self refresh];
                                            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                                                [self showSuccessMessage:@"Success"];
                                            }];
                                        }];
                                        closeButton = @"No";
                                    }
                                    
                                    [alert showInfo:@"Restore"
                                           subTitle:[NSString stringWithFormat:@"Last time backup : %@.", timestring]
                                   closeButtonTitle:closeButton
                                           duration:0];
                                }];
                                
                            }
                        }];
    }];
}

- (void)addAllow {
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    
    UITextField *textField = [alert addTextField:@"IP Address"];
    textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    textField.delegate = self;
    
    [alert addButton:@"Allow it" actionBlock:^(void) {
        
        [textField resignFirstResponder];
        
        if(textField.text.length <= 0)
            return;
        
        if(![IJTValueChecker checkIpv4Address:textField.text]) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", textField.text]];
            }];
            return;
        }
        if([IJTAllowAndBlock exsitInAllow:textField.text]) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is already exsit.", textField.text]];
            }];
            return;
        }
        if([IJTAllowAndBlock exsitInBlock:textField.text]) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is already exsit in block list.", textField.text]];
            }];
            return;
        }
        
        [IJTAllowAndBlock newAllow:textField.text
                              time:time(NULL)
                       displayName:@"Injector"
                            enable:YES];
        self.allowList = [IJTAllowAndBlock allowList];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [self.tableView reloadData];
            [self showSuccessMessage:@"Success"];
        }];
        
    }];
    [alert showEdit:@"Allow" subTitle:@"Please enter an IP Address you want to allow." closeButtonTitle:@"Done" duration:0];
}

- (void)callback {
    [self refresh];
}

#pragma mark text field delegate
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"1234567890.any\b";
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.allowList.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    return self.allowList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [NSString stringWithFormat:@"Allow(%ld)", (unsigned long)self.allowList.count];
    return @"";
}

#pragma mark Table view delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTAllowBlockListTableViewCell *cell = (IJTAllowBlockListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AllowCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.allowList[indexPath.row]];
    [IJTFormatUILabel dict:dict
                       key:@"IpAddress"
                     label:cell.ipAddressLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    NSNumber *time = [dict valueForKey:@"AddTime"];
    NSString *timestring = [IJTFormatString formatTime:[time longValue]];
    [dict setValue:timestring forKey:@"AddTimeString"];
    [IJTFormatUILabel dict:dict
                       key:@"AddTimeString"
                     label:cell.addTimeLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"DisplayName" prefix:@"App When You Allow : "
                     label:cell.appLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    NSNumber *enable = [dict valueForKey:@"Enable"];
    if([enable boolValue]) {
        [IJTFormatUILabel text:@"Yes"
                         label:cell.enableLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
    }
    else {
        [IJTFormatUILabel text:@"No"
                         label:cell.enableLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
    }
    
    cell.enable = [enable boolValue];
    
    cell.ipAddress = [dict valueForKey:@"IpAddress"];
    cell.lastTime = [time longValue];
    cell.appName = [dict valueForKey:@"DisplayName"];
    
    [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:11];
    }];
    
    [cell layoutIfNeeded];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    IJTAllowBlockListTableViewCell *cell = (IJTAllowBlockListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    NSString *enableText = cell.enable ? @"Disable" : @"Enable";

    [alert addButton:enableText actionBlock:^{
        [IJTAllowAndBlock setEnableAllow:!cell.enable ipAddress:cell.ipAddress];
        [self refresh];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [self showSuccessMessage:@"Success"];
        }];
    }];
    
    [alert addButton:@"Move to Block" actionBlock:^{
        if([IJTAllowAndBlock allowMoveToBlock:cell.ipAddress target:self]) {
            [self refresh];
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [self showSuccessMessage:@"Success"];
            }];
        }
    }];
    
    [alert showInfo:@"Action"
           subTitle:[NSString stringWithFormat:@"Select a Action at %@ :", cell.ipAddress]
   closeButtonTitle:@"Nothing to do"
           duration:0];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        IJTAllowBlockListTableViewCell *cell = (IJTAllowBlockListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        SCLAlertView *alert = [IJTShowMessage baseAlertView];
        
        [alert addButton:@"Yes" actionBlock:^(void) {
            [IJTAllowAndBlock removeAllowIpAddress:cell.ipAddress];
            self.allowList = [IJTAllowAndBlock allowList];
            [self.tableView reloadData];
        }];
        
        [alert showWarning:@"Warning"
                  subTitle:[NSString stringWithFormat:@"Are you sure delete: %@?", cell.ipAddress]
          closeButtonTitle:@"No"
                  duration:0];
    }
}

@end
