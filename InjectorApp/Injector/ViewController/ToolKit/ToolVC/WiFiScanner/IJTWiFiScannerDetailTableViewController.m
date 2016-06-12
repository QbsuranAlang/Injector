//
//  IJTWiFiScannerDetailTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/11/9.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWiFiScannerDetailTableViewController.h"
#import "IJTWiFiScannerFieldTableViewCell.h"
@interface IJTWiFiScannerDetailTableViewController ()

@end

@implementation IJTWiFiScannerDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 75;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.navigationItem.title = [_dict valueForKey:@"SSID"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0) {
        return [[_dict allKeys] count];
    }
    else {
        return [[_recordDict allKeys] count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTWiFiScannerFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FieldCell" forIndexPath:indexPath];
    
    NSDictionary *dict = nil;
    NSArray *keys = nil;
    NSString *key = nil;
    if(indexPath.section == 0) {
        dict = _dict;
    }
    else {
        dict = _recordDict;
    }
    keys = [dict allKeys];
    keys = [keys sortedArrayUsingSelector:@selector(compare:)];
    
    key = [keys objectAtIndex:indexPath.row];
    cell.nameLabel.text = key;
    [IJTFormatUILabel dict:dict
                       key:key
                     label:cell.fieldLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [cell layoutIfNeeded];
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Information";
    }
    else if(section == 1) {
        return @"Record";
    }
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
