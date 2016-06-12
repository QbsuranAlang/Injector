//
//  IJTNetbiosTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/14.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTNetbiosTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTNetbiosResultTableViewController.h"

@interface IJTNetbiosTableViewController ()

@property (nonatomic, strong) FUISegmentedControl *targetTypeSegmentedControl;
@property (nonatomic, strong) FUITextField *singleTextField;
@property (nonatomic, strong) FUITextField *intervalTextField;
@property (nonatomic, strong) FUITextField *timeoutTextField;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) Reachability *wifiReachability;


@end

@implementation IJTNetbiosTableViewController

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
    
    
    self.targetTypeSegmentedControl = [[FUISegmentedControl alloc]
                                       initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 28)];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"Single" atIndex:0 animated:NO];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"LAN" atIndex:1 animated:NO];
    [self.targetTypeSegmentedControl setSelectedSegmentIndex:0];
    [self.targetTypeSegmentedControl addTarget:self action:@selector(targetTypeChange) forControlEvents:UIControlEventValueChanged];
    
    self.singleTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.singleTextField.placeholder = @"Target IP address";
    
    self.timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"1000";
    self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    
    self.intervalTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.intervalTextField.placeholder = @"Send frame interval(µs)";
    self.intervalTextField.returnKeyType = UIReturnKeyDone;
    self.intervalTextField.text = @"1000";
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoNetbiosVC) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    if(self.fromLAN) {
        [self.targetTypeSegmentedControl setEnabled:NO];
        [self.singleTextField setEnabled:NO];
        self.singleTextField.text = self.ipAddressFromLan;
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
    [self.navigationController dismissGridMenuAnimated:YES completion:nil];
}

- (void)targetTypeChange {
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        self.timeoutTextField.returnKeyType = UIReturnKeyNext;
    }
    
    [self.tableView reloadData];
    [self reachabilityChanged:nil];
}

- (void)gotoNetbiosVC {
    
    [self dismissKeyboard];
    
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        if(self.singleTextField.text.length <= 0) {
            [self showErrorMessage:@"Target IP address is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:self.singleTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.singleTextField.text]];
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
    
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        if(self.intervalTextField.text.length <= 0) {
            [self showErrorMessage:@"Interval is empty."];
            return;
        }
        else if(![IJTValueChecker checkAllDigit:_intervalTextField.text] ||
                [self.intervalTextField.text longLongValue] <= 0) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid interval value.", _intervalTextField.text]];
            return;
        }
    }
    
    IJTNetbiosResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"NetBIOSResultVC"];
    
    vc.singleIpAddress = self.singleTextField.text;
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.interval = (useconds_t)[self.intervalTextField.text longLongValue];
    vc.selectedIndex = self.targetTypeSegmentedControl.selectedSegmentIndex;
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable && self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        [self showWarningMessage:@"Now select LAN as target, but there is no Wi-Fi connection."];
        [self.actionButton setEnabled:NO];
        [self.actionButton setTitle:@"No Wi-Fi Connection" forState:UIControlStateNormal];
    }
    else {
        [self.actionButton setEnabled:YES];
        [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    }
}

#pragma text view delegate
- (void)dismissKeyboard {
    if(self.singleTextField.isFirstResponder) {
        [self.singleTextField resignFirstResponder];
    }
    else if(self.timeoutTextField.isFirstResponder) {
        [self.timeoutTextField resignFirstResponder];
    }
    else if(self.intervalTextField.isFirstResponder) {
        [self.intervalTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.singleTextField) {
        [self.timeoutTextField becomeFirstResponder];
    }
    else if(textField == self.timeoutTextField) {
        if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
            [self.timeoutTextField resignFirstResponder];
        }
        else
            [self.intervalTextField becomeFirstResponder];
    }
    else if(textField == self.intervalTextField) {
        [self.intervalTextField resignFirstResponder];
    }
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.timeoutTextField || textField == self.intervalTextField) {
        allowString = @"1234567890\b";
    }
    else if(textField == self.singleTextField) {
        allowString = @"1234567890.\b";
    }
    else
        return YES;
    
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        GET_ARG_CELL;
        
        [IJTFormatUILabel text:@"Type"
                         label:cell.nameLabel
                          font:[UIFont systemFontOfSize:17]];
        
        [cell.controlView addSubview:self.targetTypeSegmentedControl];
        
        [cell layoutIfNeeded];
        
        CGFloat width = CGRectGetWidth(cell.controlView.frame);
        self.targetTypeSegmentedControl.frame = CGRectMake(width - 150, 0, 150, 28);
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 1 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:self.singleTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 2 && indexPath.row == 0) || (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 1 && indexPath.row == 0)) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:self.timeoutTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 2 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:self.intervalTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 3 && indexPath.row == 0) || (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 3 && indexPath.row == 0)) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:self.actionButton];
        
        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Target Type";
    
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        if(section == 1)
            return @"Single";
        else if(section == 2)
            return @"Read Timeout";
        else if (section == 3)
            return @"Action";
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        if(section == 1)
            return @"Read Timeout";
        else if(section == 2)
            return @"Inject Interval";
        else if (section == 3)
            return @"Action";
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 2)
        return 44.0f;
    else if(indexPath.section == 3)
        return 55.0f;
    return 0.0f;
}
@end
