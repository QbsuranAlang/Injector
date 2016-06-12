//
//  IJTSSDPTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTSSDPTableViewController.h"
#import "IJTSSDPResultTableViewController.h"
#import "IJTArgTableViewCell.h"

@interface IJTSSDPTableViewController ()

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) FUITextField *timeoutTextField;
@property (nonatomic, strong) FUISegmentedControl *targetTypeSegmentedControl;
@property (nonatomic, strong) FUITextField *targetTextField;

@end

@implementation IJTSSDPTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.fromLAN) {
        self.dismissButton = self.popButton;
    }
    else if(self.multiToolButton == nil) {
        self.dismissButton = [[UIBarButtonItem alloc]
                              initWithImage:[UIImage imageNamed:@"down.png"]
                              style:UIBarButtonItemStylePlain
                              target:self action:@selector(dismissVC)];
    }
    else {
        self.dismissButton = self.multiToolButton;
    }
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"1000";
    self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    
    self.targetTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.targetTextField.placeholder = @"Target IP address";
    self.targetTextField.text = SSDP_MULTICAST_ADDR;
    
    self.targetTypeSegmentedControl = [[FUISegmentedControl alloc]
                                       initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 28)];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"LAN" atIndex:0 animated:NO];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"WAN" atIndex:1 animated:NO];
    [self.targetTypeSegmentedControl setSelectedSegmentIndex:0];
    [self.targetTypeSegmentedControl addTarget:self action:@selector(targetTypeChange) forControlEvents:UIControlEventValueChanged];
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoSSDPVC) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
    if([IJTNetowrkStatus supportWifi]) {
        self.wifiReachability = [IJTNetowrkStatus wifiReachability];
        [self.wifiReachability startNotifier];
        [self reachabilityChanged:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self dismissKeyboard];
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if([IJTNetowrkStatus supportWifi])
        [self.wifiReachability stopNotifier];
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoSSDPVC {
    
    [self dismissKeyboard];
    
    if(self.targetTextField.text.length <= 0) {
        [self showErrorMessage:@"Target IP address is empty."];
        return;
    }
    else if(![IJTValueChecker checkIpv4Address:self.targetTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.targetTextField.text]];
        return;
    }
    
    if(self.timeoutTextField.text.length <= 0) {
        [self showErrorMessage:@"Timeout is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:self.timeoutTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid timeout value.", self.timeoutTextField.text]];
        return;
    }
    
    IJTSSDPResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SSDPResultVC"];
    vc.multiToolButton = self.multiToolButton;
    vc.targetIpAddress = self.targetTextField.text;
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.selectedIndex = self.targetTypeSegmentedControl.selectedSegmentIndex;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)targetTypeChange {
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        self.targetTextField.text = SSDP_MULTICAST_ADDR;
    }
    else if (self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        self.targetTextField.text = @"";
    }
    
    [self reachabilityChanged:nil];
    [self.tableView reloadData];
}

#pragma mark text field delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.timeoutTextField.isFirstResponder) {
        [self.timeoutTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if(textField == self.targetTextField) {
        [self.timeoutTextField becomeFirstResponder];
    }
    else if(textField == self.timeoutTextField) {
        [self.timeoutTextField resignFirstResponder];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.targetTextField) {
        allowString = @"1234567890.\b";
    }
    else if(textField == self.timeoutTextField) {
        allowString = @"1234567890\b";
    }
    else
        return YES;
    
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable && self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        [self showWarningMessage:@"Now select LAN as target, but there is no Wi-Fi connection."];
        [self.actionButton setEnabled:NO];
        [self.actionButton setTitle:@"No Wi-Fi Connection" forState:UIControlStateNormal];
    }
    else {
        [self.actionButton setEnabled:YES];
        [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0) {
        if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
            return 1;
        }
        else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
            return 2;
        }
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(indexPath.row == 0) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Type"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            
            [cell.controlView addSubview:_targetTypeSegmentedControl];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.targetTypeSegmentedControl.frame = CGRectMake(width - 180, 0, 180, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:_targetTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if(indexPath.section == 1 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:_timeoutTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 2 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:_actionButton];
        
        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 || indexPath.section == 1)
        return 44.0f;
    else if(indexPath.section == 2)
        return 55.0f;
    return 0.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Domain";
    else if(section == 1)
        return @"Read Timeout";
    else if(section == 2)
        return @"Action";
    return @"";
}
@end
