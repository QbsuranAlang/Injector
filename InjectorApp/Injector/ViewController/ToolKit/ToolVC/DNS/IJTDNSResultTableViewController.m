//
//  IJTDNSResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/12.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTDNSResultTableViewController.h"
#import "IJTArgTableViewCell.h"
#import "IJTDNSTaskTableViewCell.h"
#import "IJTDNSIPTableViewCell.h"
#import "IJTDNSHostnameTableViewCell.h"

@interface IJTDNSResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *queryButton;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic, strong) NSArray *answerList;
@property (nonatomic, strong) NSThread *requestThread;

@end

@implementation IJTDNSResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 45;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"DNS";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.queryButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"DNSNav.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(query)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_queryButton, nil];
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:self.target forKey:@"Target"];
    [self.taskInfoDict setValue:self.targetType forKey:@"Type"];
    [self.taskInfoDict setValue:self.serverIpAddress forKey:@"Server"];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Target : %@\nServer : %@\nType : %@",
                              self.target, self.serverIpAddress, self.targetType];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)query {
    [self.queryButton setEnabled:NO];
    [self.dismissButton setEnabled:NO];
    self.answerList = [[NSMutableArray alloc] init];
    self.messageLabel.text = @"Querying...";
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    self.requestThread = [[NSThread alloc] initWithTarget:self selector:@selector(queryThread) object:nil];
    [self.requestThread start];
}

- (void)queryThread {
    IJTDNS *dns = [[IJTDNS alloc] init];
    int ret = 0;
    if(self.selectedIndex == 0) {
        ret =
        [dns hostname2IpAddress:self.target
                         server:self.serverIpAddress
                         family:AF_INET
                        timeout:_timeout
                         target:self
                       selector:DNS_CALLBACK_SEL
                         object:_answerList];
    }
    else if(self.selectedIndex == 1) {
        ret =
        [dns hostname2IpAddress:self.target
                         server:self.serverIpAddress
                         family:AF_INET6
                        timeout:_timeout
                         target:self
                       selector:DNS_CALLBACK_SEL
                         object:_answerList];
    }
    else if(self.selectedIndex == 2) {
        ret =
        [dns ipAddress2Hostname:self.target
                         server:self.serverIpAddress
                        timeout:_timeout
                         target:self
                       selector:DNS_PTR_CALLBACK_SEL
                         object:_answerList];
    }
    
    if(ret == -1) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", hstrerror(dns.errorHappened)]];
    }
    else if(ret == -2) {
        self.messageLabel.text = @"No Answer";
        [IJTDispatch dispatch_main:^{
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }];
    }
    else {
        [IJTDispatch dispatch_main:^{
            [self.tableView beginUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }];
    }
    
    [IJTDispatch dispatch_main:^{
        [self.queryButton setEnabled:YES];
        [self.dismissButton setEnabled:YES];
    }];
    
    self.requestThread = nil;
}

DNS_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = (NSMutableArray *)object;
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:ipAddress forKey:@"IpAddress"];
        [dict setValue:hostname forKey:@"Hostname"];
        [list addObject:dict];
        
        NSArray *addArray = @[[NSIndexPath indexPathForRow:list.count - 1 inSection:1]];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

DNS_PTR_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = (NSMutableArray *)object;
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:name forKey:@"Hostname"];
        [dict setValue:resolveHostname forKey:@"ResolveHostname"];
        [list addObject:dict];
        
        NSArray *addArray = @[[NSIndexPath indexPathForRow:list.count - 1 inSection:1]];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:addArray withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.answerList.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    if(section == 0)
        return 1;
    else if(section == 1)
        return self.answerList.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTDNSTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Type"
                         label:cell.typeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Target"
                         label:cell.targetLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Server"
                         label:cell.serverLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        NSDictionary *dict = self.answerList[indexPath.row];
        
        if(self.selectedIndex == 0 || self.selectedIndex == 1) {
            IJTDNSIPTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IPCell" forIndexPath:indexPath];
            
            [IJTFormatUILabel dict:dict
                               key:@"IpAddress"
                             label:cell.ipAddressLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            [IJTFormatUILabel dict:dict
                               key:@"Hostname"
                             label:cell.hostnameLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
                label.font = [UIFont systemFontOfSize:11];
            }];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(self.selectedIndex == 2) {
            IJTDNSHostnameTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HostnameCell" forIndexPath:indexPath];
            
            [IJTFormatUILabel dict:dict
                               key:@"Hostname"
                             label:cell.hostnameLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"ResolveHostname"
                             label:cell.resolveHostnameLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
                label.font = [UIFont systemFontOfSize:11];
            }];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Task Information";
    else if(section == 1) {
        return [NSString stringWithFormat:@"Answer(%lu)", (unsigned long)self.answerList.count];
    }
    return @"";
}

@end
