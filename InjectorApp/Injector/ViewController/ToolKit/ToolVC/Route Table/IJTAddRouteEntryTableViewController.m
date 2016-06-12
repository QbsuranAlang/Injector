//
//  IJTAddRouteEntryTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTAddRouteEntryTableViewController.h"
#import "IJTArgTableViewCell.h"

@interface IJTAddRouteEntryTableViewController ()

@property (nonatomic, strong) FUISegmentedControl *dstTypeSegmentedControl;
@property (nonatomic, strong) FUITextField *networkTextField;
@property (nonatomic, strong) FUITextField *netmaskTextField;
@property (nonatomic, strong) FUITextField *hostTextField;
@property (nonatomic, strong) FUITextField *gatewayTextField;
@property (nonatomic, strong) FUISwitch *dynamicSwitch;
@property (nonatomic, strong) FUIButton *addButton;

@end

@implementation IJTAddRouteEntryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.navigationItem.title = @"New Route Entry";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.dstTypeSegmentedControl = [[FUISegmentedControl alloc]
                                    initWithFrame:CGRectMake(0, 0, 200, 28)];
    [self.dstTypeSegmentedControl insertSegmentWithTitle:@"Network" atIndex:0 animated:NO];
    [self.dstTypeSegmentedControl insertSegmentWithTitle:@"Host" atIndex:1 animated:NO];
    [self.dstTypeSegmentedControl setSelectedSegmentIndex:0];
    [self.dstTypeSegmentedControl addTarget:self action:@selector(typeChange) forControlEvents:UIControlEventValueChanged];
    
    self.networkTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.networkTextField.placeholder = @"Network";
    
    self.netmaskTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.netmaskTextField.placeholder = @"Netmask";
    
    self.hostTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.hostTextField.placeholder = @"Host";
    
    self.gatewayTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.gatewayTextField.placeholder = @"Gateway";
    self.gatewayTextField.returnKeyType = UIReturnKeyDone;
    
    self.dynamicSwitch = [[FUISwitch alloc]
                          initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.dynamicSwitch.onLabel.text = @"YES";
    self.dynamicSwitch.offLabel.text = @"NO";
    self.dynamicSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.dynamicSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    
    self.addButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.addButton setTitle:@"New one" forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(addRoute) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self dismissKeyboard];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)typeChange {
    self.netmaskTextField.text = @"";
    self.networkTextField.text = @"";
    self.hostTextField.text = @"";
    [self dismissKeyboard];
    [self.tableView reloadData];
}

- (void)addRoute {
    
    [self dismissKeyboard];
    
    if(self.dstTypeSegmentedControl.selectedSegmentIndex == 0) {
        if(_networkTextField.text.length <= 0) {
            [self showErrorMessage:@"Network address is empty."];
            return;
        }
        else {
            if(![IJTValueChecker checkIpv4Address:_networkTextField.text]) {
                [self showErrorMessage:
                 [NSString stringWithFormat:@"\"%@\" is not a valid network address.",  _networkTextField.text]];
                return;
            }
        }
        if(_netmaskTextField.text.length <= 0) {
            [self showErrorMessage:@"Netmask address is empty."];
            return;
        }
        else {
            if(![IJTValueChecker checkNetmask:_netmaskTextField.text]) {
                [self showErrorMessage:
                 [NSString stringWithFormat:@"\"%@\" is not a valid netmask address.",  _networkTextField.text]];
                return;
            }
        }
    }
    else if(self.dstTypeSegmentedControl.selectedSegmentIndex == 1) {
        if(_hostTextField.text.length <= 0) {
            [self showErrorMessage:@"Host IP address is empty."];
            return;
        }
        else {
            if(![IJTValueChecker checkIpv4Address:_hostTextField.text]) {
                [self showErrorMessage:
                 [NSString stringWithFormat:@"\"%@\" is not a valid Host IP address.",  _hostTextField.text]];
                return;
            }
        }
    }
    else {
        return;
    }
    
    if(_gatewayTextField.text.length <= 0) {
        [self showErrorMessage:@"Gateway address is empty."];
        return;
    }
    else {
        if(![IJTValueChecker checkIpv4Address:_gatewayTextField.text]) {
            [self showErrorMessage:
             [NSString stringWithFormat:@"\"%@\" is not a valid gateway address.",  _gatewayTextField.text]];
            return;
        }
    }
    
    IJTRoutetable *route = [[IJTRoutetable alloc] init];
    if(route.errorHappened) {
        if(route.errorCode == 0) {
            [self showErrorMessage:[NSString stringWithFormat:@"%@.", route.errorMessage]];
        }
        else {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(route.errorCode)]];
        }
        return;
    }
    
    if(self.dstTypeSegmentedControl.selectedSegmentIndex == 0) {
        [route addRouteNetwork:_networkTextField.text
                       netmask:_netmaskTextField.text
                       gateway:_gatewayTextField.text
                       dynamic:_dynamicSwitch.isOn];
    }
    else if(self.dstTypeSegmentedControl.selectedSegmentIndex == 1) {
        [route addRouteHost:_hostTextField.text
                    gateway:_gatewayTextField.text
                    dynamic:_dynamicSwitch.isOn];
    }
    
    if(route.errorHappened) {
        if(route.errorCode == 0) {
            [self showErrorMessage:[NSString stringWithFormat:@"%@.", route.errorMessage]];
        }
        else if(route.errorCode == EEXIST) {
            if(self.dstTypeSegmentedControl.selectedSegmentIndex == 0) {
                [self showErrorMessage:[NSString stringWithFormat:@"%@(%@) => %@ exsit.",
                                                  _networkTextField.text, _netmaskTextField.text, _gatewayTextField.text]];
                return;
            }
            else if(self.dstTypeSegmentedControl.selectedSegmentIndex == 1) {
                [self showErrorMessage:[NSString stringWithFormat:@"%@ => %@ exsit.",
                                                  _hostTextField.text, _gatewayTextField.text]];
                return;
            }
        }
        else {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(route.errorCode)]];
        }
    }
    else {
        [self showSuccessMessage:@"Success"];
        //[self.delegate callback];
    }
    [route close];
}

