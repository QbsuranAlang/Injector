//
//  IJTArpoisonTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTArpoisonTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTArpoisonResultTableViewController.h"

@interface IJTArpoisonTableViewController ()

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) FUISegmentedControl *targetTypeSegmentedControl;
@property (nonatomic, strong) FUISegmentedControl *opTypeSegmentedControl;
@property (nonatomic, strong) NSString *gatewayAddress;
@property (nonatomic, strong) FUITextField *singleTextField;
@property (nonatomic, strong) FUITextField *injectRowsTextField;
@property (nonatomic, strong) FUITextField *intervalTextField;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) NSThread *getDefaultGatewayThread;
@property (nonatomic, strong) FUISegmentedControl *senderTypeSegmentedControl;
@property (nonatomic, strong) FUISwitch *twoWaySwitch;
@property (nonatomic, strong) FUISwitch *forwardSwitch;
@property (nonatomic, strong) FUITextField *senderIpAddressTextField;
@property (nonatomic, strong) FUITextField *senderMacAddressTextField;
@property (nonatomic, strong) NSString *myIpAddress;
@property (nonatomic, strong) NSString *myMacAddress;
@property (nonatomic, strong) FUITextField *startIpAddressTextField;
@property (nonatomic, strong) FUITextField *endIpAddressTextField;

@end

