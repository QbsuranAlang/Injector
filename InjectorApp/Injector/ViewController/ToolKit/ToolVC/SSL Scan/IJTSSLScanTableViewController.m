//
//  IJTSSLScanTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/12/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTSSLScanTableViewController.h"
#import "IJTSSLScanResultTableViewController.h"
@interface IJTSSLScanTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUITextField *portTextField;
@property (nonatomic, strong) FUITextField *timeoutTextField;

@property (nonatomic, strong) FUIButton *actionButton;

@end

@implementation IJTSSLScanTableViewController

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
    
    _timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"3000";
    self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoScanVC) forControlEvents:UIControlEventTouchUpInside];
    
    [_targetView addSubview:_targetTextField];
    [_portView addSubview:_portTextField];
    [_timeoutView addSubview:_timeoutTextField];
    [_actionView addSubview:_actionButton];
    
    [self setSwitch:self.clientCiphersSwitch enabled:NO];
    [self setSwitch:self.renegotiationSwitch enabled:YES];
    [self setSwitch:self.compressionSwitch enabled:YES];
    [self setSwitch:self.heartbleedSwitch enabled:YES];
    [self setSwitch:self.serverCiphersSwitch enabled:YES];
    [self setSwitch:self.showCertificateSwitch enabled:NO];
    [self setSwitch:self.showTrustedCAsSwitch enabled:NO];
    
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

- (void)gotoScanVC {
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
    
    if(self.timeoutTextField.text.length <= 0) {
        [self showErrorMessage:@"Timeout is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:self.timeoutTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid timeout value.", self.timeoutTextField.text]];
        return;
    }
    
    IJTSSLScanResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SSLScanResultVC"];
    vc.target = self.targetTextField.text;
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.family = self.typeSegmentedControl.selectedSegmentIndex == 0 ? AF_INET : AF_INET6;
    vc.multiToolButton = self.multiToolButton;
    vc.port = [self.portTextField.text intValue];
    vc.clientCipher = self.clientCiphersSwitch.isOn;
    vc.renegotiation = self.renegotiationSwitch.isOn;
    vc.compression = self.compressionSwitch.isOn;
    vc.heartbleed = self.heartbleedSwitch.isOn;
    vc.serverCipher = self.serverCiphersSwitch.isOn;
    vc.showCertificate = self.showCertificateSwitch.isOn;
    vc.showTrustedCAs = self.showTrustedCAsSwitch.isOn;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)setSwitch: (FUISwitch *)switchView enabled: (BOOL)enabled {
    switchView.offLabel.text = @"NO";
    switchView.onLabel.text = @"YES";
    switchView.onLabel.font = [UIFont boldFlatFontOfSize:14];
    switchView.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [switchView setOn:enabled];
}

#pragma text view delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.portTextField.isFirstResponder) {
        [self.portTextField resignFirstResponder];
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
    else if(textField == self.timeoutTextField || textField == self.portTextField) {
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
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 3;
    else if(section == 1)
        return 7;
    else if(section == 2 || section == 3)
        return 1;
    return 0;
}



@end
