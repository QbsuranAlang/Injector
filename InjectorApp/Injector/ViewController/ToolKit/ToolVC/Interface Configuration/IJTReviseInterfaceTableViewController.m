//
//  IJTReviseInterfaceTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/15.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTReviseInterfaceTableViewController.h"
#import "IJTInterfaceFlagsCollectionViewCell.h"
#define IPHONE_ROW 4.
#define IPAD_ROW 5.
#define COLLECTION_HEIGHT 1.1

@interface IJTReviseInterfaceTableViewController ()

@property (nonatomic, strong) FUITextField *selectInterfaceTextField;
@property (nonatomic, strong) FUITextField *mtuTextField;
@property (nonatomic, strong) NSMutableArray *interfaceList;
@property (nonatomic) int oldMtu;
@property (nonatomic) unsigned short oldFlags;
@property (nonatomic, strong) NSArray *flagsStringArray;
@property (nonatomic, strong) NSArray *flagsValueArray;
@property (nonatomic, strong) NSMutableArray *flagsButtonArray;

@end

@implementation IJTReviseInterfaceTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 180;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"Modify Interface";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.selectInterfaceTextField = [IJTTextField baseTextFieldWithTarget:self];
    
    self.selectInterfaceTextField.placeholder = @"Tap to select an interface";
    
    self.mtuTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.mtuTextField.placeholder = @"MTU";
    self.mtuTextField.returnKeyType = UIReturnKeyDone;
    
    
    [self.selectInterfaceView addSubview:self.selectInterfaceTextField];
    [self.mtuView addSubview:self.mtuTextField];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    [self.modifyButton addTarget:self action:@selector(applySetting) forControlEvents:UIControlEventTouchUpInside];
    
    [self loadInterface];

    [self showInfoMessage:@"Setting some flags will be auto correct when applying."];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self dismissKeyboard];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismissKeyboard {
    if(self.mtuTextField.isFirstResponder) {
        [self.mtuTextField resignFirstResponder];
    }
}

- (void)loadInterface {
    self.interfaceList = [[NSMutableArray alloc] init];
    IJTIfconfig *ifconfig = [[IJTIfconfig alloc] init];
    [ifconfig getAllInterfaceRegisterTarget:self selector:IFCONFIG_SHOW_CALLBACK_SEL object:_interfaceList];
    
    self.flagsStringArray = @[@"UP", @"BROADCAST", @"DEBUG", @"LOOPBACK", @"POINTOPOINT", @"SMART", @"RUNNING", @"NOARP", @"PROMISC", @"ALLMULTI", @"OACTIVE", @"SIMPLEX", @"LINK0", @"LINK1", @"LINK2", @"MULTICAST"];
    self.flagsValueArray = @[@(IJTIfconfigFlagUp), @(IJTIfconfigFlagBroadcast), @(IJTIfconfigFlagDebug), @(IJTIfconfigFlagLoopback), @(IJTIfconfigFlagP2P), @(IJTIfconfigFlagSmart), @(IJTIfconfigFlagRunning), @(IJTIfconfigFlagNoArp), @(IJTIfconfigFlagPromisc), @(IJTIfconfigFlagAllMulticast), @(IJTIfconfigFlagOActive), @(IJTIfconfigFlagSimplex), @(IJTIfconfigFlagLink0), @(IJTIfconfigFlagLink1), @(IJTIfconfigFlagLink2), @(IJTIfconfigFlagMulticast)];
    
    double offset = IPHONE_ROW;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        offset = IPAD_ROW;
    CGFloat cellWidth = SCREEN_WIDTH/offset;
    //circle chart view
    CGFloat r = cellWidth/3.0;
    self.flagsButtonArray = [[NSMutableArray alloc] init];
    for(int i = 0 ; i < self.flagsStringArray.count ; i++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(cellWidth/2-r, cellWidth/2-r - 5, 2*r, 2*r)];
        [button setTitle:@"" forState:UIControlStateNormal];
        button.tag = i;
        [button addTarget:self action:@selector(setFlagButton:) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage imageNamed:@"unchecked.png"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"checked.png"] forState:UIControlStateSelected];
        [self.flagsButtonArray addObject:button];
    }
}