@implementation IJTArpoisonTableViewController

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
    
    self.targetTypeSegmentedControl = [[FUISegmentedControl alloc]
                                 initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 28)];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"Gateway" atIndex:0 animated:NO];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"LAN" atIndex:1 animated:NO];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"Range" atIndex:2 animated:NO];
    [self.targetTypeSegmentedControl insertSegmentWithTitle:@"Single" atIndex:3 animated:NO];
    [self.targetTypeSegmentedControl setSelectedSegmentIndex:0];
    [self.targetTypeSegmentedControl
     setWidth:(SCREEN_WIDTH-16)/self.targetTypeSegmentedControl.numberOfSegments+10 forSegmentAtIndex:0];
    [self.targetTypeSegmentedControl addTarget:self action:@selector(typeChange:) forControlEvents:UIControlEventValueChanged];
    
    self.senderTypeSegmentedControl = [[FUISegmentedControl alloc]
                                       initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 28)];
    [self.senderTypeSegmentedControl insertSegmentWithTitle:@"Myself" atIndex:0 animated:NO];
    [self.senderTypeSegmentedControl insertSegmentWithTitle:@"Other" atIndex:1 animated:NO];
    [self.senderTypeSegmentedControl setSelectedSegmentIndex:0];
    [self.senderTypeSegmentedControl addTarget:self action:@selector(typeChange:) forControlEvents:UIControlEventValueChanged];
    
    self.opTypeSegmentedControl = [[FUISegmentedControl alloc]
                                  initWithFrame:CGRectMake(0, 0, 180, 28)];
    [self.opTypeSegmentedControl insertSegmentWithTitle:@"Reply" atIndex:0 animated:NO];
    [self.opTypeSegmentedControl insertSegmentWithTitle:@"Request" atIndex:1 animated:NO];
    [self.opTypeSegmentedControl setSelectedSegmentIndex:0];
    
    self.singleTextField = [IJTTextField baseTextFieldWithTarget:self];
    
    self.senderIpAddressTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.senderIpAddressTextField.placeholder = @"Sender IP address";
    
    self.senderMacAddressTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.senderMacAddressTextField.placeholder = @"Sender MAC address";
    
    self.injectRowsTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.injectRowsTextField.placeholder = @"Send frame rows(0 equal infinity)";
    self.injectRowsTextField.text = @"0";
    
    self.intervalTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.intervalTextField.placeholder = @"Send frame interval(µs)";
    self.intervalTextField.returnKeyType = UIReturnKeyDone;
    self.intervalTextField.text = @"3000000";
    
    self.startIpAddressTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.startIpAddressTextField.placeholder = @"Start IP address";
    
    self.endIpAddressTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.endIpAddressTextField.placeholder = @"End IP address";
    
    self.twoWaySwitch = [[FUISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.twoWaySwitch.offLabel.text = @"NO";
    self.twoWaySwitch.onLabel.text = @"YES";
    self.twoWaySwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.twoWaySwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.twoWaySwitch setOn:YES];
    
    self.forwardSwitch = [[FUISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.forwardSwitch.offLabel.text = @"NO";
    self.forwardSwitch.onLabel.text = @"YES";
    self.forwardSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.forwardSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoArposionVC) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.getDefaultGatewayThread = nil;
    
    if(self.fromLAN) {
        [self.targetTypeSegmentedControl setSelectedSegmentIndex:3];
        [self.targetTypeSegmentedControl setEnabled:NO];
        [self.singleTextField setEnabled:NO];
        self.singleTextField.text = self.ipAddressFromLan;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
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

- (void)gotoArposionVC {
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        if(self.singleTextField.text.length <= 0) {
            [self showErrorMessage:@"Default gateway is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:_singleTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.singleTextField.text]];
            return;
        }
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 2) {
        if(self.startIpAddressTextField.text.length <= 0) {
            [self showErrorMessage:@"Start IP address is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:self.startIpAddressTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.startIpAddressTextField.text]];
            return;
        }
        
        if(self.endIpAddressTextField.text.length <= 0) {
            [self showErrorMessage:@"End IP address is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:self.endIpAddressTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.endIpAddressTextField.text]];
            return;
        }
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 3) {
        if(self.singleTextField.text.length <= 0) {
            [self showErrorMessage:@"Target IP address is empty."];
            return;
        }
        else if(![IJTValueChecker checkIpv4Address:_singleTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.singleTextField.text]];
            return;
        }
    }
    
    if(self.senderIpAddressTextField.text.length <= 0) {
        [self showErrorMessage:@"Sender IP address is empty."];
        return;
    }
    else if(![IJTValueChecker checkIpv4Address:_senderIpAddressTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.senderIpAddressTextField.text]];
        return;
    }
    
    if(self.senderMacAddressTextField.text.length <= 0) {
        [self showErrorMessage:@"Sender MAC address is empty."];
        return;
    }
    else if(![IJTValueChecker checkMacAddress:_senderMacAddressTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid MAC address.", self.senderMacAddressTextField.text]];
        return;
    }
    
    if(self.injectRowsTextField.text.length <= 0) {
        [self showErrorMessage:@"injectRows is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:_injectRowsTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid injectRows value.", self.injectRowsTextField.text]];
        return;
    }
    
    if([self.injectRowsTextField.text integerValue] != 1) {
        if(self.intervalTextField.text.length <= 0) {
            [self showErrorMessage:@"Interval is empty."];
            return;
        }
        else if(![IJTValueChecker checkAllDigit:self.intervalTextField.text]) {
            [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid interval value.", self.intervalTextField.text]];
            return;
        }
    }
    
    IJTArpoisonResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ArpoisonResultVC"];
    vc.targetType = self.targetTypeSegmentedControl.selectedSegmentIndex;
    vc.singleAddress = self.singleTextField.text;
    vc.senderType = self.senderTypeSegmentedControl.selectedSegmentIndex;
    vc.senderIpAddress = self.senderIpAddressTextField.text;
    vc.senderMacAddress = self.senderMacAddressTextField.text;
    vc.opCode = self.opTypeSegmentedControl.selectedSegmentIndex;
    vc.injectRows = [self.injectRowsTextField.text integerValue];
    vc.interval = (useconds_t)[self.intervalTextField.text longLongValue];
    vc.startIpAddress = self.startIpAddressTextField.text;
    vc.endIpAddress = self.endIpAddressTextField.text;
    vc.twoWay = self.twoWaySwitch.isOn;
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma text view delegate
- (void)dismissKeyboard {
    if(self.singleTextField.isFirstResponder) {
        [self.singleTextField resignFirstResponder];
    }
    else if(self.injectRowsTextField.isFirstResponder) {
        [self.injectRowsTextField resignFirstResponder];
    }
    else if(self.intervalTextField.isFirstResponder) {
        [self.intervalTextField resignFirstResponder];
    }
    else if(self.senderIpAddressTextField.isFirstResponder) {
        [self.senderIpAddressTextField resignFirstResponder];
    }
    else if(self.senderMacAddressTextField.isFirstResponder) {
        [self.senderMacAddressTextField resignFirstResponder];
    }
    else if(self.startIpAddressTextField.isFirstResponder) {
        [self.startIpAddressTextField resignFirstResponder];
    }
    else if(self.endIpAddressTextField.isFirstResponder) {
        [self.endIpAddressTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.startIpAddressTextField) {
        [self.endIpAddressTextField becomeFirstResponder];
    }
    else if(textField == self.endIpAddressTextField) {
        [self.senderIpAddressTextField becomeFirstResponder];
    }
    else if(textField == self.singleTextField) {
        [self.senderIpAddressTextField becomeFirstResponder];
    }
    else if(textField == self.senderIpAddressTextField) {
        if(self.senderMacAddressTextField.isEnabled)
            [self.senderMacAddressTextField becomeFirstResponder];
        else
            [self.injectRowsTextField becomeFirstResponder];
    }
    else if(textField == self.senderMacAddressTextField) {
        [self.injectRowsTextField becomeFirstResponder];
    }
    else if(textField == self.injectRowsTextField) {
        [self.intervalTextField becomeFirstResponder];
    }
    else if(textField == self.intervalTextField) {
        [self.intervalTextField resignFirstResponder];
    }
    
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.injectRowsTextField || textField == self.intervalTextField) {
        allowString = @"1234567890\b";
    }
    else if(textField == self.singleTextField || textField == self.senderIpAddressTextField) {
        allowString = @"1234567890.\b";
    }
    else if(textField == self.senderMacAddressTextField) {
        allowString = @"1234567890abcdefABCDEF:\b";
    }
    else
        return YES;
    
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

#pragma mark segement control
- (void)typeChange: (id)sender {
    FUISegmentedControl *segmentedControl = sender;
    if(segmentedControl == self.targetTypeSegmentedControl) {
        if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
            self.singleTextField.text = self.gatewayAddress;
            [self.singleTextField setEnabled:NO];
            
            if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
                self.singleTextField.placeholder = @"Getting default gateway...";
            }
            else {
                self.singleTextField.placeholder = @"Couldn\'t get default gateway address";
                self.singleTextField.text = @"";
            }
        }
        else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 2) {
            NSArray *arr = [IJTNetowrkStatus getWiFiNetworkStartAndEndIpAddress];
            if(arr && arr.count == 2) {
                self.startIpAddressTextField.text = [arr objectAtIndex:0];
                self.endIpAddressTextField.text = [arr objectAtIndex:1];
            }
            else {
                self.startIpAddressTextField.text = @"";
                self.endIpAddressTextField.text = @"";
            }
        }
        else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 3) {
            if(!self.fromLAN) {
                [self.singleTextField setEnabled:YES];
                self.singleTextField.text = @"";
            }
            self.singleTextField.placeholder = @"Target IP address";
        }
    }
    
    if(segmentedControl == self.senderTypeSegmentedControl) {
        if(self.senderTypeSegmentedControl.selectedSegmentIndex == 0) {
            if(self.myIpAddress != nil)
                self.senderIpAddressTextField.text = self.myIpAddress;
            if(self.myMacAddress != nil)
                self.senderMacAddressTextField.text = self.myMacAddress;
            [self.senderMacAddressTextField setEnabled:NO];
        }
        else {
            self.senderIpAddressTextField.text = @"";
            [self.senderMacAddressTextField setEnabled:YES];
        }
    }
    
    [self.tableView reloadData];
    
    if(segmentedControl == self.senderTypeSegmentedControl) {
        if(self.senderTypeSegmentedControl.selectedSegmentIndex == 1) {
            [self.senderMacAddressTextField becomeFirstResponder];
        }
    }
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    self.gatewayAddress = @"";
    self.myIpAddress = @"";
    
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"arposion"];
        [self.actionButton setEnabled:NO];
        [self.actionButton setTitle:@"No Wi-Fi Connection" forState:UIControlStateNormal];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.actionButton setEnabled:YES];
        [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
        
        //get getgaway
        if(self.getDefaultGatewayThread == nil) {
            //otherwise when popped back to the view, it will cause crash. What the damn bug.
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                self.getDefaultGatewayThread =
                [[NSThread alloc] initWithTarget:self selector:@selector(getDefaultGateway) object:nil];
                [self.getDefaultGatewayThread start];
            }];
        }
        
        self.myIpAddress = [IJTNetowrkStatus currentIPAddress:@"en0"];
    }
    
    self.myMacAddress = [IJTNetowrkStatus wifiMacAddress];
    [self typeChange:self.targetTypeSegmentedControl];
    [self typeChange:self.senderTypeSegmentedControl];
}

