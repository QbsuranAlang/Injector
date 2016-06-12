//
//  IJTHTTPSFisherTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/12/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTHTTPSFisherTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTHTTPSFisherResultTableViewController.h"
@interface IJTHTTPSFisherTableViewController ()

@property (nonatomic, strong) FUITextField *redirectHostnameTextField;
@property (nonatomic, strong) FUITextField *redirectIpAddressTextField;
@property (nonatomic, strong) FUISwitch *saveSwitch;
//@property (nonatomic, strong) FUISwitch *displayHeaderSwitch;
//@property (nonatomic, strong) FUISwitch *displayBodySwitch;
@property (nonatomic, strong) FUIButton *actionButton;

@property (nonatomic, strong) Reachability *wifiReachability;

@end

@implementation IJTHTTPSFisherTableViewController

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
    
    self.redirectHostnameTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.redirectHostnameTextField.placeholder = @"Hostname";
    
    self.redirectIpAddressTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.redirectIpAddressTextField.placeholder = @"IP address";
    self.redirectIpAddressTextField.returnKeyType = UIReturnKeyDone;
    
    self.saveSwitch = [[FUISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.saveSwitch.offLabel.text = @"NO";
    self.saveSwitch.onLabel.text = @"YES";
    self.saveSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.saveSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.saveSwitch setOn:YES];
    /*
    self.displayHeaderSwitch = [[FUISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.displayHeaderSwitch.offLabel.text = @"NO";
    self.displayHeaderSwitch.onLabel.text = @"YES";
    self.displayHeaderSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.displayHeaderSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.displayHeaderSwitch setOn:YES];
    
    self.displayBodySwitch = [[FUISwitch alloc] initWithFrame:CGRectMake(0, 0, 80, 28)];
    self.displayBodySwitch.offLabel.text = @"NO";
    self.displayBodySwitch.onLabel.text = @"YES";
    self.displayBodySwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.displayBodySwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    [self.displayBodySwitch setOn:NO];
    */
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoFishingVC) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
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

- (void)gotoFishingVC {
    [self dismissKeyboard];
    
    if(self.redirectHostnameTextField.text.length <= 0) {
        [self showErrorMessage:@"Redirect hostname is empty."];
        return;
    }
    
    if(self.redirectIpAddressTextField.text.length <= 0) {
        [self showErrorMessage:@"Redirect IP address is empty."];
        return;
    }
    else if(![IJTValueChecker checkIpv4Address:self.redirectIpAddressTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", self.redirectIpAddressTextField.text]];
        return;
    }
    
    IJTHTTPSFisherResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"HTTPSFisherResultVC"];
    vc.rediectHostname = self.redirectHostnameTextField.text;
    vc.redirectIpAddress = self.redirectIpAddressTextField.text;
    vc.savepackets = self.saveSwitch.isOn;
    vc.multiToolButton = self.multiToolButton;
    //vc.displayHeader = self.displayHeaderSwitch.isOn;
    //vc.displayBody = self.displayBodySwitch.isOn;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark UITextField
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.redirectIpAddressTextField) {
        allowString = @"1234567890.\b";
    }
    else {
        return YES;
    }
    
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

- (void)dismissKeyboard {
    if([self.redirectHostnameTextField isFirstResponder]) {
        [self.redirectHostnameTextField resignFirstResponder];
    }
    else if([self.redirectIpAddressTextField isFirstResponder]) {
        [self.redirectIpAddressTextField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.redirectHostnameTextField) {
        [self.redirectIpAddressTextField becomeFirstResponder];
    }
    else if(textField == self.redirectIpAddressTextField) {
        [self.redirectIpAddressTextField resignFirstResponder];
    }
    return NO;
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"HTTPS Fisher"];
        [self.actionButton setEnabled:NO];
        [self.actionButton setTitle:@"No Wi-Fi Connection" forState:UIControlStateNormal];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.actionButton setEnabled:YES];
        [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 2;
    else if(section == 1 || section == 2)
        return 1;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(indexPath.row == 0) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:_redirectHostnameTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_EMPTY_CELL;
            
            [cell.contentView addSubview:_redirectIpAddressTextField];
            
            [cell layoutIfNeeded];
            return cell;
        }//end else
    }//end if
    else if(indexPath.section == 1 && indexPath.row == 0) {
        GET_ARG_CELL;
        
        [IJTFormatUILabel text:@"Saving"
                         label:cell.nameLabel
                          font:[UIFont systemFontOfSize:17]];
        
        [cell.controlView addSubview:_saveSwitch];
        
        [cell layoutIfNeeded];
        
        CGFloat width = CGRectGetWidth(cell.controlView.frame);
        self.saveSwitch.frame = CGRectMake(width - 80, 0, 80, 28);
        
        [cell layoutIfNeeded];
        return cell;
    }
    /*else if(indexPath.section == 2) {
        if(indexPath.row == 0) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Header"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            
            [cell.controlView addSubview:_displayHeaderSwitch];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.displayHeaderSwitch.frame = CGRectMake(width - 80, 0, 80, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            GET_ARG_CELL;
            
            [IJTFormatUILabel text:@"Body"
                             label:cell.nameLabel
                              font:[UIFont systemFontOfSize:17]];
            
            [cell.controlView addSubview:_displayBodySwitch];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.controlView.frame);
            self.displayBodySwitch.frame = CGRectMake(width - 80, 0, 80, 28);
            
            [cell layoutIfNeeded];
            return cell;
        }
    }*/
    else if(indexPath.section == 2 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        
        [cell.contentView addSubview:self.actionButton];
        
        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Redirect Host";
    }
    else if(section == 1) {
        return @"Save packets";
    }
    /*else if(section == 2) {
        return @"Display";
    }*/
    else if(section == 2) {
        return @"Action";
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 2)
        return 55.0f;
    else
        return 44.0f;
}

@end