#pragma mark text field

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.networkTextField) {
        [self.netmaskTextField becomeFirstResponder];
    }
    else if(textField == self.netmaskTextField || textField == self.hostTextField) {
        [self.gatewayTextField becomeFirstResponder];
    }
    else if(textField == self.gatewayTextField) {
        [self.gatewayTextField resignFirstResponder];
    }
    return NO;
}

- (void)dismissKeyboard {
    if(self.netmaskTextField.isFirstResponder) {
        [self.netmaskTextField resignFirstResponder];
    }
    else if(self.networkTextField.isFirstResponder) {
        [self.networkTextField resignFirstResponder];
    }
    else if(self.hostTextField.isFirstResponder) {
        [self.hostTextField resignFirstResponder];
    }
    else if(self.gatewayTextField.isFirstResponder) {
        [self.gatewayTextField resignFirstResponder];
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.networkTextField || textField == self.netmaskTextField ||
       textField == self.hostTextField || textField == self.gatewayTextField) {
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0) {
        if(self.dstTypeSegmentedControl.selectedSegmentIndex == 0)
            return 5;
        else if(self.dstTypeSegmentedControl.selectedSegmentIndex == 1)
            return 4;
    }
    else if(section == 1) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0) {
        if(indexPath.row == 0) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Destination"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            
            [cell.controlView addSubview:self.dstTypeSegmentedControl];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.dstTypeSegmentedControl.frame = CGRectMake(width - 180, 0, 180, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(self.dstTypeSegmentedControl.selectedSegmentIndex == 0 &&
                (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3)) {
            GET_EMPTY_CELL;;
            
            if(indexPath.row == 1) {
                [cell.contentView addSubview:self.networkTextField];
            }
            else if(indexPath.row == 2) {
                [cell.contentView addSubview:self.netmaskTextField];
            }
            else if(indexPath.row == 3) {
                [cell.contentView addSubview:self.gatewayTextField];
            }
            
            [cell layoutIfNeeded];
            
            return cell;
        }
        else if(self.dstTypeSegmentedControl.selectedSegmentIndex == 1 && (indexPath.row == 1 || indexPath.row == 2)) {
            GET_EMPTY_CELL;
            
            if(indexPath.row == 1) {
                [cell.contentView addSubview:self.hostTextField];
            }
            else if(indexPath.row == 2) {
                [cell.contentView addSubview:self.gatewayTextField];
            }
            
            [cell layoutIfNeeded];
            
            return cell;
        }
        
        else if((self.dstTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.row == 4) ||
                (self.dstTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.row == 3)) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Dynamic"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];

            [cell.controlView addSubview:self.dynamicSwitch];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.dynamicSwitch.frame = CGRectMake(width - 80, 0, 80, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if(indexPath.section == 1) {
        GET_EMPTY_CELL;
        
        CGFloat height = CGRectGetHeight(cell.frame);
        self.addButton.frame = CGRectMake(16, 8, SCREEN_WIDTH - 32, height - 16);
        [cell.contentView addSubview:self.addButton];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        return 44.f;
    }
    else if(indexPath.section == 1) {
        return 55.0f;
    }
    
    return .0f;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Parameters";
    }
    else if(section == 1) {
        return @"Action";
    }
    
    return @"";
}

@end
