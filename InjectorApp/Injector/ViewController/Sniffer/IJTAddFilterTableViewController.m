//
//  IJTAddFilterTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTAddFilterTableViewController.h"

@interface IJTAddFilterTableViewController ()

@property (nonatomic, strong) FUITextField *nameTextField;
@property (nonatomic, strong) FUITextField *pcapFilterTextField;
@property (nonatomic) BOOL supportWifi;
@property (nonatomic) BOOL supportCellular;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) Reachability *cellReachability;

typedef enum {
    nameTextFieldTag,
    pcapFilterTextFieldTag
} TextFieldType;

@end

@implementation IJTAddFilterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"down.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.nameTextField = [IJTTextField baseTextFieldWithTarget:self];
    [self.nameView addSubview:self.nameTextField];
    
    self.pcapFilterTextField = [IJTTextField baseTextFieldWithTarget:self];
    [self.pcapFilterView addSubview:self.pcapFilterTextField];
    
    [self.pcapFilterTextField addTarget:self
                                 action:@selector(pcapFilterTextFieldEditingCganged:)
                       forControlEvents:UIControlEventEditingChanged];
    
    self.nameTextField.placeholder = @"The nickname you can recognize";
    self.pcapFilterTextField.placeholder = @"The filter expression";
    
    self.nameTextField.tag = nameTextFieldTag;
    self.pcapFilterTextField.tag = pcapFilterTextFieldTag;
    
    self.pcapFilterTextField.returnKeyType = UIReturnKeyDone;
    
    [self.addButton addTarget:self action:@selector(addFilter) forControlEvents:UIControlEventTouchUpInside]; 
    
    //get support status
    self.supportWifi = [IJTNetowrkStatus supportWifi];
    self.supportCellular = [IJTNetowrkStatus supportCellular];
    
    
    if(!self.supportWifi) {
        [self.wifiLabel removeFromSuperview];
        [self.wifiView removeFromSuperview];
    }
    
    if(!self.supportCellular) {
        [self.cellLabel removeFromSuperview];
        [self.cellView removeFromSuperview];
    }
    
    [self pcapFilterTextFieldEditingCganged:self.pcapFilterTextField];
    
    UITapGestureRecognizer *singleFingerTap1 =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(startAnimation:)];
    UITapGestureRecognizer *singleFingerTap2 =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(startAnimation:)];
    [self.wifiView addGestureRecognizer:singleFingerTap1];
    [self.cellView addGestureRecognizer:singleFingerTap2];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.wifiLabel.font = [UIFont systemFontOfSize:17];
    self.cellLabel.font = [UIFont systemFontOfSize:17];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.view startCanvasAnimation];
    
    //reachability
    [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
    if(self.supportWifi) {
        self.wifiReachability = [IJTNetowrkStatus wifiReachability];
        [self.wifiReachability startNotifier];
    }
    if(self.supportCellular) {
        self.cellReachability = [IJTNetowrkStatus cellReachability];
        [self.cellReachability startNotifier];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if(self.supportWifi)
        [self.wifiReachability stopNotifier];
    if(self.supportCellular)
        [self.cellReachability stopNotifier];
}

- (void) startAnimation: (UITapGestureRecognizer *)recognizer {
    CSAnimationView *animation = (CSAnimationView *)recognizer.view;
    [animation startCanvasAnimation];
}

- (void)dismissVC {
    [self dismissKeyboard];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard {
    if(self.nameTextField.isFirstResponder) {
        [self.nameTextField resignFirstResponder];
    }
    else if(self.pcapFilterTextField.isFirstResponder) {
        [self.pcapFilterTextField resignFirstResponder];
    }
}

- (void)addFilter {
    
    [self dismissKeyboard];
    
    if([self.nameTextField.text isEqualToString:@""]) {
        [self showErrorMessage:@"You have to name it."];
        return;
    }
    if([self.pcapFilterTextField.text isEqualToString:@""]) {
        [self showErrorMessage:@"Please enter filter expression."];
        return;
    }
    if([self checkPcapExsitForKey:self.pcapFilterTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is exsit.", self.pcapFilterTextField.text]];
        return;
    }
    if(![IJTPcap testPcapFilter:self.pcapFilterTextField.text interface:@"en0"] &&
       ![IJTPcap testPcapFilter:self.pcapFilterTextField.text interface:@"pdp_ip0"]) {
        
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" Wi-Fi or Cellular can't apply.", self.pcapFilterTextField.text]];
        return;
    }
    NSString *path = nil;
    if(geteuid()) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        path = [NSString stringWithFormat:@"%@/%@", basePath, @"PcapFiler"];
    }
    else {
        path = @"/var/root/Injector/PcapFiler";
    }
    
    NSMutableArray *pcapFilter = [NSMutableArray arrayWithContentsOfFile:path];
    if(pcapFilter == nil) {
        pcapFilter = [[NSMutableArray alloc] init];
        [pcapFilter writeToFile:path atomically:YES];
    }
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:self.pcapFilterTextField.text forKey:@"pcapFilter"];
    [dict setValue:self.nameTextField.text forKey:@"name"];
    [pcapFilter addObject:dict];
    [pcapFilter writeToFile:path atomically:YES];
    
    [self showSuccessMessage:@"Success"];
    
    [self.delegate callback];
    [self.view startCanvasAnimation];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    [self pcapFilterTextFieldEditingCganged:self.pcapFilterTextField];
}

