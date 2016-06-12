//
//  IJTAddArpCacheTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/14.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTAddArpCacheTableViewController.h"

@interface IJTAddArpCacheTableViewController ()

@property (nonatomic, strong) FUITextField *ipAddressTextField;
@property (nonatomic, strong) FUITextField *macAddressTextField;

@end

@implementation IJTAddArpCacheTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"New ARP Entry";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.ipAddressTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.macAddressTextField = [IJTTextField baseTextFieldWithTarget:self];
    
    self.ipAddressTextField.placeholder = @"IP address";
    
    self.macAddressTextField.placeholder = @"MAC address";
    self.macAddressTextField.returnKeyType = UIReturnKeyDone;
    
    [self.ipAddressView addSubview:self.ipAddressTextField];
    [self.macAddressView addSubview:self.macAddressTextField];
    
    self.staticSwitch.onLabel.text = @"YES";
    self.publishedSwitch.onLabel.text = @"YES";
    self.onlySwitch.onLabel.text = @"YES";
    self.staticSwitch.offLabel.text = @"NO";
    self.publishedSwitch.offLabel.text = @"NO";
    self.onlySwitch.offLabel.text = @"NO";
    self.staticSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.staticSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    self.onlySwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.onlySwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    self.publishedSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.publishedSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    
    [self.staticSwitch setOn:YES];
    [self.publishedSwitch setOn:NO];
    [self.onlySwitch setOn:NO];
    
    [self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:17];
    }];
    
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

#pragma mark text field

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(self.ipAddressTextField.isFirstResponder) {
        [self.macAddressTextField becomeFirstResponder];
    }
    else if(self.macAddressTextField.isFirstResponder) {
        [self.macAddressTextField resignFirstResponder];
    }
    return NO;
}

- (void)dismissKeyboard {
    if(self.ipAddressTextField.isFirstResponder) {
        [self.ipAddressTextField resignFirstResponder];
    }
    else if(self.macAddressTextField.isFirstResponder) {
        [self.macAddressTextField resignFirstResponder];
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.ipAddressTextField) {
        allowString = @"1234567890.\b";
    }
    else if(textField == self.macAddressTextField) {
        allowString = @"1234567890:abcdefABCDEF\b";
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
    if(section == 0)
        return 5;
    else if(section == 1)
        return 1;
    return 0;
}

- (IBAction)addArpCache:(id)sender {
    
    [self dismissKeyboard];
    NSString *ipAddress = self.ipAddressTextField.text;
    NSString *macAddress = self.macAddressTextField.text;
    
    if(ipAddress.length <= 0) {
        [self showErrorMessage:@"IP address is empty."];
        return;
    }
    if(![IJTValueChecker checkIpv4Address:ipAddress]) {
        [self showErrorMessage:
         [NSString stringWithFormat:@"\"%@\" is not a valid IP address.", ipAddress]];
        return;
    }
    
    if(macAddress.length <= 0) {
        [self showErrorMessage:@"MAC address is empty."];
        return;
    }
    if(![IJTValueChecker checkMacAddress:macAddress]) {
        [self showErrorMessage:
         [NSString stringWithFormat:@"\"%@\" is not a valid MAC address.", macAddress]];
        return;
    }
    
    IJTArptable *arptable = [[IJTArptable alloc] init];
    if(arptable.errorHappened) {
        if(arptable.errorCode == 0)
            [self showErrorMessage:arptable.errorMessage];
        else
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(arptable.errorCode)]];
        return;
    }
    
    [arptable addIpAddress:ipAddress
                macAddress:macAddress
                  isstatic:_staticSwitch.isOn
               ispublished:_publishedSwitch.isOn
                    isonly:_onlySwitch.isOn];
    
    if(arptable.errorHappened) {
        if(arptable.errorCode == 0)
            [self showErrorMessage:arptable.errorMessage];
        else if(arptable.errorCode == EEXIST)
            [self showErrorMessage:[NSString stringWithFormat:@"%@(%@) exsit.", ipAddress, macAddress]];
        else
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(arptable.errorCode)]];
        [arptable close];
        return;
    }
    
    //[self.delegate callback];
    [self showSuccessMessage:@"Success"];
}
@end
