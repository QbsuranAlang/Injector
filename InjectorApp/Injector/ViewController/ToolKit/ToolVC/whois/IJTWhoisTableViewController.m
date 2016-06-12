//
//  IJTWhoisTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/23.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWhoisTableViewController.h"
#import "IJTWhoisResultTableViewController.h"

@interface IJTWhoisTableViewController ()

@property (nonatomic, strong) FUITextField *targetTextField;
@property (nonatomic, strong) FUITextField *serverTextField;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) NSMutableArray *serverList;
@property (nonatomic, strong) FUITextField *timeoutTextField;

@end

@implementation IJTWhoisTableViewController

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
    
    
    self.serverTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.serverTextField.placeholder = @"Tap to select a WHOIS server";
    self.serverTextField.text = [IJTWhois whoisServerList2String:IJTWhoisServerListPnic];
    
    self.timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    self.timeoutTextField.text = @"5000";
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoWHOISVC) forControlEvents:UIControlEventTouchUpInside];
    
    [self.targetView addSubview:self.targetTextField];
    [self.serverView addSubview:self.serverTextField];
    [self.timeoutView addSubview:self.timeoutTextField];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self dismissKeyboard];
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)gotoWHOISVC {
    [self dismissKeyboard];
    
    if(self.targetTextField.text.length <= 0) {
        [self showErrorMessage:@"Target is empty."];
        return;
    }
    if(self.serverTextField.text.length <= 0) {
        [self showErrorMessage:@"Server is empty."];
        return;
    }
    
    if(self.timeoutTextField.text.length <= 0) {
        [self showErrorMessage:@"Timeout is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:_timeoutTextField.text] ||
            [self.timeoutTextField.text longLongValue] <= 0) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid timeout value.", _timeoutTextField.text]];
        return;
    }
    
    IJTWhoisResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"WHOISResultVC"];
    vc.target = self.targetTextField.text;
    vc.server = self.serverTextField.text;
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark picker view

- (NSAttributedString *)czpickerView:(CZPickerView *)pickerView attributedTitleForRow:(NSInteger)row {
    
    NSMutableParagraphStyle *mutParaStyle = [[NSMutableParagraphStyle alloc] init];
    [mutParaStyle setAlignment:NSTextAlignmentCenter];
    
    NSMutableDictionary *attrsDictionary = [[NSMutableDictionary alloc] init];
    [attrsDictionary setObject:[UIFont systemFontOfSize:17] forKey:NSFontAttributeName];
    [attrsDictionary setObject:mutParaStyle forKey:NSParagraphStyleAttributeName];
    
    return [[NSMutableAttributedString alloc]
            initWithString:self.serverList[row] attributes:attrsDictionary];
}

- (NSInteger)numberOfRowsInPickerView:(CZPickerView *)pickerView{
    return self.serverList.count;
}

- (void)czpickerView:(CZPickerView *)pickerView didConfirmWithItemAtRow:(NSInteger)row {
    self.serverTextField.text = self.serverList[row];
    if(row == self.serverList.count - 1) {
        [self.serverTextField becomeFirstResponder];
    }
}

#pragma mark text field delegate


- (void)textFieldDidEndEditing:(UITextField *)textField {
    if(textField == self.serverTextField) {
        self.serverTextField.placeholder = @"Tap to select a WHOIS server";
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    if(textField == self.serverTextField) {
        if([self.serverTextField.text isEqualToString:@"Other"]) {
            self.serverTextField.text = @"";
            self.serverTextField.placeholder = @"Server IP address or hostname";
            return YES;
        }
        
        [self dismissKeyboard];
        
        self.serverList = [NSMutableArray arrayWithArray:[IJTWhois whoisServerList]];
        [self.serverList addObject:@"Other"];
        
        CZPickerView *picker = [IJTPickerView pickerViewTitle:@"WHOIS Server List" target:self];
        [picker show];
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(self.targetTextField == textField) {
        [self.serverTextField becomeFirstResponder];
    }
    else if(textField == self.serverTextField) {
        [self.timeoutTextField becomeFirstResponder];
    }
    else if(textField == self.timeoutTextField) {
        [self.timeoutTextField resignFirstResponder];
    }
    
    return NO;
}

- (void)dismissKeyboard {
    if(self.targetTextField.isFirstResponder) {
        [self.targetTextField resignFirstResponder];
    }
    else if(self.serverTextField.isFirstResponder) {
        [self.serverTextField resignFirstResponder];
    }
    else if(self.timeoutTextField.isFirstResponder) {
        [self.timeoutTextField resignFirstResponder];
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.timeoutTextField) {
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
    return 1;
}

@end
