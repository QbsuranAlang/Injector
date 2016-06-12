//
//  IJTWiFiScannerKnownNetworksTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/11/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWiFiScannerKnownNetworksTableViewController.h"
#import "IJTWiFiScannerKnownNetworkTableViewCell.h"
@interface IJTWiFiScannerKnownNetworksTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *trashButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

@end

@implementation IJTWiFiScannerKnownNetworksTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    if(_knownNetworks.count <= 1)
        self.navigationItem.title = @"Known Network";
    else
        self.navigationItem.title = @"Known Networks";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    //set edit button
    self.trashButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"trash.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(editAction:)];
    
    self.doneButton = [[UIBarButtonItem alloc]
                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                       target:self
                       action:@selector(editAction:)];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_trashButton, nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)editAction: (id)sender {
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    if(button == self.trashButton) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_doneButton, nil];
        self.dismissButton.enabled = NO;
        [self.tableView setEditing:YES animated:YES];
    }
    else if(button == self.doneButton) {
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_trashButton, nil];
        self.dismissButton.enabled = YES;
        [self.tableView setEditing:NO animated:YES];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _knownNetworks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTWiFiScannerKnownNetworkTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KnownCell" forIndexPath:indexPath];
    
    NSDictionary *dict = [_knownNetworks objectAtIndex:indexPath.row];
    
    [IJTFormatUILabel dict:dict
                       key:@"SSID"
                     label:cell.SSIDLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    
    [IJTFormatUILabel dict:dict
                       key:@"BSSID"
                     label:cell.BSSIDLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Password"
                     label:cell.passwordLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    if([[dict valueForKey:@"Password"] length] <= 0) {
        cell.passwordLabel.text = @"";
    }
    
    
    [cell layoutIfNeeded];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = _knownNetworks[indexPath.row];
    
    NSString *password = [dict valueForKey:@"Password"];
    
    if(password.length > 0) {
        [[UIPasteboard generalPasteboard] setString:password];
        [self showInfoMessage:[NSString stringWithFormat:@"\"%@\" is copied to clipboard.", password]];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *dict = _knownNetworks[indexPath.row];
        NSString *SSID = [dict valueForKey:@"SSID"];
        NSString *BSSID = [dict valueForKey:@"BSSID"];
        
        SCLAlertView *alert = [IJTShowMessage baseAlertView];
        
        [alert addButton:@"Delete it" actionBlock:^{
            BOOL success =
            [self.scanner removeKnownNetworkSSID:SSID BSSID:BSSID];
            
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                if(success) {
                    [self showSuccessMessage:@"Success"];
                    
                    [self.knownNetworks removeObjectAtIndex:indexPath.row];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                else {
                    [self showErrorMessage:@"Fail to delete it."];
                }
            }];
            
        }];
        
        [alert showWarning:@"Warning"
                  subTitle:[NSString stringWithFormat:@"Are you sure delete: %@(%@)?", SSID, BSSID]
          closeButtonTitle:@"No"
                  duration:0];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(_knownNetworks.count <= 1)
        return [NSString stringWithFormat:@"Network(%lu)", (unsigned long)_knownNetworks.count];
    else
        return [NSString stringWithFormat:@"Networks(%lu)", (unsigned long)_knownNetworks.count];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"Tap to copy password to clipboard.";
}
@end
