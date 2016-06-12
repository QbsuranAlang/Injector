//
//  IJTBaseViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/8/11.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTBaseViewController.h"

@interface IJTBaseViewController () <JFMinimalNotificationDelegate>

@property (nonatomic, strong) JFMinimalNotification *minimalNotification;

@end

@implementation IJTBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc]
     initWithTitle:@""
     style:UIBarButtonItemStylePlain
     target:nil
     action:nil];
    
    self.stopButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"stop.png"]
                       style:UIBarButtonItemStylePlain
                       target:nil action:nil];
    [self.stopButton setTintColor:IJTStopRecordColor];
    
    self.messageLabel = [[UILabel alloc]
                         initWithFrame:CGRectMake(self.view.center.x - SCREEN_WIDTH/2 + 8,
                                                  SCREEN_HEIGHT/2 - CGRectGetHeight(self.navigationController.navigationBar.frame)/2 - CGRectGetHeight(self.tabBarController.tabBar.frame)/2 - 60,
                                                  SCREEN_WIDTH - 16, 120)];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.textColor = IJTSupportColor;
    self.messageLabel.font = [UIFont boldFlatFontOfSize:30];
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.adjustsFontSizeToFitWidth = YES;
    
    self.tableView.backgroundColor = IJTTableViewBackgroundColor;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.delegate = nil;
}

+ (NSArray *)getSystemToolArray {
    return
    @[@{@"Cache": [@[@"ARP Table", @"Route Table"]
                   sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]},
      @{@"Internet": [@[@"Interface Configure", @"Connection", @"Wi-Fi Scanner"]
                      sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]}];
}

+ (NSArray *)getNetworkToolArray {
    return
    @[@{@"ARP": [@[@"ARP-scan", @"arping", @"arpoison"]
                 sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]},
      @{@"Name Service": [@[@"DNS", @"DNSpoof", @"LLMNR", @"mDNS"]
                          sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]},
      @{@"Troubleshooting": [@[@"ping", @"tracepath"]
                             sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]},
      @{@"Exploit": [@[@"Shellshock"]
                     sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]},
      @{@"SSL and TLS": [@[@"Heartbleed", @"HTTPS Fisher", @"SSL Scan"]
                     sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]},
      @{@"Denial of Service": [@[@"SYN Flood"]
                               sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]},
      @{@"Port Scan": [@[@"ACK Scan", @"Connect Scan", @"FIN Scan", @"Maimon Scan", @"NULL Scan", @"SYN Scan", @"UDP Scan", @"Xmas Scan"]
                       sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]},
      @{@"Prank": [@[@"Wake-on-LAN"]
                   sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]},
      @{@"Other": [@[@"NetBIOS", @"SSDP", @"WHOIS"]
                   sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]}];
}

+ (NSArray *)getLANSupportToolArray {
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self getAllTool:[self getNetworkToolArray]]];
    
    [array removeObject:@"ARP-scan"];
    [array removeObject:@"HTTPS Fisher"];
    return array;
}

+ (NSArray *)getAllTool: (NSArray *)array {
    NSArray *list = [[NSArray alloc] init];
    for(NSDictionary *dict in array) {
        NSString *key = [[dict allKeys] objectAtIndex:0];
        NSArray *items = [dict valueForKey:key];
        list = [list arrayByAddingObjectsFromArray:items];
    }
    return list;
}

+ (NSArray *)getAllToolSectionArray {
    NSArray *system = [self getSystemToolArray];
    NSArray *network = [self getNetworkToolArray];
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    for(NSDictionary *dict in system) {
        NSString *key = [[dict allKeys] objectAtIndex:0];
        [list addObject:key];
    }//end for
    
    for(NSDictionary *dict in network) {
        NSString *key = [[dict allKeys] objectAtIndex:0];
        [list addObject:key];
    }//end for
    
    return list;
}

- (void)minimalNotificationDidDismissNotification:(JFMinimalNotification*)notification {
    if(self.minimalNotification != nil) {
        [self.minimalNotification removeFromSuperview];
        self.minimalNotification = nil;
    }
}

- (void)showInfoMessage: (NSString *)message {
    [self showMessage:message title:@"Information" style:JFMinimalNotificationStyleDefault];
}

