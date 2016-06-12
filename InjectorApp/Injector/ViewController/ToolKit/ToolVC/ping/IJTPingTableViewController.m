//
//  IJTPingTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTPingTableViewController.h"
#import "IJTPingResultTableViewController.h"

@interface IJTPingTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUITextField *sourceTextField;
@property (nonatomic, strong) FUITextField *ttlTextField;
@property (nonatomic, strong) FUITextField *amountTextField;
@property (nonatomic, strong) FUITextField *timeoutTextField;
@property (nonatomic, strong) FUITextField *intervalTextField;
@property (nonatomic, strong) FUITextField *payloadSizeTextField;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) FUISwitch *fragmentSwitch;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) Reachability *cellReachability;

@end

@implementation IJTPingTableViewController

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
    [self.sourceSegmentedControl removeAllSegments];
    int index = 0;
    if([IJTNetowrkStatus supportWifi]) {
        [self.sourceSegmentedControl insertSegmentWithTitle:@"Wi-Fi" atIndex:index++ animated:NO];
    }
    if([IJTNetowrkStatus supportCellular]) {
        [self.sourceSegmentedControl insertSegmentWithTitle:@"Cellular" atIndex:index++ animated:NO];
    }
    
    [self.sourceSegmentedControl insertSegmentWithTitle:@"Other" atIndex:index animated:NO];
    
    if(self.sourceSegmentedControl.numberOfSegments > 0)
        [self.sourceSegmentedControl setSelectedSegmentIndex:0];
    [self.sourceSegmentedControl addTarget:self
                                    action:@selector(sourceTypeChange)
                          forControlEvents:UIControlEventTouchUpInside];
    [self sourceTypeChange];
    
    self.ttlTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.ttlTextField.placeholder = @"Time to live(Maximum: 255)";
    int ttl = [IJTSysctl sysctlValueByname:@"net.inet.ip.ttl"];
    if(ttl == -1)
        self.ttlTextField.text = @"255";
    else
        self.ttlTextField.text = [NSString stringWithFormat:@"%d", ttl];
    
    self.payloadSizeTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.payloadSizeTextField.placeholder = [NSString stringWithFormat:@"Payload size"];
    self.payloadSizeTextField.text = @"0";
    
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
    
    self.fragmentSwitch = [[FUISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.fragmentSwitch.offLabel.text = @"NO";
    self.fragmentSwitch.onLabel.text = @"YES";
    self.fragmentSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.fragmentSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.fragmentSwitch setOn:YES];
    self.fragmentView.backgroundColor = [UIColor clearColor];
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoPingVC) forControlEvents:UIControlEventTouchUpInside];
    
    [self.fragmentView addSubview:self.fragmentSwitch];
    [self.sourceView addSubview:self.sourceTextField];
    [self.targetView addSubview:self.targetTextField];
    [self.amountView addSubview:self.amountTextField];
    [self.timeoutView addSubview:self.timeoutTextField];
    [self.intervalView addSubview:self.intervalTextField];
    [self.actionView addSubview:self.actionButton];
    [self.payloadView addSubview:self.payloadSizeTextField];
    [self.ttlView addSubview:self.ttlTextField];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    [self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:17];
    }];
    
    CGFloat width = (SCREEN_WIDTH - (self.tosButtons.count - 1))/self.tosButtons.count;
    
    [self.tosButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
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

- (void)gotoPingVC {
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
    
    if(self.ttlTextField.text.length <= 0) {
        [self showErrorMessage:@"TTL is empty."];
        return;
    }
    else if(![IJTValueChecker checkUint8:self.ttlTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid TTL value.", self.ttlTextField.text]];
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
    
    IJTPingTos tos = 0;
    
    if(self.bit1Button.isSelected)
        tos |= IJTPingTos1;
    if(self.bit2Button.isSelected)
        tos |= IJTPingTos2;
    if(self.bit3Button.isSelected)
        tos |= IJTPingTos3;
    if(self.bit4Button.isSelected)
        tos |= IJTPingTosD;
    if(self.bit5Button.isSelected)
        tos |= IJTPingTosT;
    if(self.bit6Button.isSelected)
        tos |= IJTPingTosR;
    if(self.bit7Button.isSelected)
        tos |= IJTPingTosC;
    if(self.bit8Button.isSelected)
        tos |= IJTPingTosX;
    
    IJTPingResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"pingResultVC"];
    
    vc.targetIpAddress = self.targetTextField.text;
    vc.sourceIpAddress = self.sourceTextField.text;
    vc.fragment = self.fragmentSwitch.isOn;
    vc.tos = tos;
    vc.ttl = [self.ttlTextField.text integerValue];
    vc.payloadSize = [self.payloadSizeTextField.text integerValue];
    vc.amount = [self.amountTextField.text integerValue];
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.interval = (useconds_t)[self.intervalTextField.text longLongValue];
    vc.multiToolButton = self.multiToolButton;
    NSString *selectTitle = [self.sourceSegmentedControl titleForSegmentAtIndex:self.sourceSegmentedControl.selectedSegmentIndex];
    if([selectTitle isEqualToString:@"Other"])
        vc.fakeMe = YES;
    else
        vc.fakeMe = NO;
    [self.navigationController pushViewController:vc animated:YES];
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

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    [self sourceTypeChange];
}

- (void)sourceTypeChange {
    NSString *title = [self.sourceSegmentedControl
                       titleForSegmentAtIndex:self.sourceSegmentedControl.selectedSegmentIndex];
    NSString *sourceIpAddress = nil;
    self.sourceTextField.text = @"";
    
    if([title isEqualToString:@"Wi-Fi"]) {
        [self.sourceTextField setEnabled:NO];
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
        [self.sourceTextField setEnabled:NO];
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
    else if([title isEqualToString:@"Other"]) {
        self.sourceTextField.placeholder = @"Source IP address";
        [self.sourceTextField setEnabled:YES];
        [self.sourceTextField becomeFirstResponder];
    }
}

#pragma mark text field delegate
- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.sourceTextField.isFirstResponder) {
        [self.sourceTextField resignFirstResponder];
    }
    else if(self.ttlTextField.isFirstResponder) {
        [self.ttlTextField resignFirstResponder];
    }
    else if(self.amountTextField.isFirstResponder) {
        [self.amountTextField resignFirstResponder];
    }
    else if(self.intervalTextField.isFirstResponder) {
        [self.intervalTextField resignFirstResponder];
    }
    else if(self.timeoutTextField.isFirstResponder) {
        [self.timeoutTextField resignFirstResponder];
    }
    else if(self.payloadSizeTextField.isFirstResponder) {
        [self.payloadSizeTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.targetTextField) {
        if(self.sourceTextField.isEnabled)
            [self.sourceTextField becomeFirstResponder];
        else
            [self.ttlTextField becomeFirstResponder];
    }
    else if(textField == self.sourceTextField) {
        [self.ttlTextField becomeFirstResponder];
    }
    else if(textField == self.ttlTextField) {
        [self.payloadSizeTextField becomeFirstResponder];
    }
    else if(textField == self.payloadSizeTextField) {
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
    
    if(textField == self.timeoutTextField || textField == self.amountTextField || textField == self.intervalTextField ||
       textField == self.ttlTextField || textField == self.payloadSizeTextField) {
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 10;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 1)
        return 2;
    else
        return 1;
}

@end