ROUTETABLE_SHOW_CALLBACK_METHOD {
    if(![interface isEqualToString:@"en0"])
        return;
    
    if(type == IJTRoutetableTypeInet4 && [destinationIpAddress isEqualToString:@"0.0.0.0"]) {
        self.gatewayAddress = [NSString stringWithString:gateway];
    }
}

- (void)getDefaultGateway {
    IJTRoutetable *route = [[IJTRoutetable alloc] init];
    if(route.errorHappened) {
        if(route.errorCode == 0) {
            [self showErrorMessage:[NSString stringWithFormat:@"%@.", route.errorMessage]];
        }
        else {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(route.errorCode)]];
        }
        [IJTDispatch dispatch_main:^{
            self.singleTextField.placeholder = @"Couldn\'t get default gateway address";
        }];
    }
    else {
        [route getGatewayByDestinationIpAddress:@"0.0.0.0"
                                         target:self
                                       selector:ROUTETABLE_SHOW_CALLBACK_SEL
                                         object:nil];
        if(self.gatewayAddress.length <= 0) {
            [IJTDispatch dispatch_main:^{
                self.singleTextField.placeholder = @"Couldn\'t get default gateway address";
            }];
        }
        [route close];
    }//end else
    [IJTDispatch dispatch_main:^{
        [self typeChange:self.targetTypeSegmentedControl];
        [self typeChange:self.senderTypeSegmentedControl];
    }];
    
    self.getDefaultGatewayThread = nil;
}

