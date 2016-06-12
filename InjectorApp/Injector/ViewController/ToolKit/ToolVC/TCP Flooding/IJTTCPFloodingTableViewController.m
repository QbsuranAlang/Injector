//
//  IJTTCPFloodingTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/8.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTTCPFloodingTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTTCPFloodingResultTableViewController.h"

@interface IJTTCPFloodingTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUITextField *targetPortTextField;
@property (nonatomic, strong) FUITextField *sourceIpAddressTextField;
@property (nonatomic, strong) FUITextField *sourcePortTextField;
@property (nonatomic, strong) FUISwitch *sourceIpRandSwitch;
@property (nonatomic, strong) FUISwitch *sourcePortRandSwitch;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) FUITextField *amountTextField;
@property (nonatomic, strong) FUITextField *intervalTextField;

@end

@implementation IJTTCPFloodingTableViewController

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
    self.targetTextField.placeholder = @"Target IP address or hostname";
    
    self.targetPortTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.targetPortTextField.placeholder = @"Port(Maximum: 65535)";
    
    self.sourceIpAddressTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.sourceIpAddressTextField.placeholder = @"Source IP address";
    
    self.sourcePortTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.sourcePortTextField.placeholder = @"Port(Maximum: 65535)";
    
    self.sourceIpRandSwitch = [[FUISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.sourceIpRandSwitch.offLabel.text = @"NO";
    self.sourceIpRandSwitch.onLabel.text = @"YES";
    self.sourceIpRandSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.sourceIpRandSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.sourceIpRandSwitch setOn:YES];
    [self.sourceIpRandSwitch addTarget:self action:@selector(randSwitchChange:) forControlEvents:UIControlEventValueChanged];
    
    self.sourcePortRandSwitch = [[FUISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.sourcePortRandSwitch.offLabel.text = @"NO";
    self.sourcePortRandSwitch.onLabel.text = @"YES";
    self.sourcePortRandSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.sourcePortRandSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.sourcePortRandSwitch setOn:YES];
    [self.sourcePortRandSwitch addTarget:self action:@selector(randSwitchChange:) forControlEvents:UIControlEventValueChanged];
    
    self.amountTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.amountTextField.placeholder = @"Send frame amount(0 equal infinity)";
    self.amountTextField.text = @"0";
    
    self.intervalTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.intervalTextField.placeholder = @"Send frame interval(µs)";
    self.intervalTextField.returnKeyType = UIReturnKeyDone;
    self.intervalTextField.text = @"200000";
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoTCPFloodingVC) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    if(self.fromLAN) {
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

- (void)gotoTCPFloodingVC {
    [self dismissKeyboard];
    
    if(self.targetTextField.text.length <= 0) {
        [self showErrorMessage:@"Target IP address is empty."];
        return;
    }
    
    if(self.targetPortTextField.text.length <= 0) {
        [self showErrorMessage:@"Target port port is empty."];
        return;
    }
    else if(![IJTValueChecker checkUint16:self.targetPortTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.targetPortTextField.text]];
        return;
    }
    else if([self.targetPortTextField.text integerValue] == 0) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.targetPortTextField.text]];
        return;
    }
    
    if(!self.sourceIpRandSwitch.isOn) {
        if(self.sourceIpAddressTextField.text.length <= 0) {
            [self showErrorMessage:@"Source IP address is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:self.sourceIpAddressTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.sourceIpAddressTextField.text]];
            return;
        }
    }
    
    if(!self.sourcePortRandSwitch.isOn) {
        if(self.sourcePortTextField.text.length <= 0) {
            [self showErrorMessage:@"Source port port is empty."];
            return;
        }
        else if(![IJTValueChecker checkUint16:self.sourcePortTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.sourcePortTextField.text]];
            return;
        }
        else if([self.sourcePortTextField.text integerValue] == 0) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.sourcePortTextField.text]];
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
    
    IJTTCPFloodingResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SYNFloodResultVC"];
    vc.multiToolButton = self.multiToolButton;
    vc.targetIpAddress = self.targetTextField.text;
    vc.targetPort = [self.targetPortTextField.text integerValue];
    vc.sourceIpAddress = self.sourceIpRandSwitch.isOn ? nil : self.sourceIpAddressTextField.text;
    vc.sourcePort = self.sourcePortRandSwitch.isOn ? 0 : [self.sourcePortTextField.text integerValue];
    vc.amount = [self.amountTextField.text integerValue];
    vc.interval = (useconds_t)[self.intervalTextField.text longLongValue];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark switch
