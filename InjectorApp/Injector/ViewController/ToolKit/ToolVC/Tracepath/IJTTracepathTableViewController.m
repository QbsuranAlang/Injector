//
//  IJTTracepathTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/22.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTTracepathTableViewController.h"
#import "IJTTracepathResultTableViewController.h"
@interface IJTTracepathTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUITextField *sourceTextField;
@property (nonatomic, strong) FUITextField *startTTLTextField;
@property (nonatomic, strong) FUITextField *endTTLTextField;
@property (nonatomic, strong) FUITextField *timeoutTextField;
@property (nonatomic, strong) FUITextField *payloadSizeTextField;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) Reachability *cellReachability;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) FUITextField *startPortTextField;
@property (nonatomic, strong) FUITextField *endPortTextField;

@end

@implementation IJTTracepathTableViewController

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
    
    self.sourceTextField = [IJTTextField baseTextFieldWithTarget:self];
    [self.sourceTextField setEnabled:NO];
    
    [self.sourceSegmentedControl removeAllSegments];
    int index = 0;
    if([IJTNetowrkStatus supportWifi]) {
        [self.sourceSegmentedControl insertSegmentWithTitle:@"Wi-Fi" atIndex:index++ animated:NO];
    }
    if([IJTNetowrkStatus supportCellular]) {
        [self.sourceSegmentedControl insertSegmentWithTitle:@"Cellular" atIndex:index++ animated:NO];
    }
    if(self.sourceSegmentedControl.numberOfSegments > 0)
        [self.sourceSegmentedControl setSelectedSegmentIndex:0];
    
    [self.sourceSegmentedControl addTarget:self
                                    action:@selector(sourceTypeChange)
                          forControlEvents:UIControlEventTouchUpInside];
    [self sourceTypeChange];
    
    self.startTTLTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.startTTLTextField.placeholder = @"Start time to live(Maximum: 255)";
    self.startTTLTextField.text = @"1";
    
    self.endTTLTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.endTTLTextField.placeholder = @"End time to live(Maximum: 255)";
    int ttl = [IJTSysctl sysctlValueByname:@"net.inet.ip.ttl"];
    if(ttl == -1)
        self.endTTLTextField.text = @"255";
    else
        self.endTTLTextField.text = [NSString stringWithFormat:@"%d", ttl];
    
    self.timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"1000";
    self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    
    self.payloadSizeTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.payloadSizeTextField.placeholder = [NSString stringWithFormat:@"Payload size(Maximum: %d bytes)", TRACEPATH_MAXSIZE];
    self.payloadSizeTextField.text = @"0";
    
    self.resolveHostnameSwitch.onLabel.text = @"YES";
    self.resolveHostnameSwitch.offLabel.text = @"NO";
    self.resolveHostnameSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.resolveHostnameSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.resolveHostnameSwitch setOn:NO];
    
    self.startPortTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.startPortTextField.placeholder = [NSString stringWithFormat:@"Start port(%d - %d)", TRACEPATH_MIN_PORT, TRACEPATH_MAX_PORT];
    self.startPortTextField.text = [NSString stringWithFormat:@"%d", TRACEPATH_MIN_PORT];
    
    self.endPortTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.endPortTextField.placeholder = [NSString stringWithFormat:@"End port(%d - %d)", TRACEPATH_MIN_PORT, TRACEPATH_MAX_PORT];
    self.endPortTextField.text = [NSString stringWithFormat:@"%d", TRACEPATH_MAX_PORT];
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoTracepathVC) forControlEvents:UIControlEventTouchUpInside];
    
    [self.targetView addSubview:self.targetTextField];
    [self.timeoutView addSubview:self.timeoutTextField];
    [self.actionView addSubview:self.actionButton];
    [self.payloadSizeView addSubview:self.payloadSizeTextField];
    [self.sourceView addSubview:self.sourceTextField];
    [self.startTTLView addSubview:self.startTTLTextField];
    [self.endTTLView addSubview:self.endTTLTextField];
    [self.startPortView addSubview:self.startPortTextField];
    [self.endPortView addSubview:self.endPortTextField];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    [self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:17];
    }];
    
    CGFloat width = (SCREEN_WIDTH - (self.buttons.count - 1))/self.buttons.count;
    
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        NSLayoutConstraint *constraint =
        [NSLayoutConstraint constraintWithItem:button
                                     attribute:NSLayoutAttributeWidth
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:nil
                                     attribute:NSLayoutAttributeNotAnAttribute
                                    multiplier:1 constant:width];
        [button addConstraint:constraint];
        
        [button setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [button setSelected:NO];
        button.adjustsImageWhenHighlighted = NO;
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        [self imageTopTitleBottom:button];
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

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
    if([IJTNetowrkStatus supportWifi]) {
        self.wifiReachability = [IJTNetowrkStatus wifiReachability];
        [self.wifiReachability startNotifier];
    }
    if([IJTNetowrkStatus supportCellular]) {
        self.cellReachability = [IJTNetowrkStatus cellReachability];
        [self.cellReachability startNotifier];
    }
    [self reachabilityChanged:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self dismissKeyboard];
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if([IJTNetowrkStatus supportWifi])
        [self.wifiReachability stopNotifier];
    if([IJTNetowrkStatus supportCellular])
        [self.cellReachability stopNotifier];
}

