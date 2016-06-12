//
//  IJTWhoisResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/23.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTWhoisResultTableViewController.h"
#import "IJTwhoisTaskTableViewCell.h"

@interface IJTWhoisResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *whoisButton;
@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (nonatomic, strong) NSThread *requestThread;
@property (nonatomic, strong) UITextView *replyMessageTextView;
@property (nonatomic) CGFloat textViewHeigth;
@property (nonatomic, strong) NSString *replyMessage;

@end

@implementation IJTWhoisResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 200;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"WHOIS";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.whoisButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"WHOISNav.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(who)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_whoisButton, nil];
    
    self.replyMessageTextView = [[UITextView alloc] init];
    self.replyMessageTextView.textColor = IJTValueColor;
    //self.replyMessageTextView.font = [UIFont fontWithName:@"Menlo-Regular" size:14];
    //self.replyMessageTextView.selectable = NO;
    self.replyMessageTextView.scrollEnabled = NO;
    self.replyMessageTextView.editable = NO;
    self.replyMessageTextView.text = @"";
    self.replyMessage = @"";
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:self.target forKey:@"Target"];
    [self.taskInfoDict setValue:self.server forKey:@"Server"];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Target : %@\nServer : %@", self.target, self.server];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)who {
    [self.whoisButton setEnabled:NO];
    [self.dismissButton setEnabled:NO];
    
    self.messageLabel.text = [NSString stringWithFormat:@"Target : %@\nServer : %@", self.target, self.server];
    self.replyMessage = @"";
    [self.tableView reloadData];
    
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        self.requestThread = [[NSThread alloc] initWithTarget:self selector:@selector(whoThread) object:nil];
        [self.requestThread start];
    }];
}

- (void)whoThread {
    IJTWhois *whois = [[IJTWhois alloc] init];
    
    __block int ret =
    [whois whois:_target
     whoisServer:_server
         timeout:_timeout
          target:self
        selector:WHOIS_CALLBACK_SEL
          object:nil];
    
    [IJTDispatch dispatch_main:^{
        if(ret == -2) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", hstrerror(whois.errorCode)]];
        }
        else if(ret == -1) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(whois.errorCode)]];
        }
        else if(ret == 1) {
            self.messageLabel.text = @"Timeout !";
        }
        
        [self.whoisButton setEnabled:YES];
        [self.dismissButton setEnabled:YES];
        [self.tableView reloadData];
    }];
    
    [whois close];
    self.requestThread = nil;
}

WHOIS_CALLBACK_METHOD {
    BOOL printable = NO;
    for(NSUInteger i = 0 ; i < respone.length ; i++) {
        if(isgraph([respone characterAtIndex:i])) {
            printable = YES;
            break;
        }
    }
    if(printable) {
        self.replyMessage = [NSString stringWithString:respone];
    }
    else {
        [IJTDispatch dispatch_main:^{
            self.messageLabel.text = @"Reply no message";
        }];
    }
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
    else if(section == 1) {
        if(self.replyMessage.length <= 0) {
            [self.tableView addSubview:self.messageLabel];
            return 0;
        }
        else {
            [self.messageLabel removeFromSuperview];
            return 1;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTwhoisTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
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
    else if(indexPath.section == 1 && indexPath.row == 0) {
        GET_EMPTY_CELL;
        
        self.replyMessageTextView.text = self.replyMessage;
        
        self.replyMessageTextView.textAlignment = NSTextAlignmentNatural;
        
        self.textViewHeigth = [IJTFormatUITextView
                               textViewHeightForAttributedText:self.replyMessageTextView.attributedText
                               andWidth:SCREEN_WIDTH - 16];
        
        self.replyMessageTextView.frame = CGRectMake(0, 0, SCREEN_WIDTH, self.textViewHeigth);
        
        [self.replyMessageTextView sizeToFit];
        
        [cell.contentView addSubview:self.replyMessageTextView];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0)
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    else if(indexPath.section == 1)
        return self.textViewHeigth;
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Task Information";
    else if(section == 1)
        return @"Reply Message";
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
