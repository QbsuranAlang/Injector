//
//  IJTRuleTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/6/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTRuleTableViewController.h"
#import "IJTAllowBlockListTableViewCell.h"
#import "IJTLastBackupTableViewCell.h"
@interface IJTRuleTableViewController ()

@property (nonatomic, strong) NSMutableDictionary *dict;

@end

@implementation IJTRuleTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"down.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.dict = [[NSMutableDictionary alloc] init];
    [self.dict setValue:[IJTFormatString formatTime:self.lastTime] forKey:@"Time"];
    [self.dict setValue:[NSNumber numberWithUnsignedInteger:self.ruleList.count] forKey:@"Count"];
    
    if(self.ruleList.count <= 1) {
        self.navigationItem.title = @"Backup Item";
    }
    else
        self.navigationItem.title = @"Backup Items";
    
    //sort by add time, aes
    for(int i = 0 ; i < self.ruleList.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSDictionary *dict1 = self.ruleList[i];
            NSDictionary *dict2 = self.ruleList[j];
            NSString *time1 = [dict1 valueForKey:@"AddTime"];
            NSString *time2 = [dict2 valueForKey:@"AddTime"];
            
            if([time1 longLongValue] > [time2 longLongValue]) {
                [self.ruleList exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 1;

    return self.ruleList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Backup Information";
    
    return [NSString stringWithFormat:@"Item Detail(%lu)", (unsigned long)_ruleList.count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        IJTLastBackupTableViewCell *cell = (IJTLastBackupTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"BackupCell" forIndexPath:indexPath];
        [IJTFormatUILabel dict:self.dict
                           key:@"Time"
                         label:cell.timeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:self.dict
                           key:@"Count"
                         label:cell.itemsLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else {
        IJTAllowBlockListTableViewCell *cell = (IJTAllowBlockListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"RuleCell" forIndexPath:indexPath];
        
        // Configure the cell...
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.ruleList[indexPath.row]];
        [IJTFormatUILabel dict:dict
                           key:@"IpAddress"
                         label:cell.ipAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];

        NSNumber *time = [dict valueForKey:@"AddTime"];
        NSString *timestring = [IJTFormatString formatTime:[time longValue]];
        [dict setValue:timestring forKey:@"AddTimeString"];
        [IJTFormatUILabel dict:dict
                           key:@"AddTimeString"
                         label:cell.addTimeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        NSString *opstring = @"";
        if(self.op == IJTFirewallOperatorAllow) {
            opstring = @"Allow";
        }
        else if(self.op == IJTFirewallOperatorBlock) {
            opstring = @"Block";
        }
        [IJTFormatUILabel dict:dict
                           key:@"DisplayName"
                        prefix:[NSString stringWithFormat:@"App When You %@ : ", opstring]
                         label:cell.appLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        
        
        NSNumber *enable = [dict valueForKey:@"Enable"];
        if([enable boolValue]) {
            [IJTFormatUILabel text:@"Yes"
                             label:cell.enableLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
        }
        else {
            [IJTFormatUILabel text:@"No"
                             label:cell.enableLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
        }
        
                                 
        cell.ipAddress = [dict valueForKey:@"IpAddress"];
        cell.lastTime = [time longValue];
        cell.appName = [dict valueForKey:@"DisplayName"];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell layoutIfNeeded];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 0)
        return;
    IJTAllowBlockListTableViewCell *cell = (IJTAllowBlockListTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    
    [alert addButton:@"Yes" actionBlock:^{
        
        if(self.op == IJTFirewallOperatorAllow) {
            if(![IJTValueChecker checkIpv4Address:cell.ipAddress]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", cell.ipAddress]];
                }];
                return;
            }
            if([IJTAllowAndBlock exsitInAllow:cell.ipAddress]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is already exsit.", cell.ipAddress]];
                }];
                return;
            }
            if([IJTAllowAndBlock exsitInBlock:cell.ipAddress]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is already exsit in block list.", cell.ipAddress]];
                }];
                return;
            }
            
            [IJTAllowAndBlock newAllow:cell.ipAddress
                                  time:cell.lastTime
                           displayName:cell.appName
                                enable:cell.enable];
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [self showSuccessMessage:@"Success"];
            }];
        }
        else if(self.op == IJTFirewallOperatorBlock) {
            if(![IJTValueChecker checkIpv4Address:cell.ipAddress]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid IP address.", cell.ipAddress]];
                }];
                return;
            }
            if([IJTAllowAndBlock exsitInBlock:cell.ipAddress]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is already exsit.", cell.ipAddress]];
                }];
                return;
            }
            if([IJTAllowAndBlock exsitInAllow:cell.ipAddress]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is already exsit in allow list.", cell.ipAddress]];
                }];
                return;
            }
            
            if([IJTAllowAndBlock newBlock:cell.ipAddress
                                     time:cell.lastTime
                              displayName:cell.appName
                                   enable:cell.enable
                                   target:self]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showSuccessMessage:@"Success"];
                }];
            }//end if success
        }//end if block
    }];
    
    [alert showInfo:@"Restore one"
           subTitle:[NSString stringWithFormat:@"Do you want store %@?", cell.ipAddress]
   closeButtonTitle:@"No"
           duration:0];
}

- (NSMutableArray *)loadFromFile {
    NSMutableArray *list = [NSMutableArray arrayWithContentsOfFile:[self filename]];
    
    if(list == nil) {
        list = [[NSMutableArray alloc] init];
        [list writeToFile:[self filename] atomically:YES];
    }
    
    //sort by add time, aes
    for(int i = 0 ; i < list.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSDictionary *dict1 = list[i];
            NSDictionary *dict2 = list[j];
            NSString *time1 = [dict1 valueForKey:@"AddTime"];
            NSString *time2 = [dict2 valueForKey:@"AddTime"];
            
            if([time1 longLongValue] > [time2 longLongValue]) {
                [list exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }
    return list;
}

- (NSString *)filename {
    if(self.op == IJTFirewallOperatorAllow)
        return [IJTAllowAndBlock allowFilename];
    else if(self.op == IJTFirewallOperatorBlock)
        return [IJTAllowAndBlock blockFilename];
    else
        return @"";
}

@end