- (void)showErrorMessage: (NSString *)message {
    [self showMessage:message title:@"Error" style:JFMinimalNotificationStyleError];
}

- (void)showWarningMessage: (NSString *)message {
    [self showMessage:message title:@"Warning" style:JFMinimalNotificationStyleWarning];
}

- (void)showSuccessMessage: (NSString *)message {
    [self showMessage:message title:@"Success" style:JFMinimalNotificationStyleSuccess];
}

- (void)showMessage: (NSString *)message title: (NSString *)title style: (JFMinimalNotificationStyle)style {
    if(message.length <= 0)
        return;
    @try {
        if(self.minimalNotification != nil) {
            return;
        }
        id topvc = [self topMostController];
        if(![topvc isKindOfClass:[IJTBaseViewController class]]) { //is not my view controller
            [IJTDispatch dispatch_main:^{
                
                [self baseNotificationViewWithTitle:title subTitle:message style:style];
                
                JFMinimalNotification *minimalNotification = self.minimalNotification;
                
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                               initWithTarget:self
                                               action:@selector(dismissNotification)];
                [minimalNotification addGestureRecognizer:tap];
                
                minimalNotification.delegate = self;
                /**
                 * Add the notification to a view
                 */
                if(self.tabBarController.viewControllers.count != 0)
                    [self.tabBarController.view addSubview:minimalNotification];
                else
                    [self.navigationController.view addSubview:minimalNotification];
                [minimalNotification show];
            }];
            return;
        }
        IJTBaseViewController *vc = (IJTBaseViewController *)topvc;
        [IJTDispatch dispatch_main:^{
            if(vc.minimalNotification == nil) {
                [vc baseNotificationViewWithTitle:title
                                           subTitle:message
                                              style:style];
                vc.minimalNotification.delegate = vc;
                /**
                 * Add the notification to a view
                 */
                if(vc.tabBarController.viewControllers.count != 0)
                    [vc.tabBarController.view addSubview:vc.minimalNotification];
                else
                    [vc.navigationController.view addSubview:vc.minimalNotification];
                [vc.minimalNotification show];
            }
        }];
    }
    @catch (NSException *exception) {
    }
}

- (void)dismissNotification {
    [self.minimalNotification dismiss];
}

- (void)dismissShowMessage {
    if(self.minimalNotification != nil) {
        [self.minimalNotification dismiss];
    }
}

- (void)baseNotificationViewWithTitle: (NSString *)title
                             subTitle: (NSString *)subTitle
                                style: (JFMinimalNotificationStyle)style {
    NSTimeInterval dismissDelay = 1 + subTitle.length*0.15;
    if(style == JFMinimalNotificationStyleSuccess)
        dismissDelay = 0.8;
    self.minimalNotification =
    [JFMinimalNotification notificationWithStyle:style
                                           title:title subTitle:subTitle
                                  dismissalDelay:dismissDelay
                                    touchHandler:^{
                                        [self.minimalNotification dismiss];
                                    }];
    /**
     * Set the desired font for the title and sub-title labels
     * Default is System Normal
     */
    UIFont* titleFont = [UIFont fontWithName:@"STHeitiK-Light" size:22];
    [self.minimalNotification setTitleFont:titleFont];
    UIFont* subTitleFont = [UIFont fontWithName:@"STHeitiK-Light" size:16];
    [self.minimalNotification setSubTitleFont:subTitleFont];
    
    /**
     * Set any necessary edge padding as needed
     */
    self.minimalNotification.edgePadding = UIEdgeInsetsMake(0, 0, 10, 0);
}

- (void)showWiFiOnlyNoteWithToolName: (NSString *)toolName {
    if([Reachability reachabilityForLocalWiFi].currentReachabilityStatus == NotReachable) {
        [self showWarningMessage:
         [NSString stringWithFormat:@"%@ must running via Wi-Fi.", toolName]];
    }
}

- (UIViewController*)topMostController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

#pragma mark AMWaveTransition

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC
{
    if (operation != UINavigationControllerOperationNone) {
        // Return your preferred transition operation
        return [AMWaveTransition transitionWithOperation:operation];
    }
    return nil;
}
@end
