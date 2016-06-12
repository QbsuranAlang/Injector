//
//  IJTShellshockResultTableViewController.m
//  
//
//  Created by 聲華 陳 on 2016/1/2.
//
//

#import "IJTShellshockResultTableViewController.h"
#import "IJTShellshockTaskTableViewCell.h"
#import "IJTShellshockReplyTableViewCell.h"
@interface IJTShellshockResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *exploitButton;
@property (nonatomic, strong) NSThread *exploitThread;
@property (nonatomic) BOOL exploiting;
@property (nonatomic, strong) NSMutableArray *shellshockArray;

@end

@implementation IJTShellshockResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Shellshock";
    
    //self size
    self.tableView.estimatedRowHeight = 50;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.exploitButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"ShellshockNav.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(startExploit)];
    
    self.navigationItem.rightBarButtonItem = self.exploitButton;
    
    self.messageLabel.text = [NSString stringWithFormat:@"%@", _urlString];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)startExploit {
    [self.exploitButton setEnabled:NO];
    self.shellshockArray = [[NSMutableArray alloc] init];
    self.exploiting = YES;
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    [self.dismissButton setEnabled:NO];
    
    self.exploitThread = [[NSThread alloc] initWithTarget:self selector:@selector(startExploitThread) object:nil];
    [self.exploitThread start];
}

- (void)startExploitThread {
    IJTShellshock *shellshock = [[IJTShellshock alloc] init];
    NSString *error = @"";
    NSString *replyMessage =
    [shellshock exploitURL:_urlString command:_commands timeout:_timeout error:&error];
    if(error.length > 0) {
        [self showErrorMessage:error];
    }
    else {
        [self.shellshockArray addObject:replyMessage];
    }
    
    self.exploiting = NO;
    [IJTDispatch dispatch_main:^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        [self.exploitButton setEnabled:YES];
        [self.dismissButton setEnabled:YES];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(_shellshockArray.count != 0) {
        [self.messageLabel removeFromSuperview];
    }
    else {
        [self.tableView addSubview:self.messageLabel];
    }
    if(section == 0)
        return 1;
    else if(section == 1)
        return _shellshockArray.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTShellshockTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel text:_urlString label:cell.urlLabel color:IJTValueColor font:[UIFont systemFontOfSize:11]];
        [IJTFormatUILabel text:_commands label:cell.commandLabel color:IJTValueColor font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else {
        IJTShellshockReplyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReplyCell" forIndexPath:indexPath];
        
        NSString *message = _shellshockArray[indexPath.row];
        
        [IJTFormatUILabel text:message label:cell.replyMessageLabel color:IJTValueColor font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Task Information";
    
    if(self.exploiting) {
        if(section == 1)
            return @"Shellshock";
    }
    else {
        if(section == 1)
            return [NSString stringWithFormat:@"Shellshock(%lu)", (unsigned long)_shellshockArray.count];
    }
    
    return @"";
}



@end
