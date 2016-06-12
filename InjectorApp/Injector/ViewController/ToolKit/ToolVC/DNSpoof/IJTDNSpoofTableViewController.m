//
//  IJTDNSpoofTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/12/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTDNSpoofTableViewController.h"
#import "IJTDNSpoofResultTableViewController.h"
@interface IJTDNSpoofTableViewController ()

@property (nonatomic, strong) UITextView *dnsPatternTextView;
@property (nonatomic, strong) FUIButton *actionButton;
@property (nonatomic, strong) Reachability *wifiReachability;

@end

static NSString *patternPlaceholder =
@"www.google.com A 127.0.0.1\n"
"www.github.com AAAA ::1\n"
"*.facebook.com A 127.0.0.1\n";

@implementation IJTDNSpoofTableViewController

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
    
    self.dnsPatternTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 150)];
    self.dnsPatternTextView.delegate = self;
    self.dnsPatternTextView.returnKeyType = UIReturnKeyDone;
    self.dnsPatternTextView.backgroundColor = [UIColor cloudsColor];
    self.dnsPatternTextView.font = [UIFont systemFontOfSize:18];
    self.dnsPatternTextView.textAlignment = NSTextAlignmentCenter;
    
    self.dnsPatternTextView.keyboardType = UIKeyboardTypeASCIICapable;
    self.dnsPatternTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.dnsPatternTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.dnsPatternTextView.scrollEnabled = YES;
    
    self.actionButton = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
    [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(gotoSpoofVC) forControlEvents:UIControlEventTouchUpInside];
    
    [self.dnsPatternView addSubview:_dnsPatternTextView];
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
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSString *pattern = [user valueForKey:@"DNSpoofPattern"];
    
    if(pattern.length <= 0) {
        self.dnsPatternTextView.text = patternPlaceholder;
        self.dnsPatternTextView.textColor = [[UIColor midnightBlueColor] colorWithAlphaComponent:.6];
    }
    else {
        self.dnsPatternTextView.text = pattern;
        self.dnsPatternTextView.textColor = [UIColor midnightBlueColor];
    }
    
    [self.dnsPatternTextView addObserver:self
                              forKeyPath:@"contentSize"
                                 options:(NSKeyValueObservingOptionNew)
                                 context:NULL];
    [self.dnsPatternTextView layoutIfNeeded];
    [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
    if([IJTNetowrkStatus supportWifi]) {
        self.wifiReachability = [IJTNetowrkStatus wifiReachability];
        [self.wifiReachability startNotifier];
        [self reachabilityChanged:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.dnsPatternTextView removeObserver:self forKeyPath:@"contentSize"];
    if(![self.dnsPatternTextView.text isEqualToString:@""] && ![self.dnsPatternTextView.text isEqualToString:patternPlaceholder]) {
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        [user setObject:self.dnsPatternTextView.text forKey:@"DNSpoofPattern"];
        [user synchronize];
    }//end if
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if([IJTNetowrkStatus supportWifi])
        [self.wifiReachability stopNotifier];
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismissKeyboard {
    if([self.dnsPatternTextView isFirstResponder]) {
        [self.dnsPatternTextView resignFirstResponder];
    }
}

- (void)gotoSpoofVC {
    [self dismissKeyboard];
    
    if(self.dnsPatternTextView.text.length <= 0 || [self.dnsPatternTextView.text isEqualToString:patternPlaceholder]) {
        [self showErrorMessage:@"DNS pattern list is empty."];
        return;
    }
    else if([IJTDNSpoof checkPattern:_dnsPatternTextView.text] <= 0) {
        [self showErrorMessage:@"There is no valid item in the DNS pattern list."];
        return;
    }
    
    IJTDNSpoofResultTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"DNSpoofResultVC"];
    vc.dnsPatternString = self.dnsPatternTextView.text;
    vc.multiToolButton = self.multiToolButton;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"DNSpoof"];
        [self.actionButton setEnabled:NO];
        [self.actionButton setTitle:@"No Wi-Fi Connection" forState:UIControlStateNormal];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.actionButton setEnabled:YES];
        [self.actionButton setTitle:@"Ready" forState:UIControlStateNormal];
    }
}

#pragma mark UITextView

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:patternPlaceholder]) {
        textView.text = @"";
        textView.textColor = [UIColor midnightBlueColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if([textView.text isEqualToString:@""]) {
        textView.text = patternPlaceholder;
        textView.textColor = [[UIColor midnightBlueColor] colorWithAlphaComponent:.6];
    }
    else {
        textView.textColor = [UIColor midnightBlueColor];
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        [user setObject:textView.text forKey:@"DNSpoofPattern"];
        [user synchronize];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}
@end
