//
//  IJTShellshockTableViewController.m
//  
//
//  Created by 聲華 陳 on 2016/1/2.
//
//

#import "IJTShellshockTableViewController.h"
#import "IJTShellshockResultTableViewController.h"
@interface IJTShellshockTableViewController ()

@property (nonatomic, strong) FUITextField *urlTextField;
@property (nonatomic, strong) UITextView *commandTextView;
@property (nonatomic, strong) FUITextField *timeoutTextField;
@property (nonatomic, strong) UIButton *actionButton;

@end

@implementation IJTShellshockTableViewController

static NSString *commandPlaceholder =
@"Commands in one line\n";

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
    
    self.commandTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 150)];
    self.commandTextView.delegate = self;
    self.commandTextView.returnKeyType = UIReturnKeyDone;
    self.commandTextView.backgroundColor = [UIColor cloudsColor];
    self.commandTextView.font = [UIFont systemFontOfSize:18];
    self.commandTextView.textAlignment = NSTextAlignmentCenter;
    
    self.commandTextView.keyboardType = UIKeyboardTypeASCIICapable;
    self.commandTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.commandTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.commandTextView.scrollEnabled = YES;
    self.commandTextView.text = commandPlaceholder;
    self.commandTextView.textColor = [[UIColor midnightBlueColor] colorWithAlphaComponent:.6];
    self.commandTextView.returnKeyType = UIReturnKeyNext;
    
    _urlTextField = [IJTTextField baseTextFieldWithTarget:self];
    _urlTextField.placeholder = @"URL";
    
    _timeoutTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.timeoutTextField.placeholder = @"Read timeout(ms)";
    self.timeoutTextField.text = @"3000";
    self.timeoutTextField.returnKeyType = UIReturnKeyDone;
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoShockVC) forControlEvents:UIControlEventTouchUpInside];
    
    [self.urlView addSubview:_urlTextField];
    [self.commandView addSubview:_commandTextView];
    [self.timeoutView addSubview:_timeoutTextField];
    [self.actionView addSubview:_actionButton];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.commandTextView addObserver:self
                           forKeyPath:@"contentSize"
                              options:(NSKeyValueObservingOptionNew)
                              context:NULL];
    [self.commandTextView layoutIfNeeded];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.commandTextView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard {
    if([self.urlTextField isFirstResponder]) {
        [self.urlTextField resignFirstResponder];
    }
    else if([self.commandTextView isFirstResponder]) {
        [self.commandTextView resignFirstResponder];
    }
    else if([self.timeoutTextField isFirstResponder]) {
        [self.timeoutTextField resignFirstResponder];
    }
}

- (void)gotoShockVC {
    [self dismissKeyboard];
    
    if(self.urlTextField.text.length <= 0) {
        [self showErrorMessage:@"URL is empty."];
        return;
    }
    else if(![IJTValueChecker checkURL:_urlTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid URL.", self.urlTextField.text]];
        return;
    }
    
    if(self.commandTextView.text.length <= 0 || [self.commandTextView.text isEqualToString:commandPlaceholder]) {
        [self showErrorMessage:@"Command is empty."];
        return;
    }
    
    if(self.timeoutTextField.text.length <= 0) {
        [self showErrorMessage:@"Timeout is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:self.timeoutTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid timeout value.", self.timeoutTextField.text]];
        return;
    }
    
    IJTShellshockResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ShellshockResultVC"];
    vc.urlString = self.urlTextField.text;
    vc.commands = self.commandTextView.text;
    vc.timeout = (u_int32_t)[self.timeoutTextField.text longLongValue];
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark UITextView

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:commandPlaceholder]) {
        textView.text = @"";
        textView.textColor = [UIColor midnightBlueColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if([textView.text isEqualToString:@""]) {
        textView.text = commandPlaceholder;
        textView.textColor = [[UIColor midnightBlueColor] colorWithAlphaComponent:.6];
    }
    else {
        textView.textColor = [UIColor midnightBlueColor];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self adjustTextView:object];
}

- (void)adjustTextView: (UITextView *)textView {
    CGFloat topoffset = ([textView bounds].size.height - [textView contentSize].height * [textView zoomScale])/2.0;
    topoffset = ( topoffset < 0.0 ? 0.0 : topoffset );
    textView.contentOffset = (CGPoint){.x = 0, .y = -topoffset};
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"]) {
        [self.timeoutTextField becomeFirstResponder];
        return NO;
    }
    
    NSUInteger MAX_NUMBER_OF_LINES_ALLOWED = 1;
    
    NSMutableString *t = [NSMutableString stringWithString:
                          self.commandTextView.text];
    [t replaceCharactersInRange: range withString:text];
    
    NSUInteger numberOfLines = 0;
    for (NSUInteger i = 0; i < t.length; i++) {
        if ([[NSCharacterSet newlineCharacterSet]
             characterIsMember: [t characterAtIndex: i]]) {
            numberOfLines++;
        }
    }
    
    return (numberOfLines < MAX_NUMBER_OF_LINES_ALLOWED);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == self.urlTextField) {
        [self.commandTextView becomeFirstResponder];
    }
    else if(textField == self.timeoutTextField) {
        [self.timeoutTextField resignFirstResponder];
    }
    
    return NO;
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
