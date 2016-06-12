//
//  IJTLLMNRTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTLLMNRTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTLLMNRResultTableViewController.h"

@interface IJTLLMNRTableViewController ()

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) FUISegmentedControl *typeSegmentedControl;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUISegmentedControl *targetTypeSegmentedControl;
@property (nonatomic, strong) FUITextField *intervalTextField;
@property (nonatomic, strong) FUITextField *timeoutTextField;

@end

@implementation IJTLLMNRTableViewController

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
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoMDNSVC) forControlEvents:UIControlEventTouchUpInside];
    
    self.targetTextField = [IJTTextField baseTextFieldWithTarget:self];
    
    self.timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"1000";
    
    self.intervalTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.intervalTextField.placeholder = @"Send frame interval(µs)";
    self.intervalTextField.returnKeyType = UIReturnKeyDone;
    self.intervalTextField.text = @"1000";
    
    self.typeSegmentedControl = [[FUISegmentedControl alloc]
                                 initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 28)];
    [self.typeSegmentedControl insertSegmentWithTitle:@"PTR" atIndex:0 animated:NO];
    [self.typeSegmentedControl insertSegmentWithTitle:@"A" atIndex:1 animated:NO];
    [self.typeSegmentedControl insertSegmentWithTitle:@"AAAA" atIndex:2 animated:NO];
    [self.typeSegmentedControl setSelectedSegmentIndex:0];
    [self.typeSegmentedControl addTarget:self action:@selector(typeChange) forControlEvents:UIControlEventValueChanged];
    [self typeChange];
    
    self.targetTypeSegmentedControl = [[FUISegmentedControl alloc]
                                       initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 28)];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"Single" atIndex:0 animated:NO];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"LAN" atIndex:1 animated:NO];
    [self.targetTypeSegmentedControl setSelectedSegmentIndex:0];
    [self.targetTypeSegmentedControl addTarget:self action:@selector(targetTypeChange) forControlEvents:UIControlEventValueChanged];
    [self targetTypeChange];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    if(self.fromLAN) {
        [self.typeSegmentedControl setEnabled:NO];
        [self.targetTypeSegmentedControl setEnabled:NO];
        [self.targetTextField setEnabled:NO];
        self.targetTextField.text = self.ipAddressFromLan;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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

- (void)gotoMDNSVC {
    [self dismissKeyboard];
    if(!(self.typeSegmentedControl.selectedSegmentIndex == 0 &&
         self.targetTypeSegmentedControl.selectedSegmentIndex == 1)) {
        if(self.targetTextField.text.length <= 0) {
            if(self.typeSegmentedControl.selectedSegmentIndex == 1 ||
               self.typeSegmentedControl.selectedSegmentIndex == 2) {
                [self showErrorMessage:@"Hostname is empty."];
            }
            else if(self.typeSegmentedControl.selectedSegmentIndex == 0) {
                [self showErrorMessage:@"IP address is empty."];
            }
            return;
        }
        else if(self.typeSegmentedControl.selectedSegmentIndex == 0 &&
                ![IJTValueChecker checkIpv4Address:self.targetTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.targetTextField.text]];
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
    
    if(self.typeSegmentedControl.selectedSegmentIndex == 0 &&
       self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
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
    
    IJTLLMNRResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LLMNRResultVC"];
    vc.multiToolButton = self.multiToolButton;
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.interval = (useconds_t)[self.intervalTextField.text longLongValue];
    vc.target = self.targetTextField.text;
    vc.typeSelectedIndex = self.typeSegmentedControl.selectedSegmentIndex;
    vc.targetSelectedIndex = self.targetTypeSegmentedControl.selectedSegmentIndex;
    vc.type = [self.typeSegmentedControl titleForSegmentAtIndex:self.typeSegmentedControl.selectedSegmentIndex];
    //vc.isLAN = self.typeSegmentedControl.selectedSegmentIndex == 0 && self.targetTypeSegmentedControl.selectedSegmentIndex == 1 ? YES : NO;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)typeChange {
    if(self.typeSegmentedControl.selectedSegmentIndex == 0 &&
       self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        self.timeoutTextField.returnKeyType = UIReturnKeyNext;
    }
    else {
        self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    }
    
    if(self.typeSegmentedControl.selectedSegmentIndex == 1 ||
       self.typeSegmentedControl.selectedSegmentIndex == 2) {
        if([self.targetTextField.placeholder isEqualToString:@"IPv4 address"]) {
            self.targetTextField.text = @"";
        }
        self.targetTextField.placeholder = @"Hostname";
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 0) {
        if([self.targetTextField.placeholder isEqualToString:@"Hostname"]) {
            self.targetTextField.text = @"";
        }
        self.targetTextField.placeholder = @"IPv4 address";
    }
    
    [self.tableView reloadData];
}

- (void)targetTypeChange {
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        self.timeoutTextField.returnKeyType = UIReturnKeyNext;
    }
    
    [self.tableView reloadData];
}

#pragma text view delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.timeoutTextField.isFirstResponder) {
        [self.timeoutTextField resignFirstResponder];
    }
    else if(self.intervalTextField.isFirstResponder) {
        [self.intervalTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.targetTextField) {
        [self.timeoutTextField becomeFirstResponder];
    }
    else if(textField == self.timeoutTextField) {
        if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1 &&
           self.typeSegmentedControl.selectedSegmentIndex == 0) {
            [self.intervalTextField becomeFirstResponder];
        }
        else
            [self.timeoutTextField resignFirstResponder];
    }
    else if(textField == self.intervalTextField) {
        [self.intervalTextField resignFirstResponder];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.targetTextField) {
        if(self.typeSegmentedControl.selectedSegmentIndex == 1 ||
           self.typeSegmentedControl.selectedSegmentIndex == 2) {
            return YES;
        }
        else if(self.typeSegmentedControl.selectedSegmentIndex == 0) {
            allowString = @"1234567890.\b";
        }
    }
    else if(textField == self.timeoutTextField || textField == self.intervalTextField) {
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
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"mDNS"];
        [self.actionButton setEnabled:NO];
        [self.actionButton setTitle:@"No Wi-Fi Connection" forState:UIControlStateNormal];
    }
    else {
        [self.actionButton setEnabled:YES];
        [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    }
    [self targetTypeChange];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if(self.typeSegmentedControl.selectedSegmentIndex == 0 &&
       self.targetTypeSegmentedControl.selectedSegmentIndex == 1)
        return 5;
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0 || section == 4)
        return 1;
    
    if(self.typeSegmentedControl.selectedSegmentIndex == 1 ||
       self.typeSegmentedControl.selectedSegmentIndex == 2) {
        if(section == 1 || section == 2 || section == 3)
            return 1;
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 0) {
        if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
            if(section == 1)
                return 2;
            else if(section == 2 || section == 3)
                return 1;
        }
        else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
            if(section == 1 || section == 2 || section == 3)
                return 1;
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
            
            [cell.controlView addSubview:_typeSegmentedControl];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.typeSegmentedControl.frame = CGRectMake(width - 180, 0, 180, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if(((self.typeSegmentedControl.selectedSegmentIndex == 1 ||
              self.typeSegmentedControl.selectedSegmentIndex == 2) &&
             indexPath.section == 1 && indexPath.row == 0) ||
            (self.typeSegmentedControl.selectedSegmentIndex == 0 &&
             self.targetTypeSegmentedControl.selectedSegmentIndex == 0 &&
             indexPath.row == 1)) {
                GET_EMPTY_CELL;
                
                [cell.contentView addSubview:self.targetTextField];
                
                [cell layoutIfNeeded];
                return cell;
            }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 0 &&
            indexPath.section == 1 && indexPath.row == 0) {
        GET_ARG_CELL;
        
        [IJTFormatUILabel text:@"Type"
                         label:cell.nameLabel
                          font:[UIFont systemFontOfSize:17]];
        
        [cell.controlView addSubview:self.targetTypeSegmentedControl];
        
        [cell layoutIfNeeded];
        
        CGFloat width = CGRectGetWidth(cell.controlView.frame);
        self.targetTypeSegmentedControl.frame = CGRectMake(width - 180, 0, 180, 28);
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 2 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:self.timeoutTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 0 &&
            self.targetTypeSegmentedControl.selectedSegmentIndex == 1 &&
            indexPath.section == 3 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:self.intervalTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if((indexPath.section == 3 && indexPath.row == 0) ||
            (self.typeSegmentedControl.selectedSegmentIndex == 0 &&
             self.targetTypeSegmentedControl.selectedSegmentIndex == 1 &&
             indexPath.section == 4 && indexPath.row == 0)) {
                GET_EMPTY_CELL;
                
                [cell.contentView addSubview:self.actionButton];
                
                [cell layoutIfNeeded];
                return cell;
            }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Query Type";
    else if(section == 2)
        return @"Read Timeout";
    
    if(self.typeSegmentedControl.selectedSegmentIndex == 1 ||
       self.typeSegmentedControl.selectedSegmentIndex == 2) {
        if(section == 1)
            return @"Hostname";
        else if(section == 3)
            return @"Action";
    }
    else if(self.typeSegmentedControl.selectedSegmentIndex == 0) {
        if(section == 1)
            return @"Target";
        if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
            if(section == 3)
                return @"Action";
        }
        else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
            if(section == 3)
                return @"Inject Interval";
            else if(section == 4)
                return @"Action";
        }
    }
    
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 2)
        return 44.0f;
    else if(indexPath.section == 3) {
        if(self.typeSegmentedControl.selectedSegmentIndex == 0 &&
           self.targetTypeSegmentedControl.selectedSegmentIndex == 1)
            return 44.0f;
        else
            return 55.0f;
    }
    else if(indexPath.section == 4)
        return 55.0f;
    return 0.0f;
}

@end