- (void)gotoTracepathVC {
    [self dismissKeyboard];
    
    if(self.targetTextField.text.length <= 0) {
        [self showErrorMessage:@"Target is empty."];
        return;
    }
    
    if(self.sourceTextField.text.length <= 0) {
        [self showErrorMessage:@"Source is empty."];
        return;
    }
    else if(![IJTValueChecker checkIpv4Address:self.sourceTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.sourceTextField.text]];
        return;
    }
    
    if(self.startTTLTextField.text.length <= 0) {
        [self showErrorMessage:@"Start TTL is empty."];
        return;
    }
    else if(![IJTValueChecker checkUint8:self.startTTLTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid TTL value.", self.startTTLTextField.text]];
        return;
    }
    else if([self.startTTLTextField.text integerValue] == 0) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid TTL value.", self.startTTLTextField.text]];
        return;
    }
    
    if(self.endTTLTextField.text.length <= 0) {
        [self showErrorMessage:@"End TTL is empty."];
        return;
    }
    else if(![IJTValueChecker checkUint8:self.endTTLTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid TTL value.", self.endTTLTextField.text]];
        return;
    }
    else if([self.endTTLTextField.text integerValue] == 0) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid TTL value.", self.endTTLTextField.text]];
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
    
    if(self.payloadSizeTextField.text.length <= 0) {
        [self showErrorMessage:@"Payload size is empty"];
        return;
    }
    else if(![IJTValueChecker checkUint16:self.payloadSizeTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid payload size value.", self.payloadSizeTextField.text]];
        return;
    }
    else if([self.payloadSizeTextField.text integerValue] > TRACEPATH_MAXSIZE) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid payload size value.", self.payloadSizeTextField.text]];
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
    
    IJTTracepathTos tos = 0;
    
    if(self.bit1Button.isSelected)
        tos |= IJTTracepathTos1;
    if(self.bit2Button.isSelected)
        tos |= IJTTracepathTos2;
    if(self.bit3Button.isSelected)
        tos |= IJTTracepathTos3;
    if(self.bit4Button.isSelected)
        tos |= IJTTracepathTosD;
    if(self.bit5Button.isSelected)
        tos |= IJTTracepathTosT;
    if(self.bit6Button.isSelected)
        tos |= IJTTracepathTosR;
    if(self.bit7Button.isSelected)
        tos |= IJTTracepathTosC;
    if(self.bit8Button.isSelected)
        tos |= IJTTracepathTosX;
    
    IJTTracepathResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"tracepathResultVC"];
    vc.target = self.targetTextField.text;
    vc.sourceIpAddress = self.sourceTextField.text;
    vc.startTTL = [self.startTTLTextField.text integerValue];
    vc.endTTL = [self.endTTLTextField.text integerValue];
    vc.tos = tos;
    vc.startPort = [self.startPortTextField.text integerValue];
    vc.endPort = [self.endPortTextField.text integerValue];
    vc.payloadSize = [self.payloadSizeTextField.text integerValue];
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.multiToolButton = self.multiToolButton;
    vc.resolveHostname = self.resolveHostnameSwitch.isOn;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)sourceTypeChange {
    NSString *title = [self.sourceSegmentedControl
                       titleForSegmentAtIndex:self.sourceSegmentedControl.selectedSegmentIndex];
    NSString *sourceIpAddress = nil;
    self.sourceTextField.text = @"";
    
    if([title isEqualToString:@"Wi-Fi"]) {
        if(self.wifiReachability.currentReachabilityStatus != NotReachable) {
            sourceIpAddress = [IJTNetowrkStatus currentIPAddress:@"en0"];
        }
        if(sourceIpAddress == nil) {
            self.sourceTextField.placeholder = @"Couldn\'t get current IP address";
        }
        else {
            self.sourceTextField.text = sourceIpAddress;
        }
    }
    else if([title isEqualToString:@"Cellular"]) {
        if(self.cellReachability.currentReachabilityStatus != NotReachable) {
            sourceIpAddress = [IJTNetowrkStatus currentIPAddress:@"pdp_ip0"];
        }
        if(sourceIpAddress == nil) {
            self.sourceTextField.placeholder = @"Couldn\'t get current IP address";
        }
        else {
            self.sourceTextField.text = sourceIpAddress;
        }
    }
}

