//
//  IJTHeartbleedResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/12/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTHeartbleedResultTableViewController.h"
#import "IJTHeartbleedTaskTableViewCell.h"
#import "IJTHeartbleedErrorTableViewCell.h"
#import "IJTHeartbleedVulnerableTableViewCell.h"
@interface IJTHeartbleedResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *exploitButton;
@property (nonatomic, strong) IJTHeartbleed *heartbleed;
@property (nonatomic, strong) NSThread *exploitThread;
@property (nonatomic) BOOL cancle;
@property (nonatomic) BOOL exploiting;
@property (nonatomic, strong) NSMutableArray *heartbleedArray;
@property (nonatomic) BOOL vulnerable;

@end

@implementation IJTHeartbleedResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Heartbleed";
    
    //self size
    self.tableView.estimatedRowHeight = 1000;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.exploitButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"HeartbleedNav.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(startExploit)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopExploit)];
    
    self.navigationItem.rightBarButtonItem = self.exploitButton;
    
    self.messageLabel.text = [NSString stringWithFormat:@"%@:%d", _target, _port];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)stopExploit {
    if(self.exploitThread != nil) {
        [self.stopButton setEnabled:NO];
        [self.heartbleed stop];
        self.cancle = YES;
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            if(![self.exploitThread isFinished]) {
                while(self.exploitThread) {
                    usleep(100);
                }
            }
            [self.stopButton setEnabled:YES];
        }];
    }
}

#pragma mark heartbleed delegate
- (void)IJTHeartbleedConnectTimeout {
    [self showErrorMessage:@"Timeout"];
}

- (void)IJTHeartbleedCreateSocketFailure:(NSString *)message {
    [self showErrorMessage:message];
    [IJTDispatch dispatch_main:^{
        [self stopExploit];
    }];
}

- (void)IJTHeartbleedResolveHostnameFailure:(NSString *)message {
    [self showErrorMessage:message];
    [IJTDispatch dispatch_main:^{
        [self stopExploit];
    }];
}

