//
//  IJTFilterInformationViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTFilterInformationViewController.h"
@interface IJTFilterInformationViewController ()

@end

@implementation IJTFilterInformationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"How to Custom Your Filter";
    [self.webView loadRequest:[IJTWeb fileRequest:@"Filtering_expression_syntax.html" ofType:nil]];
    //開啟縮放
    self.webView.scalesPageToFit = YES;
    self.webView.scrollView.bounces = YES;
    self.webView.scrollView.showsVerticalScrollIndicator = YES;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithImage:[UIImage imageNamed:@"left.png"]
                                   style:UIBarButtonItemStylePlain
                                   target:self action:@selector(back:)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:backButton, nil];
}

- (void)back: (id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [KVNProgress showWithStatus:@"Loading..."];
    webView.dataDetectorTypes = UIDataDetectorTypeNone;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [KVNProgress dismiss];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    //NSLog(@"load with error %@", error.localizedDescription);
    [KVNProgress dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    if(navigationType == UIWebViewNavigationTypeLinkClicked) {
        return NO;
    }
    return YES;
}

@end
