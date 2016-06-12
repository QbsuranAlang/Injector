//
//  IJTArpScanTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/19.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArpScanTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTArpScanResultTableViewController.h"

@interface IJTArpScanTableViewController ()

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) FUISegmentedControl *typeSegmentedControl;
@property (nonatomic, strong) FUITextField *timeoutTextField;
@property (nonatomic, strong) FUITextField *networkTextField;
@property (nonatomic, strong) FUITextField *slashTextField;
@property (nonatomic, strong) FUITextField *startIpTextField;
@property (nonatomic, strong) FUITextField *endIpTextField;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) FUITextField *intervalTextField;
@end

@implementation IJTArpScanTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.multiToolButton == nil) {
        self.dismissButton = [[UIBarButtonItem alloc]
                              initWithImage:[UIImage imageNamed:@"down.png"]
                              style:UIBarButtonItemStylePlain
                              target:self action:@selector(dismissVC)];
    }
    else {
        self.dismissButton = self.multiToolButton;
    }
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.typeSegmentedControl = [[FUISegmentedControl alloc]
                                 initWithFrame:CGRectMake(8, 8, SCREEN_WIDTH - 16, 28)];
    [self.typeSegmentedControl insertSegmentWithTitle:@"LAN" atIndex:0 animated:NO];
    [self.typeSegmentedControl insertSegmentWithTitle:@"Network" atIndex:1 animated:NO];
    [self.typeSegmentedControl insertSegmentWithTitle:@"Range" atIndex:2 animated:NO];
    [self.typeSegmentedControl setSelectedSegmentIndex:0];
    [self.typeSegmentedControl addTarget:self action:@selector(typeChange) forControlEvents:UIControlEventValueChanged];
    
    self.timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"1000";
    
    self.intervalTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.intervalTextField.placeholder = @"Send frame interval(µs)";
    self.intervalTextField.returnKeyType = UIReturnKeyDone;
    self.intervalTextField.text = @"1000";
    
    self.networkTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.networkTextField.placeholder = @"Network";
    
    self.slashTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.slashTextField.placeholder = @"Slash(1-32)";
    
    self.startIpTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.startIpTextField.placeholder = @"Start IP address";
    
    self.endIpTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.endIpTextField.placeholder = @"End IP address";
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoScanVC) forControlEvents:UIControlEventTouchUpInside];
    
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

- (void)typeChange {
    [self dismissKeyboard];
    
    self.networkTextField.text = @"";
    self.slashTextField.text = @"";
    self.startIpTextField.text = @"";
    self.endIpTextField.text = @"";
    
    if(self.typeSegmentedControl.selectedSegmentIndex == 1) {
        int slash = 0;
        NSString *network = [IJTNetowrkStatus getWiFiNetworkAndSlash:&slash];
        if(network) {
            self.networkTextField.text = network;
            self.slashTextField.text = [NSString stringWithFormat:@"%d", slash];
        }
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 2) {
        NSArray *arr = [IJTNetowrkStatus getWiFiNetworkStartAndEndIpAddress];
        if(arr && arr.count == 2) {
            self.startIpTextField.text = [arr objectAtIndex:0];
            self.endIpTextField.text = [arr objectAtIndex:1];
        }
    }
    
    [self.tableView reloadData];
}

- (void)gotoScanVC {
    
    [self dismissKeyboard];
    
    if(self.typeSegmentedControl.selectedSegmentIndex == 1) {
        if(_networkTextField.text.length <= 0) {
            [self showErrorMessage:@"Network is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:_networkTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid network address.", _networkTextField.text]];
            return;
        }
        if(_slashTextField.text.length <= 0) {
            [self showErrorMessage:@"Slash is empty."];
            return;
        }
        else if(![IJTValueChecker checkSlash:_slashTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid slash number.", _slashTextField.text]];
            return;
        }
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 2) {
        if(_startIpTextField.text.length <= 0) {
            [self showErrorMessage:@"Start IP address is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:_startIpTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", _startIpTextField.text]];
            return;
        }
        if(_endIpTextField.text.length <= 0) {
            [self showErrorMessage:@"End IP address is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:_endIpTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", _endIpTextField.text]];
            return;
        }
    }
    
    if(self.timeoutTextField.text.length <= 0) {
        [self showErrorMessage:@"Timeout is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:_timeoutTextField.text] ||
            [self.timeoutTextField.text longLongValue] <= 0) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid timeout value.", _timeoutTextField.text]];
        return;
    }
    
    if(self.intervalTextField.text.length <= 0) {
        [self showErrorMessage:@"Interval is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:_intervalTextField.text] ||
            [self.intervalTextField.text longLongValue] <= 0) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid interval value.", _intervalTextField.text]];
        return;
    }
    
    IJTArpScanResultTableViewController *vc = (IJTArpScanResultTableViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"ArpScanResultVC"];
    vc.scanType = (int)self.typeSegmentedControl.selectedSegmentIndex;
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.networkAddress = self.networkTextField.text;
    vc.slash = [self.slashTextField.text intValue];
    vc.startIpAddress = self.startIpTextField.text;
    vc.endIpAddress = self.endIpTextField.text;
    vc.interval = (useconds_t)[self.intervalTextField.text longLongValue];
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark text field