- (void)IJTHeartbleedTestHeartbleedFailure:(NSString *)message {
    [self showErrorMessage:message];
    
    [IJTDispatch dispatch_main:^{
        [_heartbleedArray addObject:[self getErrorDictionaryMessage:message]];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_heartbleedArray.count - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

- (NSDictionary *)getErrorDictionaryMessage: (NSString *)message {
    struct timeval time;
    gettimeofday(&time, NULL);
    return @{@"Error": @(YES),
             @"Message": message,
             @"Time": [IJTFormatString formatTimestamp:time secondsPadding:3 decimalPoint:3]};
}

- (void)IJTHeartbleedTestHeartbleedResultVersion:(NSString *)version vulnerable:(BOOL)vulnerable data:(char *)data length:(u_int16_t)length {
    if(vulnerable) {
        self.vulnerable = YES;
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:version forKey:@"Version"];
        [dict setValue:[NSString stringWithFormat:@"%d %@", length, length <= 0 ? @"byte" : @"bytes"] forKey:@"Length"];
        [dict setValue:[self getAcsiiFormat:(u_char *)data length:length maxLength:_displayLength] forKey:@"ASCII"];
        [dict setValue:[self getHexFormat:(u_char *)data length:length maxLength:_displayLength] forKey:@"Hex"];
        [_heartbleedArray addObject:dict];
        
        [IJTDispatch dispatch_main:^{
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_heartbleedArray.count - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }];
    }
}

- (NSString *)getHexFormat: (u_char *)data length: (u_int16_t)length maxLength: (u_int16_t)maxLength {
    NSMutableString *dump = [[NSMutableString alloc] init];
    BOOL isipad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    
    int newline = 8;
    if (isipad)
        newline = 16;
    
    for(u_int16_t i = 0 ; i < maxLength && i < length ; i++) {
        
        if(i > 0 && i % newline == 0)
           [dump appendString:@"\n"];
        else if(i > 0) {
            if(isipad && i % (newline/2) == 0)
                [dump appendString:@"|"];
            else
                [dump appendString:@" "];
        }
        
        [dump appendFormat:@"%02x", data[i]];
    }
    
    return dump;
}

- (NSString *)getAcsiiFormat: (u_char *)data length: (u_int16_t)length maxLength: (u_int16_t)maxLength {
    NSMutableString *dump = [[NSMutableString alloc] init];
    BOOL isipad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    
    int newline = 16;
    if (isipad)
        newline = 32;
    
    for(u_int16_t i = 0 ; i < maxLength && i < length ; i++) {
        
        if(i > 0 && i % newline == 0)
            [dump appendString:@"\n"];
        else if(i > 0) {
            if(isipad && i % (newline/2) == 0)
                [dump appendString:@"|"];
            else
                [dump appendString:@" "];
        }
        
        if(isgraph(data[i])) {
            [dump appendFormat:@"%c", data[i]];
        }
        else {
            [dump appendString:@"."];
        }
    }
    
    return dump;
}

- (void)startExploit {
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    self.heartbleedArray = [[NSMutableArray alloc] init];
    self.cancle = NO;
    self.exploiting = YES;
    self.vulnerable = NO;
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    [self.dismissButton setEnabled:NO];
    
    self.exploitThread = [[NSThread alloc] initWithTarget:self selector:@selector(startExploitThread) object:nil];
    [self.exploitThread start];
}

- (void)startExploitThread {
    _heartbleed = [[IJTHeartbleed alloc] init];
    int ret =
    [_heartbleed setTarget:_target port:_port family:_family timeout:_timeout];
    if(ret == 0) {
        [_heartbleed setDelegate:self];
        [_heartbleed exploit];
        
        if(!_vulnerable) {
            [self showInfoMessage:@"Target seems not vulnerable to heartbleed, try again?"];
        }
    }
    else {
        [self showErrorMessage:@"Host seems refused connect."];
    }
    
    self.exploiting = NO;
    self.exploitThread = nil;
    
    [IJTDispatch dispatch_main:^{
        
        [self.dismissButton setEnabled:YES];
        [self.stopButton setEnabled:YES];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_exploitButton, nil];
        
        [self.tableView reloadData];
        
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(_heartbleedArray.count != 0) {
        [self.messageLabel removeFromSuperview];
    }
    else {
        [self.tableView addSubview:self.messageLabel];
    }
    if(section == 0)
        return 1;
    else if(section == 1)
        return _heartbleedArray.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        IJTHeartbleedTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel text:_target
                         label:cell.hostnameLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel text:[NSString stringWithFormat:@"%d", _port]
                         label:cell.portLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        
        NSDictionary *dict = _heartbleedArray[indexPath.row];
        NSNumber *error = [dict valueForKey:@"Error"];
        if([error boolValue]) {
            IJTHeartbleedErrorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ErrorCell" forIndexPath:indexPath];
            [IJTFormatUILabel dict:dict
                               key:@"Time"
                             label:cell.timeLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            [IJTFormatUILabel dict:dict
                               key:@"Message"
                             label:cell.messageLabel
                             color:IJTErrorMessageColor
                              font:[UIFont systemFontOfSize:11]];
            [cell layoutIfNeeded];
            return cell;
        }
        else {
            IJTHeartbleedVulnerableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VulnerableCell" forIndexPath:indexPath];
            
            [IJTFormatUILabel dict:dict
                               key:@"Version"
                             label:cell.versionLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            [IJTFormatUILabel dict:dict
                               key:@"Length"
                             label:cell.lengthLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            [IJTFormatUILabel dict:dict
                               key:@"ASCII"
                             label:cell.asciiDumpLabel
                             color:IJTValueColor
                              font:[UIFont fontWithName:@"Menlo-Regular" size:14]];
            [IJTFormatUILabel dict:dict
                               key:@"Hex"
                             label:cell.hexDumpLabel
                             color:IJTValueColor
                              font:[UIFont fontWithName:@"Menlo-Regular" size:20]];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Task Information";
    
    if(self.exploiting) {
        if(section == 1)
            return @"Heartbleed";
    }
    else {
        if(section == 1)
            return [NSString stringWithFormat:@"Heartbleed(%lu)", (unsigned long)_heartbleedArray.count];
    }
    
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