- (void)randSwitchChange: (id)sender {
    [self.tableView reloadData];
}

#pragma mark text field delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.targetPortTextField.isFirstResponder) {
        [self.targetPortTextField resignFirstResponder];
    }
    else if(self.sourceIpAddressTextField.isFirstResponder) {
        [self.sourceIpAddressTextField resignFirstResponder];
    }
    else if(self.sourcePortTextField.isFirstResponder) {
        [self.sourcePortTextField resignFirstResponder];
    }
    else if(self.amountTextField.isFirstResponder) {
        [self.amountTextField resignFirstResponder];
    }
    else if(self.intervalTextField.isFirstResponder) {
        [self.intervalTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if(textField == self.targetTextField) {
        [self.targetPortTextField becomeFirstResponder];
    }
    else if(textField == self.targetPortTextField) {
        if(!self.sourceIpRandSwitch.isOn) {
            [self.sourceIpAddressTextField becomeFirstResponder];
        }
        else if(!self.sourcePortRandSwitch.isOn) {
            [self.sourcePortTextField becomeFirstResponder];
        }
        else {
            [self.amountTextField becomeFirstResponder];
        }
    }
    else if(textField == self.sourceIpAddressTextField) {
        if(!self.sourcePortRandSwitch.isOn) {
            [self.sourcePortTextField becomeFirstResponder];
        }
        else {
            [self.amountTextField becomeFirstResponder];
        }
    }
    else if(textField == self.sourcePortTextField) {
        [self.amountTextField becomeFirstResponder];
    }
    else if(textField == self.amountTextField) {
        [self.intervalTextField becomeFirstResponder];
    }
    else if(textField == self.intervalTextField) {
        [self.intervalTextField resignFirstResponder];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.sourceIpAddressTextField) {
        allowString = @"1234567890.\b";
    }
    else if(textField == self.targetPortTextField ||
            textField == self.sourcePortTextField ||
            textField == self.amountTextField ||
            textField == self.intervalTextField) {
        allowString = @"1234567890\b";
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
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 2;
    else if(section == 1) {
        if(self.sourceIpRandSwitch.isOn)
            return 1;
        else
            return 2;
    }
    else if(section == 2) {
        if(self.sourcePortRandSwitch.isOn)
            return 1;
        else
            return 2;
    }
    else if(section == 3 || section == 4 || section == 5)
        return 1;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        GET_EMPTY_CELL;
        if(indexPath.row == 0) {
            [cell.contentView addSubview:_targetTextField];
        }
        else if(indexPath.row == 1) {
            [cell.contentView addSubview:_targetPortTextField];
        }
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        if(indexPath.row == 0) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Randomization"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            
            [cell.controlView addSubview:_sourceIpRandSwitch];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.sourceIpRandSwitch.frame = CGRectMake(width - 80, 0, 80, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:_sourceIpAddressTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if(indexPath.section == 2) {
        if(indexPath.row == 0) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Randomization"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            
            [cell.controlView addSubview:_sourcePortRandSwitch];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.sourcePortRandSwitch.frame = CGRectMake(width - 80, 0, 80, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:_sourcePortTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if(indexPath.section == 3) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:_amountTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 4) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:_intervalTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 5) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:self.actionButton];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Target";
    else if(section == 1)
        return @"Source Ip Address";
    else if(section == 2)
        return @"Source Port";
    else if(section == 3)
        return @"Amount";
    else if(section == 4)
        return @"Inject Interval";
    else if(section == 5)
        return @"Action";
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 5)
        return 55.0f;
    else
        return 44.0f;
}
@end