#pragma mark sysctl
- (void)forwardingSwitchChange: (id)sender {
    FUISwitch *forwardingSwitch = sender;
    int state = [IJTSysctl setIPForwarding:forwardingSwitch.isOn];
    if(state == -1) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(EPERM)]];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [forwardingSwitch setOn:!forwardingSwitch.isOn animated:YES];
        }];
    }
    else {
        [self showSuccessMessage:@"Success"];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0 ||
       self.targetTypeSegmentedControl.selectedSegmentIndex == 2 ||
       self.targetTypeSegmentedControl.selectedSegmentIndex == 3) {
        return 7;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        return 6;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0 ||
       self.targetTypeSegmentedControl.selectedSegmentIndex == 3) {
        if(section == 0 || section == 1 || section == 4 || section == 5 || section == 6)
            return 1;
        else if(section == 2 || section == 3)
            return 3;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        if(section == 0 || section == 3 || section == 4 || section == 5)
            return 1;
        else if(section == 1 || section == 2)
            return 3;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 2) {
        if(section == 0 || section == 4 || section == 5 || section == 6)
            return 1;
        else if(section == 1)
            return 2;
        else if(section == 2 || section == 3)
            return 3;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:_targetTypeSegmentedControl];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 1 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 3 && indexPath.section == 1 && indexPath.row == 0)) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:_singleTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 2 && indexPath.section == 1) {
        if(indexPath.row == 0) {
            GET_EMPTY_CELL;
            [cell.contentView addSubview:_startIpAddressTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_EMPTY_CELL;
            [cell.contentView addSubview:_endIpAddressTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    
    if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 2) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 1) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 2 && indexPath.section == 2) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 3 && indexPath.section == 2)) {
        if(indexPath.row == 0) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Whose"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            
            [cell.controlView addSubview:_senderTypeSegmentedControl];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.senderTypeSegmentedControl.frame = CGRectMake(width - 180, 0, 180, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_EMPTY_CELL;
            [cell.contentView addSubview:_senderIpAddressTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 2) {
            GET_EMPTY_CELL;
            [cell.contentView addSubview:_senderMacAddressTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    
    if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 3) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 2) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 2 && indexPath.section == 3) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 3 && indexPath.section == 3)) {
        if(indexPath.row == 0) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Operation"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            
            [cell.controlView addSubview:_opTypeSegmentedControl];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.opTypeSegmentedControl.frame = CGRectMake(width - 180, 0, 180, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Two-way"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            
            [cell.controlView addSubview:_twoWaySwitch];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.twoWaySwitch.frame = CGRectMake(width - 80, 0, 80, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 2) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Packet Forward"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            [cell.controlView addSubview:_forwardSwitch];
            
            int state = [IJTSysctl ipForwarding];
            if(state == 1) {
                [self.forwardSwitch setOn:YES];
            }
            else if(state == 0) {
                [self.forwardSwitch setOn:NO];
            }
            else if(state == -1) {
                [self.forwardSwitch setOn:NO];
                [self.forwardSwitch setEnabled:NO];
                [self showErrorMessage:@"Couldn\'t get forwarding information"];
            }
            [self.forwardSwitch addTarget:self action:@selector(forwardingSwitchChange:) forControlEvents:UIControlEventValueChanged];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.forwardSwitch.frame = CGRectMake(width - 80, 0, 80, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    
    if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 4 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 3 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 2 && indexPath.section == 4 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 3 && indexPath.section == 4 && indexPath.row == 0)) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:_injectRowsTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 5 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 4 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 2 && indexPath.section == 5 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 3 && indexPath.section == 5 && indexPath.row == 0)) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:_intervalTextField];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    if((self.targetTypeSegmentedControl.selectedSegmentIndex == 0 && indexPath.section == 6 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 1 && indexPath.section == 5 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 2 && indexPath.section == 6 && indexPath.row == 0) ||
       (self.targetTypeSegmentedControl.selectedSegmentIndex == 3 && indexPath.section == 6 && indexPath.row == 0)) {
        GET_EMPTY_CELL;
        [cell.contentView addSubview:_actionButton];
        
        [cell layoutIfNeeded];
        return cell;
    }
    return [[UITableViewCell alloc] init];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Target Type";
    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0) {
        if(section == 1)
            return @"Default Gateway";
        else if(section == 2)
            return @"Sender Type";
        else if(section == 3)
            return @"Option";
        else if(section == 4)
            return @"Row";
        else if(section == 5)
            return @"Inject Interval";
        else if(section == 6)
            return @"Action";
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        if(section == 1)
            return @"Sender Type";
        else if(section == 2)
            return @"Option";
        else if(section == 3)
            return @"Row";
        else if(section == 4)
            return @"Inject Interval";
        else if(section == 5)
            return @"Action";
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 2) {
        if(section == 1)
            return @"Range";
        else if(section == 2)
            return @"Sender Type";
        else if(section == 3)
            return @"Option";
        else if(section == 4)
            return @"Row";
        else if(section == 5)
            return @"Inject Interval";
        else if(section == 6)
            return @"Action";
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 3) {
        if(section == 1)
            return @"Single";
        else if(section == 2)
            return @"Sender Type";
        else if(section == 3)
            return @"Option";
        else if(section == 4)
            return @"Row";
        else if(section == 5)
            return @"Inject Interval";
        else if(section == 6)
            return @"Action";
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    if(self.targetTypeSegmentedControl.selectedSegmentIndex == 0 ||
       self.targetTypeSegmentedControl.selectedSegmentIndex == 2 ||
       self.targetTypeSegmentedControl.selectedSegmentIndex == 3) {
        if(indexPath.section == 6)
            return 55.0f;
    }
    else if(self.targetTypeSegmentedControl.selectedSegmentIndex == 1) {
        if(indexPath.section == 5)
            return 55.0f;
    }
    
    return 44.0f;
}

@end
