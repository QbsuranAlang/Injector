//
//  IJTNULLScanTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/14.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTNULLScanTableViewController.h"
#import "IJTNULLScanResultTableViewController.h"
@interface IJTNULLScanTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUITextField *startPortTextField;
@property (nonatomic, strong) FUITextField *endPortTextField;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) FUITextField *timeoutTextField;
@property (nonatomic, strong) FUITextField *intervalTextField;

@end

@implementation IJTNULLScanTableViewController

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
    
    self.startPortTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.startPortTextField.placeholder = @"Start port(Maximum: 65535)";
    self.startPortTextField.text = @"1";
    
    self.endPortTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.endPortTextField.placeholder = @"End port(Maximum: 65535)";
    self.endPortTextField.text = @"1023";
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoNULLScanVC) forControlEvents:UIControlEventTouchUpInside];
    
    self.randSwitch.offLabel.text = @"NO";
    self.randSwitch.onLabel.text = @"YES";
    self.randSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.randSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.randSwitch setOn:YES];
    
    self.timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"1000";
    
    self.intervalTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.intervalTextField.placeholder = @"Send frame interval(µs)";
    self.intervalTextField.returnKeyType = UIReturnKeyDone;
    self.intervalTextField.text = @"1000";
    
    [self.targetView addSubview:self.targetTextField];
    [self.startPortView addSubview:self.startPortTextField];
    [self.endPortView addSubview:self.endPortTextField];
    [self.timeoutView addSubview:self.timeoutTextField];
    [self.actionView addSubview:self.actionButton];
    [self.intervalView addSubview:self.intervalTextField];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    [self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:17];
    }];
    
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

- (void) gotoNULLScanVC {
    [self dismissKeyboard];
    if(self.targetTextField.text.length <= 0) {
        [self showErrorMessage:@"Target is empty."];
        return;
    }
    
    if(self.startPortTextField.text.length <= 0) {
        [self showErrorMessage:@"Start port is empty."];
        return;
    }
    else if(![IJTValueChecker checkUint16:self.startPortTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.startPortTextField.text]];
        return;
    }
    else if([self.startPortTextField.text integerValue] == 0) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.startPortTextField.text]];
        return;
    }
    
    if(self.endPortTextField.text.length <= 0) {
        [self showErrorMessage:@"End port is empty."];
        return;
    }
    else if(![IJTValueChecker checkUint16:self.endPortTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.endPortTextField.text]];
        return;
    }
    else if([self.endPortTextField.text integerValue] == 0) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.endPortTextField.text]];
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
    
    if(self.intervalTextField.text.length <= 0) {
        [self showErrorMessage:@"Interval is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:self.intervalTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid interval value.", self.intervalTextField.text]];
        return;
    }
    
    IJTNULLScanResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"NULLScanResultVC"];
    vc.target = self.targetTextField.text;
    vc.startPort = [self.startPortTextField.text integerValue];
    vc.endPort = [self.endPortTextField.text integerValue];
    vc.randomization = self.randSwitch.isOn;
    vc.multiToolButton = self.multiToolButton;
    vc.interval = (useconds_t)[self.intervalTextField.text longLongValue];
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark text field delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.startPortTextField.isFirstResponder) {
        [self.startPortTextField resignFirstResponder];
    }
    else if(self.endPortTextField.isFirstResponder) {
        [self.endPortTextField resignFirstResponder];
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
        [self.startPortTextField becomeFirstResponder];
    }
    else if(textField == self.startPortTextField) {
        [self.endPortTextField becomeFirstResponder];
    }
    else if(textField == self.endPortTextField) {
        [self.timeoutTextField becomeFirstResponder];
    }
    else if(textField == self.timeoutTextField) {
        [self.intervalTextField becomeFirstResponder];
    }
    else if(textField == self.intervalTextField) {
        [self.intervalTextField resignFirstResponder];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.startPortTextField || textField == self.endPortTextField ||
       textField == self.timeoutTextField || textField == self.intervalTextField) {
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
    if(section == 1)
        return 2;
    return 1;
}

@end