- (void)dismissKeyboard {
    if(self.timeoutTextField.isFirstResponder) {
        [self.timeoutTextField resignFirstResponder];
    }
    else if(self.networkTextField.isFirstResponder) {
        [self.networkTextField resignFirstResponder];
    }
    else if(self.slashTextField.isFirstResponder) {
        [self.slashTextField resignFirstResponder];
    }
    else if(self.startIpTextField.isFirstResponder) {
        [self.startIpTextField resignFirstResponder];
    }
    else if(self.endIpTextField.isFirstResponder) {
        [self.endIpTextField resignFirstResponder];
    }
    else if(self.intervalTextField.isFirstResponder) {
        [self.intervalTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(self.typeSegmentedControl.selectedSegmentIndex == 1) {
        if(textField == self.networkTextField) {
            [self.slashTextField becomeFirstResponder];
        }
        else if(textField == self.slashTextField) {
            [self.timeoutTextField becomeFirstResponder];
        }
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 2) {
        if(textField == self.startIpTextField) {
            [self.endIpTextField becomeFirstResponder];
        }
        else if(textField == self.endIpTextField) {
            [self.timeoutTextField becomeFirstResponder];
        }
    }
    
    if(textField == self.timeoutTextField) {
        [self.intervalTextField becomeFirstResponder];
    }
    else if(textField == self.intervalTextField) {
        [self.intervalTextField resignFirstResponder];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.timeoutTextField || textField == self.slashTextField || textField == self.intervalTextField) {
        allowString = @"1234567890\b";
    }
    else if(textField == self.networkTextField ||
            textField == self.startIpTextField ||
            textField == self.endIpTextField) {
        allowString = @"1234567890.\b";
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
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"ARP-scan"];
        [self.actionButton setEnabled:NO];
        [self.actionButton setTitle:@"No Wi-Fi Connection" forState:UIControlStateNormal];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.actionButton setEnabled:YES];
        [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    }
    [self typeChange];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    
    if(self.typeSegmentedControl.selectedSegmentIndex == 0) {
        return 4;
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 1 ||
            self.typeSegmentedControl.selectedSegmentIndex == 2) {
        return 5;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.typeSegmentedControl.selectedSegmentIndex == 0) {
        return 1;
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 1 ||
            self.typeSegmentedControl.selectedSegmentIndex == 2) {
        switch (section) {
            case 0: case 2: case 3: case 4:
                return 1;
                
            case 1:
                return 2;
        }
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:self.typeSegmentedControl];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if((self.typeSegmentedControl.selectedSegmentIndex == 0 &&
            indexPath.section == 1 && indexPath.row == 0) ||
            (self.typeSegmentedControl.selectedSegmentIndex == 1 &&
             indexPath.section == 2 && indexPath.row == 0) ||
            (self.typeSegmentedControl.selectedSegmentIndex == 2 &&
            indexPath.section == 2 && indexPath.row == 0)) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:self.timeoutTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if((self.typeSegmentedControl.selectedSegmentIndex == 0 &&
             indexPath.section == 2 && indexPath.row == 0) ||
            (self.typeSegmentedControl.selectedSegmentIndex == 1 &&
             indexPath.section == 3 && indexPath.row == 0) ||
            (self.typeSegmentedControl.selectedSegmentIndex == 2 &&
             indexPath.section == 3 && indexPath.row == 0)) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:self.intervalTextField];
            
        [cell layoutIfNeeded];
        return cell;
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 1 &&
            indexPath.section == 1 &&
            (indexPath.row == 0 || indexPath.row == 1)) {
        GET_EMPTY_CELL;
        
        if(indexPath.row == 0) {
            [cell.contentView addSubview:self.networkTextField];
        }
        else if(indexPath.row == 1) {
            [cell.contentView addSubview:self.slashTextField];
        }
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 2 &&
            indexPath.section == 1 &&
            (indexPath.row == 0 || indexPath.row == 1)) {
        GET_EMPTY_CELL;
        
        if(indexPath.row == 0) {
            [cell.contentView addSubview:self.startIpTextField];
        }
        else if(indexPath.row == 1) {
            [cell.contentView addSubview:self.endIpTextField];
        }
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if((self.typeSegmentedControl.selectedSegmentIndex == 0 &&
            indexPath.section == 3 && indexPath.row == 0) ||
            ((self.typeSegmentedControl.selectedSegmentIndex == 1 ||
              self.typeSegmentedControl.selectedSegmentIndex == 2 ) &&
             indexPath.section == 4 && indexPath.row == 0)) {
                
                GET_EMPTY_CELL;
                
                self.actionButton.frame = CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16);
                [cell.contentView addSubview:_actionButton];
                
                [cell layoutIfNeeded];
                return cell;
            }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if(section == 0) {
        return @"Scan Type";
    }
    
    if(self.typeSegmentedControl.selectedSegmentIndex == 0) {
        if(section == 1)
            return @"Read Timeout";
        else if(section == 2)
            return @"Inject Interval";
        else if(section == 3)
            return @"Action";
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 1 ||
            self.typeSegmentedControl.selectedSegmentIndex == 2) {
        if(section == 1)
            return @"Range";
        else if(section == 2)
            return @"Read Timeout";
        else if(section == 3)
            return @"Inject Interval";
        else if(section == 4)
            return @"Action";
    }
    
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0)
        return 44.f;
    
    if(self.typeSegmentedControl.selectedSegmentIndex == 0) {
        if(indexPath.section == 1 || indexPath.section == 2)
            return 44.f;
        else if(indexPath.section == 3)
            return 55.f;
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 1 ||
            self.typeSegmentedControl.selectedSegmentIndex == 2) {
        if(indexPath.section == 1 || indexPath.section == 2 || indexPath.section == 3)
            return 44.f;
        else if(indexPath.section == 4)
            return 55.f;
    }
    
    return 0.0f;
}


@end
