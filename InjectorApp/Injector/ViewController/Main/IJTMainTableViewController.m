//
//  IJTMainTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/5/12.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTMainTableViewController.h"
#import "IJTMainTableViewCell.h"
@interface IJTMainTableViewController ()

@property (nonatomic, strong) NSArray *titleArray;
@property (nonatomic, strong) NSArray *iconArray;
@property (nonatomic, strong) NSArray *colorArray;
@property (nonatomic, strong) NSArray *storyBoardIdsArray;


@end

@implementation IJTMainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor clearColor];
    self.titleArray = @[@"FLOW [deprecated]", @"SNIFFER", @"LAN", @"TOOL KIT", @"FIREWALL", @"SUPPORT"];
    self.iconArray = @[[UIImage imageNamed:@"Flow.png"],
                       [UIImage imageNamed:@"Sniffer.png"],
                       [UIImage imageNamed:@"LAN.png"],
                       [UIImage imageNamed:@"ToolKit.png"],
                       [UIImage imageNamed:@"Firewall.png"],
                       [UIImage imageNamed:@"Support.png"]
                       ];
    self.storyBoardIdsArray = @[@"FlowStoryboard", @"SnifferStoryboard", @"LANStoryboard", @"ToolKitStoryboard", @"FirewallStoryboard", @"SupportStoryboard"];
    self.colorArray = @[IJTFlowColor, IJTSnifferColor, IJTLANColor, IJTToolsColor, IJTFirewallColor, IJTSupportColor];
    
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        if([[[NSBundle mainBundle] bundleIdentifier] containsString:@"debug"] || getegid()) {
            FUIAlertView *alert =
            [IJTShowMessage baseAlertViewWithTitle:@"Warning"
                                           message:@"This is debug version.\nSome function may not working."
                                          delegate:nil
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
            [alert show];
        }
    }];
    
    
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *hashCode = [userDefaults valueForKey:@"MoralMode"];
        if(hashCode.length > 0) { //lock
            self.tableView.userInteractionEnabled = NO;
            [self showInputPasswordAlert];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}
#pragma GCC diagnostic pop

- (void)showInputPasswordAlert {
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    
    UITextField *password = [alert addTextField:@"Password"];
    
    password.keyboardType = UIKeyboardTypeASCIICapable;
    password.secureTextEntry = YES;
    
    [alert addButton:@"Confirm" actionBlock:^{
        [password resignFirstResponder];
        
        if(password == nil || password.text.length <= 0) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [self showInputPasswordAlert];
                
                [[IJTShowMessage baseAlertView]
                 showError:@"Error" subTitle:@"Please input a password."
                 closeButtonTitle:@"OK" duration:0];
            }];
        }
        else {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString *hashCode = [userDefaults valueForKey:@"MoralMode"];
            
            NSString *encodePassword = [IJTOpenSSL sha256FromString:password.text];

            if([hashCode isEqualToString:encodePassword]) {
                self.tableView.userInteractionEnabled = YES;
            }
            else {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showInputPasswordAlert];
                    
                    [[IJTShowMessage baseAlertView]
                     showError:@"Error" subTitle:@"Password incorrect."
                     closeButtonTitle:@"OK" duration:0];
                }];
            }
        }
    }];
    
    UIImage *icon = [UIImage imageNamed:@"Lock.png"];
    icon = [icon imageWithColor:IJTWhiteColor];
    
    [alert showCustom:icon
                color:IJTInjectorIconBackgroundColor
                title:@"Locked!"
             subTitle:@"Enter your password to unlock."
     closeButtonTitle:nil
             duration:0];
}

#pragma mark Table view delegate
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return .1f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SCREEN_HEIGHT/6.0f;
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        self.tableView.scrollEnabled = NO;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.titleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTMainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MainFunctionCell" forIndexPath:indexPath];
    
    //title
    cell.titleLabel.text = self.titleArray[indexPath.row];
    cell.titleLabel.textColor = IJTWhiteColor;
    cell.titleLabel.alpha = 0.0f;
    
    //background color
    cell.backgroundColor = self.colorArray[indexPath.row];
    
    //title animation
    CATransition *transition = [CATransition animation];
    transition.duration = 0.8f;
    transition.type = kCATransitionPush;
    if(indexPath.row & 1)
        transition.subtype = kCATransitionFromLeft;
    else
        transition.subtype = kCATransitionFromRight;
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [cell.titleLabel.layer addAnimation:transition forKey:nil];
    
    //fade in
    CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.duration = 0.8f;
    fadeInAnimation.removedOnCompletion = NO;
    fadeInAnimation.fillMode = kCAFillModeForwards;
    fadeInAnimation.fromValue = @(0.0);
    fadeInAnimation.toValue = @(1.0);
    [cell.titleLabel.layer addAnimation:fadeInAnimation forKey:@"fade"];
    
    //icon
    cell.iconImageView.image = self.iconArray[indexPath.row];
    cell.iconImageView.alpha = 0.0f;
    
    //icon animation
    fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [fadeInAnimation setBeginTime:CACurrentMediaTime() + transition.duration + 0.1]; //delay
    fadeInAnimation.duration = 1.0f;
    fadeInAnimation.removedOnCompletion = NO;
    fadeInAnimation.fillMode = kCAFillModeForwards;
    fadeInAnimation.fromValue = @(0.0);
    fadeInAnimation.toValue = @(1.0);
    [cell.iconImageView.layer addAnimation:fadeInAnimation forKey:@"fade"];
    
    //draw text on image view
    /*
    cell.backgroundTitleImageView.image =
    [UIImage drawText:cell.titleLabel.text
              inImage:[UIImage blankImage:cell.backgroundTitleImageView.frame.size]
              atPoint:CGPointMake(0, 0)];
    cell.backgroundTitleImageView.backgroundColor = [UIColor clearColor];
    
    [cell.backgroundTitleImageView blurWithAlpha:0.7f radius:1.0f];

    [cell.backgroundTitleImageView addMotionEffect:[IJTMotionEffect parallax]];
    
    
    [cell layoutIfNeeded];
    
    [IJTFormatUILabel sizeLabel:cell.titleLabel
                         toRect:cell.titleLabel.frame];
     */
    
    [cell layoutIfNeeded];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        FUIAlertView *alert =
        [IJTShowMessage baseAlertViewWithTitle:@"Sorry"
                                       message:@"FLOW is deprecated."
                                      delegate:nil
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
        [alert show];
        return;
    }//end if
    
    FUIButton *buttonF = [FUIButton appearance];
    
    buttonF.buttonColor = self.colorArray[indexPath.row];
    buttonF.shadowColor = [IJTColor darker:self.colorArray[indexPath.row] times:2];
    
    [[UINavigationBar appearance] setBarTintColor:self.colorArray[indexPath.row]];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:self.storyBoardIdsArray[indexPath.row] bundle:nil];
    UINavigationController *controller = [storyboard instantiateInitialViewController];
    controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTMainTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [IJTColor darker:cell.backgroundColor times:1.2];
    //cell.titleLabel.textColor = [IJTColor darker:cell.titleLabel.textColor times:2];
    //cell.iconImageView.image = [cell.iconImageView.image imageWithColor:[IJTColor darker:IJTWhiteColor times:2]];
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTMainTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = self.colorArray[indexPath.row];
    cell.titleLabel.textColor = IJTWhiteColor;
    cell.iconImageView.image = self.iconArray[indexPath.row];
}
@end
