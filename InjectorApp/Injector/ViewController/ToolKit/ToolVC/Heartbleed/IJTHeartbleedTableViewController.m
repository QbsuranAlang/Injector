//
//  IJTHeartbleedTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/12/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTHeartbleedTableViewController.h"
#import "IJTHeartbleedResultTableViewController.h"
@interface IJTHeartbleedTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUITextField *portTextField;
@property (nonatomic, strong) FUITextField *timeoutTextField;
@property (nonatomic, strong) FUITextField *displayTextField;

@property (nonatomic, strong) FUIButton *actionButton;

@end

@implementation IJTHeartbleedTableViewController

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
    
    _targetTextField = [IJTTextField baseTextFieldWithTarget:self];
    _targetTextField.placeholder = @"Hostname or IP address";
    
    _portTextField = [IJTTextField baseTextFieldWithTarget:self];
    _portTextField.placeholder = @"Port(Maximum: 65535)";
    _portTextField.text = @"443";
    
    _displayTextField = [IJTTextField baseTextFieldWithTarget:self];
    _displayTextField.placeholder = @"Bytes you want to display";
    _displayTextField.text = @"1000";
    
    _timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"3000";
    self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoExploitVC) forControlEvents:UIControlEventTouchUpInside];
    
    [_targetView addSubview:_targetTextField];
    [_portView addSubview:_portTextField];
    [_timeoutView addSubview:_timeoutTextField];
    [_displayView addSubview:_displayTextField];
    [_actionView addSubview:_actionButton];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
     
    if(self.fromLAN) {
        [self.typeSegmentedControl setEnabled:NO];
        [self.typeSegmentedControl setSelectedSegmentIndex:0];
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

- (void)gotoExploitVC {
    [self dismissKeyboard];
    
    if(self.targetTextField.text.length <= 0) {
        [self showErrorMessage:@"Target is empty."];
        return;
    }
    
    if(self.portTextField.text.length <= 0) {
        [self showErrorMessage:@"Start port is empty."];
        return;
    }
    else if(![IJTValueChecker checkUint16:self.portTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid port number.", self.portTextField.text]];
        return;
    }
    
    if(self.displayTextField.text.length <= 0) {
        [self showErrorMessage:@"Display length is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:self.displayTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid bytes value.", self.displayTextField.text]];
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
    
    IJTHeartbleedResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"HeartbleedResultVC"];
    vc.target = self.targetTextField.text;
    vc.port = [self.portTextField.text intValue];
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.multiToolButton = self.multiToolButton;
    vc.displayLength = [self.displayTextField.text intValue];
    vc.family = self.typeSegmentedControl.selectedSegmentIndex == 0 ? AF_INET : AF_INET6;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma text view delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.portTextField.isFirstResponder) {
        [self.portTextField resignFirstResponder];
    }
    else if(self.displayTextField.isFirstResponder) {
        [self.displayTextField resignFirstResponder];
    }
    else if(self.timeoutTextField.isFirstResponder) {
        [self.timeoutTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.targetTextField) {
        [self.portTextField becomeFirstResponder];
    }
    else if(textField == self.portTextField) {
        [self.displayTextField becomeFirstResponder];
    }
    else if(textField == self.displayTextField) {
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
        return YES;
    }
    else if(textField == self.timeoutTextField || textField == self.displayTextField) {
        allowString = @"1234567890\b";
    }
    else if(textField == self.portTextField) {
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
    if(section == 0)
        return 3;
    else if(section == 1)
        return 1;
    else if(section == 2)
        return 1;
    else if(section == 3)
        return 1;
    return 0;
}



@end
