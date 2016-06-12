//
//  IJTArpingTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArpingTableViewController.h"
#import "IJTArpingResultTableViewController.h"

@interface IJTArpingTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUITextField *amountTextField;
@property (nonatomic, strong) FUITextField *timeoutTextField;
@property (nonatomic, strong) FUITextField *intervalTextField;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) Reachability *wifiReachability;

@end

@implementation IJTArpingTableViewController

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
    self.targetTextField.placeholder = @"Target IP address";
    
    self.amountTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.amountTextField.placeholder = @"Send frame amount(0 equal infinity)";
    self.amountTextField.text = @"0";
    
    self.timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"1000";
    
    self.intervalTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.intervalTextField.placeholder = @"Send frame interval(µs)";
    self.intervalTextField.returnKeyType = UIReturnKeyDone;
    self.intervalTextField.text = @"1000000";
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoArpingVC) forControlEvents:UIControlEventTouchUpInside];
    
    [self.targetView addSubview:self.targetTextField];
    [self.amountView addSubview:self.amountTextField];
    [self.timeoutView addSubview:self.timeoutTextField];
    [self.intervalView addSubview:self.intervalTextField];
    [self.actionView addSubview:self.actionButton];
    
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

- (void)gotoArpingVC {
    
    [self dismissKeyboard];
    
    if(self.targetTextField.text.length <= 0) {
        [self showErrorMessage:@"Target IP address is empty."];
        return;
    }
    else if(![IJTValueChecker checkIpv4Address:self.targetTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.targetTextField.text]];
        return;
    }
    if(self.amountTextField.text.length <= 0) {
        [self showErrorMessage:@"Amount is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:self.amountTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid amount value.", self.amountTextField.text]];
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
    
    IJTArpingResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ArpingResultVC"];
    vc.targetIpAddress = self.targetTextField.text;
    vc.amount = [self.amountTextField.text integerValue];
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.interval = (useconds_t)[self.intervalTextField.text longLongValue];
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"arping"];
        [self.actionButton setEnabled:NO];
        [self.actionButton setTitle:@"No Wi-Fi Connection" forState:UIControlStateNormal];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.actionButton setEnabled:YES];
        [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    }
}

#pragma mark text field delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.amountTextField.isFirstResponder) {
        [self.amountTextField resignFirstResponder];
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
        [self.amountTextField becomeFirstResponder];
    }
    else if(textField == self.amountTextField) {
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
    
    if(textField == self.timeoutTextField || textField == self.amountTextField || textField == self.intervalTextField) {
        allowString = @"1234567890\b";
    }
    else if(textField == self.targetTextField) {
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
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

@end
