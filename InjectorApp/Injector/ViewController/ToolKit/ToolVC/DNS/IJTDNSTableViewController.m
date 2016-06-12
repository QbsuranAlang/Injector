//
//  IJTDNSTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/12.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTDNSTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTDNSResultTableViewController.h"

@interface IJTDNSTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUISegmentedControl *targetTypeSegmentedControl;
@property (nonatomic, strong) FUITextField *serverTextField;
@property (nonatomic, strong) NSMutableArray *dnsServerList;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) FUITextField *timeoutTextField;

@end

@implementation IJTDNSTableViewController

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
    
    self.targetTypeSegmentedControl = [[FUISegmentedControl alloc]
                                       initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 28)];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"A" atIndex:0 animated:NO];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"AAAA" atIndex:1 animated:NO];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"PTR" atIndex:2 animated:NO];
    [self.targetTypeSegmentedControl setSelectedSegmentIndex:0];
    [self.targetTypeSegmentedControl addTarget:self action:@selector(targetTypeChange) forControlEvents:UIControlEventValueChanged];
    [self targetTypeChange];
    
    self.serverTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.serverTextField.placeholder = @"Tap to select a DNS server";
    
    self.timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"1000";
    self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoDNSVC) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    if(self.fromLAN) {
        [self.targetTypeSegmentedControl setSelectedSegmentIndex:2];
        [self.targetTypeSegmentedControl setEnabled:NO];
        self.targetTextField.text = self.ipAddressFromLan;
        [self.targetTextField setEnabled:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoDNSVC {
    
    [self dismissKeyboard];
    if(self.targetTextField.text.length <= 0) {
        [self showErrorMessage:@"Target is empty."];
        return;
    }
    
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 2) {
        if(![IJTValueChecker checkIpv4Address:_targetTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IPv4 address.", _targetTextField.text]];
            return;
        }
    }
    
    if(self.serverTextField.text.length <= 0) {
        [self showErrorMessage:@"DNS server is empty."];
        return;
    }
    else if(![IJTValueChecker checkIpv4Address:_serverTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", _serverTextField.text]];
        return;
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
    
    IJTDNSResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"DNSResultVC"];
    vc.target = self.targetTextField.text;
    vc.serverIpAddress = self.serverTextField.text;
    vc.multiToolButton = self.multiToolButton;
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.targetType = [self.targetTypeSegmentedControl titleForSegmentAtIndex:self.targetTypeSegmentedControl.selectedSegmentIndex];
    vc.selectedIndex = self.targetTypeSegmentedControl.selectedSegmentIndex;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)targetTypeChange {
    self.targetTextField.text = @"";
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        self.targetTextField.placeholder = @"Hostname";
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        self.targetTextField.placeholder = @"Hostname";
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 2) {
        self.targetTextField.placeholder = @"IPv4 address";
    }
    [self.tableView reloadData];
}

#pragma text view delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.serverTextField.isFirstResponder) {
        [self.serverTextField resignFirstResponder];
    }
    else if(self.timeoutTextField.isFirstResponder) {
        [self.timeoutTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.targetTextField) {
        [self.serverTextField becomeFirstResponder];
    }
    else if(textField == self.serverTextField) {
        [self.timeoutTextField becomeFirstResponder];
    }
    else if(textField == self.timeoutTextField) {
        [self.timeoutTextField resignFirstResponder];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.serverTextField) {
        allowString = @"1234567890.\b";
    }
    else if(textField == self.targetTextField) {
        if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
            return YES;
        }
        else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
            return YES;
        }
        else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 2) {
            allowString = @"1234567890.\b";
        }
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

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if(textField == self.serverTextField) {
        self.serverTextField.placeholder = @"Tap to select a server";
        [self.tableView reloadData];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    if(textField == self.serverTextField) {
        if([self.serverTextField.text isEqualToString:@"Other"]) {
            self.serverTextField.text = @"";
            self.serverTextField.placeholder = @"Server IP address";
            return YES;
        }
        
        [self dismissKeyboard];
        
        self.dnsServerList = [[NSMutableArray alloc] init];
        int ret =
        [IJTDNS getDNSListRegisterTarget:self selector:DNS_LIST_CALLBACK_SEL object:_dnsServerList];
        if(ret != 0) {
            [self showErrorMessage:@"Couldn\'t get local DNS server list."];
            self.serverTextField.text = @"";
            self.serverTextField.placeholder = @"Server IP address";
            return YES;
        }
        
        [self.dnsServerList addObject:@"Other"];
        
        CZPickerView *picker = [IJTPickerView pickerViewTitle:@"Local DNS Server List" target:self];
        [picker show];
        return NO;
    }
    return YES;
}

DNS_LIST_CALLBACK_METHOD {
    NSMutableArray *list = (NSMutableArray *)object;
    [list addObject:ipAddress];
}

#pragma mark picker view

- (NSAttributedString *)czpickerView:(CZPickerView *)pickerView attributedTitleForRow:(NSInteger)row{
    
    NSMutableParagraphStyle *mutParaStyle = [[NSMutableParagraphStyle alloc] init];
    [mutParaStyle setAlignment:NSTextAlignmentCenter];
    
    NSMutableDictionary *attrsDictionary = [[NSMutableDictionary alloc] init];
    [attrsDictionary setObject:[UIFont systemFontOfSize:17] forKey:NSFontAttributeName];
    [attrsDictionary setObject:mutParaStyle forKey:NSParagraphStyleAttributeName];
    
    return [[NSMutableAttributedString alloc]
            initWithString:self.dnsServerList[row] attributes:attrsDictionary];
}

- (NSInteger)numberOfRowsInPickerView:(CZPickerView *)pickerView{
    return self.dnsServerList.count;
}

- (void)czpickerView:(CZPickerView *)pickerView didConfirmWithItemAtRow:(NSInteger)row {
    self.serverTextField.text = self.dnsServerList[row];
    if(row == self.dnsServerList.count - 1) {
        [self.serverTextField becomeFirstResponder];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 2;
    else if(section == 1)
        return 1;
    else if(section == 2)
        return 1;
    else if(section == 3)
        return 1;
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
            [cell.contentView addSubview:_targetTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }//end if section 0
    else if(indexPath.section == 1) {
        if(indexPath.row == 0) {
            GET_EMPTY_CELL;
            [cell.contentView addSubview:_serverTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if(indexPath.section == 2) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:_timeoutTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 3) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:_actionButton];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 2)
        return 44.0f;
    else if(indexPath.section == 3)
        return 55.0f;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Query Target";
    else if(section == 1)
        return @"DNS Server";
    else if(section == 2)
        return @"Read Timeout";
    else if(section == 3)
        return @"Action";
    return @"";
}

@end