- (BOOL)checkPcapExsitForKey: (NSString *)key {
    NSString *path = nil;
    //if([[[NSBundle mainBundle] bundleIdentifier] containsString:@"debug"]) {
    if(geteuid()) {
        path = [[NSBundle mainBundle] pathForResource:@"DefaultPcapFilter" ofType:@"plist"];
    }
    else
        path = @"/Applications/Injector.app/DefaultPcapFilter.plist";
    
    NSDictionary *defaultPcapFilter = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSArray *filterInPlist = [defaultPcapFilter valueForKey:@"pcapFilter"];
    for(NSString *filter in filterInPlist) {
        if([filter isEqualToString:key])
            return YES;
    }
    
    
    if(geteuid()) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        path = [NSString stringWithFormat:@"%@/%@", basePath, @"PcapFiler"];
    }
    else {
        path = @"/var/root/Injector/PcapFiler";
    }
    
    NSArray *pcapFilter = [NSArray arrayWithContentsOfFile:path];
    for(NSDictionary *dict in pcapFilter) {
        if([[dict valueForKey:@"pcapFilter"] isEqualToString:key]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark textFiled delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(self.nameTextField.isFirstResponder) {
        [self.pcapFilterTextField becomeFirstResponder];
    }
    else if(self.pcapFilterTextField.isFirstResponder) {
        [self.pcapFilterTextField resignFirstResponder];
    }
    return NO;
}

- (void)pcapFilterTextFieldEditingCganged:(id)sender {
    BOOL ok = NO;
    
    [self.view startCanvasAnimation];
    //check support
    if(self.supportWifi) {
        ok = [IJTPcap testPcapFilter:self.pcapFilterTextField.text interface:@"en0"];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        if(ok) {
            [IJTGradient drawCircle:self.wifiView color:IJTOkColor];
            [dict setValue:@"Yes" forKey:@"ok"];
        }
        else {
            [IJTGradient drawCircle:self.wifiView color:IJTErrorColor];
            [dict setValue:@"No" forKey:@"ok"];
        }
        [IJTFormatUILabel dict:dict
                           key:@"ok"
                        prefix:@"Wi-Fi : "
                         label:self.wifiLabel
                         color:IJTValueColor
                          font:nil];
    }//end if wifi
    if(self.supportCellular) {
        ok = [IJTPcap testPcapFilter:self.pcapFilterTextField.text interface:@"pdp_ip0"];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        if(ok) {
            [IJTGradient drawCircle:self.cellView color:IJTOkColor];
            [dict setValue:@"Yes" forKey:@"ok"];
        }
        else {
            [IJTGradient drawCircle:self.cellView color:IJTErrorColor];
            [dict setValue:@"No" forKey:@"ok"];
        }
        [IJTFormatUILabel dict:dict
                           key:@"ok"
                        prefix:@"Cellular : "
                         label:self.cellLabel
                         color:IJTValueColor
                          font:nil];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    //skip pcap filter text field
    if(textField.tag == pcapFilterTextFieldTag)
        return YES;
    
    // Prevent crashing undo bug – see note below.
    if(range.length + range.location > textField.text.length)
        return NO;
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 40) ? NO : YES;
    /*
     A note on the crashing "undo" bug
     
     As is mentioned in the comments, there is a bug with UITextField that can lead to a crash.
     
     If you paste in to the field, but the paste is prevented by your validation implementation, the paste operation is still recorded in the application's undo buffer. If you then fire an undo (by shaking the device and confirming an Undo), the UITextField will attempt to replace the string it thinks it pasted in to itself with an empty string. This will crash because it never actually pasted the string in to itself. It will try to replace a part of the string that doesn't exist.
     
     Fortunately you can protect the UITextField from killing itself like this. You just need to ensure that the range it proposes to replace does exist within its current string. This is what the initial sanity check above does.
     */
}


#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: case 1: return 44;
        case 2: return 44;
        case 3: return 55;
        default: return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: case 1: return 44;
        case 2: return 44;
        case 3: return 55;
        default: return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

@end