- (void)updateMtuAndFlags {
    NSString *if_name = self.selectInterfaceTextField.text;
    self.oldMtu = 0;
    self.oldFlags = 0;
    self.mtuTextField.text = @"";
    
    IJTIfconfig *ifconfig = [[IJTIfconfig alloc] init];
    if(ifconfig.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(ifconfig.errorCode)]];
    }
    else {
        int mtu = [ifconfig getMtuAtInterface:if_name];
        if(ifconfig.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(ifconfig.errorCode)]];
        }
        else {
            self.mtuTextField.text = [NSString stringWithFormat:@"%d", mtu];
            self.oldMtu = mtu;
        }
        
        self.oldFlags = [ifconfig getFlagAtInterface:if_name];
        if(ifconfig.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(ifconfig.errorCode)]];
            self.oldFlags = 0;
        }
    }
}

- (void)applySetting {
    NSString *interface = self.selectInterfaceTextField.text;
    NSString *mtu = self.mtuTextField.text;
    IJTIfconfigFlag flags = 0;
    NSString *mtuString = @"";
    NSString *flagsString = @"";
    BOOL updatedMTU = NO, updatedFlags = NO;
    
    if(interface.length <= 0) {
        [self showErrorMessage:@"Please select a network interface."];
        return;
    }
    if(![IJTNetowrkStatus checkInterface:interface]) {
        [self showErrorMessage:[NSString stringWithFormat:@"%@ doesn't exsit.", interface]];
        return;
    }
    
    if(![IJTValueChecker checkAllDigit:mtu]) {
        [self showErrorMessage:[NSString stringWithFormat:@"%@ is not a valid MTU size.", mtu]];
        return;
    }
    
    IJTIfconfig *ifconfig = [[IJTIfconfig alloc] init];
    if(ifconfig.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(ifconfig.errorCode)]];
        return;
    }
    
    if(self.oldMtu != [mtu intValue]) {
        [ifconfig setMtuAtInterface:interface mtu:[mtu intValue]];
        if(ifconfig.errorHappened) {
            mtuString = [NSString stringWithFormat:@"MTU: %s.", strerror(ifconfig.errorCode)];
        }
        else {
            updatedMTU = YES;
        }
    }
    
    for(int i = 0 ; i < self.flagsButtonArray.count ; i++) {
        UIButton *button = self.flagsButtonArray[i];
        if(button.selected) {
            NSNumber *bits = self.flagsValueArray[i];
            flags |= [bits unsignedShortValue];
        }
    }
    
    if(self.oldFlags != flags) {
        [ifconfig setFlagAtInterface:interface flags:flags];
        if(ifconfig.errorHappened) {
            flagsString = [NSString stringWithFormat:@"Flags: %s.", strerror(ifconfig.errorCode)];
        }
        else {
            updatedFlags = YES;
        }
    }
    
    if(mtuString.length > 0 && flagsString.length > 0) {
        [self showErrorMessage:[NSString stringWithFormat:@"%@\n%@", mtuString, flagsString]];
        return;
    }
    else if(mtuString.length > 0) {
        if(updatedFlags) {
            [self showWarningMessage:[NSString stringWithFormat:@"%@\nFlags: Success.", mtuString]];
        }
        else {
            [self showErrorMessage:mtuString];
            return;
        }
    }
    else if(flagsString.length > 0) {
        if(updatedMTU) {
            [self showWarningMessage:[NSString stringWithFormat:@"MTU: Success.\n%@", flagsString]];
        }
        else {
            [self showErrorMessage:flagsString];
            return;
        }
    }
    else if(!updatedMTU && !updatedFlags) {
        [self showInfoMessage:@"Nothing to do."];
        return;
    }
    else {
        [self showSuccessMessage:@"Success"];
    
        [self loadInterface];
        [self updateMtuAndFlags];
        [self.tableView reloadData];
        [self.collectionView reloadData];
        [self.delegate callback];
    }
}

