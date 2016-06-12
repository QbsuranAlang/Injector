//
//  IJTWOLTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWOLTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTWOLResultTableViewController.h"

@interface IJTWOLTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUITextField *amountTextField;
@property (nonatomic, strong) FUITextField *intervalTextField;
@property (nonatomic, strong) FUITextField *targetIpAddressTextField;
@property (nonatomic, strong) FUITextField *targetPortTextField;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) FUISegmentedControl *targetTypeSegmentedControl;
@property (nonatomic, strong) Reachability *wifiReachability;

@end

@implementation IJTWOLTableViewController

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
    
    self.targetTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.targetTextField.placeholder = @"Target MAC address";
    
    self.targetIpAddressTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.targetIpAddressTextField.placeholder = @"Target IP address";
    
    self.targetPortTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.targetPortTextField.placeholder = @"Target port number(Default: 9)";
    self.targetPortTextField.text = @"9";
    
    self.amountTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.amountTextField.placeholder = @"Send frame amount(0 equal infinity)";
    self.amountTextField.text = @"0";
    
    self.intervalTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.intervalTextField.placeholder = @"Send frame interval(µs)";
    self.intervalTextField.returnKeyType = UIReturnKeyDone;
    self.intervalTextField.text = @"1000000";
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoWOLVC) forControlEvents:UIControlEventTouchUpInside];
    
    self.targetTypeSegmentedControl = [[FUISegmentedControl alloc]
                                       initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 28)];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"LAN" atIndex:0 animated:NO];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"WAN" atIndex:1 animated:NO];
    [self.targetTypeSegmentedControl setSelectedSegmentIndex:0];
    [self.targetTypeSegmentedControl addTarget:self action:@selector(targetTypeChange) forControlEvents:UIControlEventValueChanged];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    if(self.fromLAN) {
        [self.targetTypeSegmentedControl setSelectedSegmentIndex:1];
        [self.targetTypeSegmentedControl setEnabled:NO];
        self.targetTextField.text = self.macAddressFromLan;
        self.targetIpAddressTextField.text = self.ipAddressFromLan;
        [self.targetTextField setEnabled:NO];
        [self.targetIpAddressTextField setEnabled:NO];
    }
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

- (void)targetTypeChange {
    [self.tableView reloadData];
    [self reachabilityChanged:nil];
}

- (void)gotoWOLVC {
    [self dismissKeyboard];
    
    if(self.targetTextField.text.length <= 0) {
        [self showErrorMessage:@"Target MAC address is empty."];
        return;
    }
    else if(![IJTValueChecker checkMacAddress:self.targetTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid MAC address.", self.targetTextField.text]];
        return;
    }
    
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        if(self.targetIpAddressTextField.text.length <= 0) {
            [self showErrorMessage:@"Target IP address is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:self.targetIpAddressTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.targetIpAddressTextField.text]];
            return;
        }
        if(self.targetPortTextField.text.length <= 0) {
            [self showErrorMessage:@"Target Port number is empty."];
            return;
        }
        else if(![IJTValueChecker checkUint16:self.targetPortTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.targetPortTextField.text]];
            return;
        }
        else if([self.self.targetPortTextField.text integerValue] == 0) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.targetPortTextField.text]];
            return;
        }
    }
    
    if(self.amountTextField.text.length <= 0) {
        [self showErrorMessage:@"Amount is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:self.amountTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid amount value.", self.amountTextField.text]];
        return;
    }
    
    if([self.amountTextField.text integerValue] != 1) {
        if(self.intervalTextField.text.length <= 0) {
            [self showErrorMessage:@"Interval is empty."];
            return;
        }
        else if(![IJTValueChecker checkAllDigit:self.intervalTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid interval value.", self.intervalTextField.text]];
            return;
        }
    }
    
    IJTWOLResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Wake-on-LANResultVC"];
    
    vc.targetIpAddress = self.targetIpAddressTextField.text;
    vc.targetMacAddress = self.targetTextField.text;
    vc.targetPortNumber = [self.targetPortTextField.text integerValue];
    vc.multiToolButton = self.multiToolButton;
    vc.interval = (useconds_t)[self.intervalTextField.text longLongValue];
    vc.amount = [self.amountTextField.text integerValue];
    vc.selectedIndex = self.targetTypeSegmentedControl.selectedSegmentIndex;
    [self.navigationController pushViewController:vc animated:YES];
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

#pragma mark text field delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.targetTextField) {
        if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
            [self.amountTextField becomeFirstResponder];
        }
        else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
            [self.targetIpAddressTextField becomeFirstResponder];
        }
    }
    else if(textField == self.targetIpAddressTextField) {
        [self.targetPortTextField becomeFirstResponder];
    }
    else if(textField == self.targetPortTextField) {
        [self.amountTextField becomeFirstResponder];
    }
    else if(textField == self.amountTextField) {
        [self.intervalTextField becomeFirstResponder];
    }
    else if(self.intervalTextField == textField) {
        [self.intervalTextField resignFirstResponder];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.amountTextField || textField == self.intervalTextField ||
       textField == self.targetPortTextField) {
        allowString = @"1234567890\b";
    }
    else if(textField == self.targetIpAddressTextField) {
        allowString = @"1234567890.\b";
    }
    else if(textField == self.targetTextField) {
        allowString = @"1234567890abcdefABCDEF:\b";
    }
    else
        return YES;
    
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.targetIpAddressTextField.isFirstResponder) {
        [self.targetIpAddressTextField resignFirstResponder];
    }
    else if(self.targetPortTextField.isFirstResponder) {
        [self.targetPortTextField resignFirstResponder];
    }
    else if(self.amountTextField.isFirstResponder) {
        [self.amountTextField resignFirstResponder];
    }
    else if(self.intervalTextField.isFirstResponder) {
        [self.intervalTextField resignFirstResponder];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        return 4;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        return 5;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        switch (section) {
            case 0: return 2;
            case 1: return 1;
            case 2: return 1;
            case 3: return 1;
        }
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        switch (section) {
            case 0: return 2;
            case 1: return 2;
            case 2: return 1;
            case 3: return 1;
            case 4: return 1;
        }
    }
    return 0;
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
            
            [cell.contentView addSubview:self.targetTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 1) ||
            (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 2)) {
        if(indexPath.row == 0) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:self.amountTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 2) ||
            (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 3)) {
        if(indexPath.row == 0) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:self.intervalTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 3) ||
            (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 4)) {
        if(indexPath.row == 0) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:self.actionButton];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 1) {
        if(indexPath.row == 0) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:self.targetIpAddressTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:self.targetPortTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        if(indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 2)
            return 44.0f;
        else if(indexPath.section == 3)
            return 55.0f;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        if(indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 2 || indexPath.section == 3)
            return 44.0f;
        else if(indexPath.section == 4)
            return 55.0f;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        if(section == 0)
            return @"Domain";
        else if(section == 1)
            return @"Amount";
        else if(section == 2)
            return @"Interval";
        else if(section == 3)
            return @"Action";
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        if(section == 0)
            return @"Domain";
        else if(section == 1)
            return @"Remote";
        else if(section == 2)
            return @"Amount";
        else if(section == 3)
            return @"Interval";
        else if(section == 4)
            return @"Action";
    }
    return @"";
}

@end