#pragma mark text field delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.startTTLTextField.isFirstResponder) {
        [self.startTTLTextField resignFirstResponder];
    }
    else if(self.endTTLTextField.isFirstResponder) {
        [self.endTTLTextField resignFirstResponder];
    }
    else if(self.startPortTextField.isFirstResponder) {
        [self.startPortTextField resignFirstResponder];
    }
    else if(self.endPortTextField.isFirstResponder) {
        [self.endPortTextField resignFirstResponder];
    }
    else if(self.payloadSizeTextField.isFirstResponder) {
        [self.payloadSizeTextField resignFirstResponder];
    }
    else if(self.timeoutTextField.isFirstResponder) {
        [self.timeoutTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.targetTextField) {
        [self.startTTLTextField becomeFirstResponder];
    }
    else if(textField == self.startTTLTextField) {
        [self.endTTLTextField becomeFirstResponder];
    }
    else if(textField == self.endTTLTextField) {
        [self.startPortTextField becomeFirstResponder];
    }
    else if(textField == self.startPortTextField) {
        [self.endPortTextField becomeFirstResponder];
    }
    else if(textField == self.endPortTextField) {
        [self.payloadSizeTextField becomeFirstResponder];
    }
    else if(textField == self.payloadSizeTextField) {
        [self.timeoutTextField becomeFirstResponder];
    }
    else if(textField == self.timeoutTextField) {
        [self.timeoutTextField resignFirstResponder];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.timeoutTextField ||
       textField == self.startTTLTextField || textField == self.endTTLTextField ||
       textField == self.payloadSizeTextField ||
       textField == self.startPortTextField || textField == self.endPortTextField) {
        allowString = @"1234567890\b";
    }
    else if(textField == self.sourceTextField) {
        allowString = @"1234567890.\b";
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
    [self sourceTypeChange];
}

#pragma mark tos button
-(void)imageTopTitleBottom:(UIButton *)button
{
    // the space between the image and text
    CGFloat spacing = 3.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = button.imageView.image.size;
    button.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
    button.imageEdgeInsets = UIEdgeInsetsMake(- (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
}

-(void)buttonTapped:(UIButton *)button {
    button.selected = !button.selected;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 9;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 1 || section == 2 || section == 3)
        return 2;
    else
        return 1;
}


@end