#pragma mark textField
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    if(textField == self.selectInterfaceTextField) {
        [self dismissKeyboard];
        CZPickerView *picker = [IJTPickerView pickerViewTitle:@"Interfaces" target:self];
        [picker show];
        return NO;
    }
    return YES;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.mtuTextField) {
        allowString = @"1234567890\b";
    }
    else
        return YES;
    
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(self.mtuTextField.isFirstResponder) {
        [self.mtuTextField resignFirstResponder];
    }
    return NO;
}

#pragma mark select interface

IFCONFIG_SHOW_CALLBACK_METHOD {
    NSMutableArray *list = (NSMutableArray *)object;
    for(NSString *if_name in list) {
        if([if_name isEqualToString:interface]) {
            return;
        }
    }
    [list addObject:interface];
}

- (NSAttributedString *)czpickerView:(CZPickerView *)pickerView attributedTitleForRow:(NSInteger)row {
    
    NSMutableParagraphStyle *mutParaStyle = [[NSMutableParagraphStyle alloc] init];
    [mutParaStyle setAlignment:NSTextAlignmentCenter];
    
    NSMutableDictionary *attrsDictionary = [[NSMutableDictionary alloc] init];
    [attrsDictionary setObject:[UIFont systemFontOfSize:17] forKey:NSFontAttributeName];
    [attrsDictionary setObject:mutParaStyle forKey:NSParagraphStyleAttributeName];
    
    return [[NSMutableAttributedString alloc]
            initWithString:self.interfaceList[row] attributes:attrsDictionary];
}

- (NSInteger)numberOfRowsInPickerView:(CZPickerView *)pickerView{
    return self.interfaceList.count;
}

#pragma mark picker view
- (void)czpickerView:(CZPickerView *)pickerView didConfirmWithItemAtRow:(NSInteger)row {
    NSString *if_name = self.interfaceList[row];
    self.selectInterfaceTextField.text = if_name;
    
    [self updateMtuAndFlags];
    
    [self loadInterface];
    [self.tableView reloadData];
    [self.collectionView reloadData];
}

- (void)czpickerViewDidClickCancelButton:(CZPickerView *)pickerView {
    if(self.selectInterfaceTextField.text.length <= 0) {
        self.oldMtu = 0;
        self.oldFlags = 0;
        self.mtuTextField.text = @"";
        [self loadInterface];
        [self.tableView reloadData];
        [self.collectionView reloadData];
    }
}

- (void)setFlagButton: (id)sender {
    UIButton *button = sender;
    button.selected = !button.selected;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if(self.selectInterfaceTextField.text.length <= 0)
        return 1;
    else
        return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 2) {
        double offset = IPHONE_ROW;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            offset = IPAD_ROW;
        double columns = ceil(self.flagsStringArray.count/offset);
        NSUInteger width = SCREEN_WIDTH/offset;
        return width*COLLECTION_HEIGHT*columns;
    }
    else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

#pragma mark colletion view
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.flagsStringArray.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IJTInterfaceFlagsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FlagsCell" forIndexPath:indexPath];
    
    UILabel *flagLabel = (UILabel *)[cell viewWithTag:101];
    [IJTFormatUILabel text:self.flagsStringArray[indexPath.row]
                     label:flagLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    flagLabel.adjustsFontSizeToFitWidth = YES;
    
    UIView *buttonView = (UIView *)[cell viewWithTag:100];
    
    [[buttonView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UIButton *flagButton = self.flagsButtonArray[indexPath.row];
    NSNumber *flag = self.flagsValueArray[indexPath.row];
    
    if(_oldFlags & [flag unsignedShortValue]) {
        flagButton.selected = YES;
    }
    else {
        flagButton.selected = NO;
    }
    [buttonView addSubview:flagButton];
    
    [cell layoutIfNeeded];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    double offset = IPHONE_ROW;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        offset = IPAD_ROW;
    NSUInteger width = SCREEN_WIDTH/offset;
    return CGSizeMake(width, width*COLLECTION_HEIGHT);
}

@end
