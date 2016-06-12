//
//  IJTSupportTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTSupportTableViewController.h"
#import "IJTSupportSocialTableViewCell.h"
#import "IJTSupportMaintainerTableViewCell.h"
#import "IJTSupportFieldTableViewCell.h"
#import "IJTSupportSwitchTableViewCell.h"
@interface IJTSupportTableViewController ()

@property (nonatomic, strong) FUIButton *facebookButton;
@property (nonatomic, strong) FUIButton *googleButton;
@property (nonatomic, strong) NSThread *facebookThread;
@property (nonatomic, strong) NSThread *googleThread;
@property (nonatomic, strong) NSMutableArray *imageArray;
@property (nonatomic, strong) NSMutableArray *nameArray;
@property (nonatomic, strong) NSThread *facebookInfoThread;
@property (nonatomic, strong) NSMutableArray *emailArray;
@property (nonatomic, strong) NSMutableDictionary *appInfoDict;
@property (nonatomic, strong) SSARefreshControl *refreshView;

@end

@implementation IJTSupportTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"close.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.facebookButton = [[FUIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 55 - 16)];
    self.googleButton = [[FUIButton alloc] initWithFrame:CGRectMake(0, 0, 120, 55 - 16)];
    self.facebookButton.tag = IJTStatusUserTypeFacebook;
    self.googleButton.tag = IJTStatusUserTypeGoogle;
    
    //app information
    self.appInfoDict = [[NSMutableDictionary alloc] init];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *appDisplayName = [infoDictionary objectForKey:@"CFBundleName"];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    
    [self.appInfoDict setValue:appDisplayName forKey:@"AppName"];
    [self.appInfoDict setValue:majorVersion forKey:@"Version"];
    
    NSString *compileDate = [NSString stringWithUTF8String:__DATE__];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"MMM d y"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    NSDate *aDate = [df dateFromString:compileDate];
    [df setDateFormat:@"y/MM/dd"];
    [self.appInfoDict setValue:[df stringFromDate:aDate] forKey:@"BuildDate"];
    
    //social media
    [self getFacebookStatus];
    [self getGoogleStatus];
    
    self.imageArray = [[NSMutableArray alloc] init];
    self.nameArray = [[NSMutableArray alloc] init];
    self.emailArray = [[NSMutableArray alloc] init];
    self.facebookInfoThread = [[NSThread alloc] initWithTarget:self selector:@selector(retrieveFacebookInfoThread) object:nil];
    [self.facebookInfoThread start];
    
    //refresh control
    self.refreshView = [[SSARefreshControl alloc] initWithScrollView:self.tableView andRefreshViewLayerType:SSARefreshViewLayerTypeOnScrollView];
    self.refreshView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)getFacebookStatus {
    [self.facebookButton setTitle:@"Waiting..." forState:UIControlStateNormal];
    self.facebookThread = [[NSThread alloc] initWithTarget:self selector:@selector(getFacebookStatusThread) object:nil];
    [self.facebookThread start];
}

- (void)getGoogleStatus {
    [self.googleButton setTitle:@"Waiting..." forState:UIControlStateNormal];
    self.googleThread = [[NSThread alloc] initWithTarget:self selector:@selector(getGoogleStatusThread) object:nil];
    [self.googleThread start];
}

- (void)getFacebookStatusThread {
    [IJTHTTP retrieveFrom:@"GetConnectionStatus.php"
                     post:[NSString stringWithFormat:@"SerialNumber=%@&UserType=%ld", [IJTID serialNumber], (long)IJTStatusUserTypeFacebook]
                  timeout:5
                    block:^(NSData *data){
                        NSString *facebook = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                        
                        if([facebook integerValue] != IJTStatusServerDataExsit && [facebook integerValue] != IJTStatusServerDataNotExsit) {
                            [IJTDispatch dispatch_main:^{
                                [self.facebookButton setTitle:@"Try again" forState:UIControlStateNormal];
                                [self showErrorMessage:@"Fail to retrieve user data."];
                                [self.facebookButton addTarget:self action:@selector(getFacebookStatus) forControlEvents:UIControlEventTouchUpInside];
                            }];
                        }
                        else {
                            [IJTDispatch dispatch_main:^{
                                [self.facebookButton removeTarget:self action:@selector(getFacebookStatus) forControlEvents:UIControlEventTouchUpInside];
                                if([facebook integerValue] == IJTStatusServerDataExsit) {
                                    [self.facebookButton setTitle:@"Disconnect" forState:UIControlStateNormal];
                                }
                                else {
                                    [self.facebookButton setTitle:@"Connect" forState:UIControlStateNormal];
                                }
                                [self.facebookButton addTarget:self action:@selector(connectToSocial:) forControlEvents:UIControlEventTouchUpInside];
                            }];
                        }
                    }];
}

- (void)getGoogleStatusThread {
    while([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        [self.googleButton removeTarget:self action:@selector(connectToSocial:) forControlEvents:UIControlEventTouchUpInside];
        [NSThread sleepForTimeInterval:0.1];
    }
    [IJTHTTP retrieveFrom:@"GetConnectionStatus.php"
                     post:[NSString stringWithFormat:@"SerialNumber=%@&UserType=%ld", [IJTID serialNumber], (long)IJTStatusUserTypeGoogle]
                  timeout:5
                    block:^(NSData *data){
                        NSString *google = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                        if([google integerValue] != IJTStatusServerDataExsit && [google integerValue] != IJTStatusServerDataNotExsit) {
                            [IJTDispatch dispatch_main:^{
                                [self.googleButton setTitle:@"Try again" forState:UIControlStateNormal];
                                [self showErrorMessage:@"Fail to retrieve user data."];
                                [self.googleButton addTarget:self action:@selector(getGoogleStatus) forControlEvents:UIControlEventTouchUpInside];
                            }];
                        }
                        else {
                            [IJTDispatch dispatch_main:^{
                                [self.googleButton removeTarget:self action:@selector(getGoogleStatus) forControlEvents:UIControlEventTouchUpInside];
                                if([google integerValue] == IJTStatusServerDataExsit) {
                                    [IJTHTTP retrieveFrom:@"UpdateSystemVersion.php"
                                                     post:[NSString stringWithFormat:@"SerialNumber=%@&SystemVersion=%@", [IJTID serialNumber], [ALHardware systemVersion]]
                                                  timeout:5
                                                    block:^(NSData *data){}];
                                    [self.googleButton setTitle:@"Disconnect" forState:UIControlStateNormal];
                                }
                                else {
                                    [self.googleButton setTitle:@"Connect" forState:UIControlStateNormal];
                                }
                                [self.googleButton addTarget:self action:@selector(connectToSocial:) forControlEvents:UIControlEventTouchUpInside];
                            }];
                        }
                    }];
}

- (void)connectToSocial: (id)sender {
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    __block FUIButton *button = sender;
    
    [alert addButton:@"Yes" actionBlock:^{
        [button setEnabled:NO];
        
        if(button.tag == IJTStatusUserTypeFacebook) {
            self.facebookThread = [[NSThread alloc] initWithTarget:self selector:@selector(connectToSocialThread:) object:sender];
            [self.facebookThread start];
        }
        else if(button.tag == IJTStatusUserTypeGoogle) {
            self.googleThread = [[NSThread alloc] initWithTarget:self selector:@selector(connectToSocialThread:) object:sender];
            [self.googleThread start];
        }
    }];
    
    if([button.titleLabel.text isEqualToString:@"Connect"]) {
        [alert showInfo:@"Connect"
               subTitle:@"Do you want to connect your social media?"
       closeButtonTitle:@"No"
               duration:0];
    }
    else {
        [alert showInfo:@"Disconnect"
               subTitle:@"Do you want to disconnect your social media?"
       closeButtonTitle:@"No"
               duration:0];
    }
}

- (void)connectToSocialThread: (id)object {
    FUIButton *button = object;
    IJTStatusUserType type = 0;
    BOOL connect = NO;
    
    if([button.titleLabel.text isEqualToString:@"Disconnect"]) {
        connect = NO;
    }
    else {
        connect = YES;
    }
    if(button.tag == IJTStatusUserTypeFacebook) {
        type = IJTStatusUserTypeFacebook;
    }
    else if(button.tag == IJTStatusUserTypeGoogle) {
        type = IJTStatusUserTypeGoogle;
    }
    else {
        return;
    }
    
    if(connect) { //
        if(type == IJTStatusUserTypeFacebook) {
            [self facebookLoginAndPost];
        }
        else if(type == IJTStatusUserTypeGoogle) {
            [self googleLoginAndPost];
        }
    }
    else { //disconnect
        
        [IJTHTTP retrieveFrom:@"DisconnectUser.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@&UserType=%ld", [IJTID serialNumber], (long)type]
                      timeout:5
                        block:^(NSData *data){
                            NSString *result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            if([result integerValue] == IJTStatusServerSuccess) {
                                [IJTDispatch dispatch_main:^{
                                    [self showSuccessMessage:@"Success"];
                                    [button setEnabled:YES];
                                    [button setTitle:@"Connect" forState:UIControlStateNormal];
                                }];
                            }
                            else {
                                [IJTDispatch dispatch_main:^{
                                    [self showErrorMessage:@"Fail to disconnect."];
                                    [button setEnabled:YES];
                                }];
                            }
                        
                        }];
    }
}

- (void)facebookLoginAndPost {
    __block FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login
     logInWithReadPermissions: @[@"public_profile", @"email", @"user_friends"]
     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
         if (error) {
             NSLog(@"Process error");
             [IJTDispatch dispatch_main:^{
                 [self.facebookButton setEnabled:YES];
                 [self showErrorMessage:@"Fail to connect."];
             }];
         } else if (result.isCancelled) {
             NSLog(@"Cancelled");
             [IJTDispatch dispatch_main:^{
                 [self.facebookButton setEnabled:YES];
                 [self showErrorMessage:@"Fail to connect."];
             }];
         } else { //login
             if ([FBSDKAccessToken currentAccessToken]) {
                 [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name, email"}]
                  startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                      if (!error) {
                          NSString *email = result[@"email"];
                          NSString *user_id = result[@"id"];
                          NSString *platform = [UIDeviceHardware platformString];
                          NSString *serialNumber = [IJTID serialNumber];
                          IJTStatusUserType user_type = IJTStatusUserTypeFacebook;
                          
                          [IJTHTTP retrieveFrom:@"ConnectUser.php"
                                           post:[NSString stringWithFormat:@"SerialNumber=%@&PlatformType=%@&User-ID=%@&UserType=%ld&Email=%@", serialNumber, platform, user_id, (long)user_type, email]
                                        timeout:5
                                          block:^(NSData *data){
                                              
                                              NSString *result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                                              if([result integerValue] == IJTStatusServerSuccess) {
                                                  [IJTHTTP retrieveFrom:@"UpdateSystemVersion.php"
                                                                   post:[NSString stringWithFormat:@"SerialNumber=%@&SystemVersion=%@", [IJTID serialNumber], [ALHardware systemVersion]]
                                                                timeout:5
                                                                  block:^(NSData *data){}];
                                                  [IJTDispatch dispatch_main:^{
                                                      [self.facebookButton setTitle:@"Disconnect" forState:UIControlStateNormal];
                                                      [self showSuccessMessage:@"Success"];
                                                  }];
                                              }
                                              else {
                                                  [IJTDispatch dispatch_main:^{
                                                      [self showErrorMessage:@"Fail to connect."];
                                                  }];
                                              }
                                          }];
                          
                          
                      }//end if sucess get user data
                      else {
                          [IJTDispatch dispatch_main:^{
                              [self showErrorMessage:@"Fail to connect."];
                          }];
                      }
                      
                      [login logOut];
                      [FBSDKAccessToken setCurrentAccessToken:nil];
                      [self.facebookButton setEnabled:YES];
                  }];//end handler
             }//end current access token is got
             else {
                 [IJTDispatch dispatch_main:^{
                     [self showErrorMessage:@"Fail to connect."];
                     [self.facebookButton setEnabled:YES];
                 }];
                 [login logOut];
                 [FBSDKAccessToken setCurrentAccessToken:nil];
             }
         }//end if login
     }];//end handler
}

- (void)googleLoginAndPost {
    NSString *security_token = [IJTID serialNumber];
    
    NSString *url =
    [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?client_id=694308736502-6lir3lh02ni1akliqpbj9fpufi17prpq.apps.googleusercontent.com&response_type=code&scope=email&redirect_uri=https://nrl.cce.mcu.edu.tw/injector/dbAccess/GoogleLogin.php&state=security_token%%3D%@", security_token];
    
    [IJTDispatch dispatch_main:^{
        [self.googleButton setEnabled:YES];
    }];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        [self getGoogleStatus];
    }];
}

- (void)retrieveFacebookInfoThread {
    [self getProfileImage:@"941133985944655"
                     name:@"江清泉"
                    email:@"ccchiang@mail.mcu.edu.tw"
                indexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    [self getProfileImage:@"790905524285247"
                     name:@"陳聲華"
                    email:@"jr89197@hotmail.com"
                indexPath:[NSIndexPath indexPathForRow:0 inSection:3]];
    [self getProfileImage:@"100001710330327"
                     name:@"萬伃倫"
                    email:@"melody70161@gmail.com"
                indexPath:[NSIndexPath indexPathForRow:0 inSection:4]];
    [self getProfileImage:@"1116585951704210"
                     name:@"魏旻柔"
                    email:@"asdfff32@yahoo.com.tw"
                indexPath:[NSIndexPath indexPathForRow:0 inSection:5]];
    [self getProfileImage:@"696499450435486"
                     name:@"鍾佳軒"
                    email:@"jeffa01160714@gmail.com"
                indexPath:[NSIndexPath indexPathForRow:1 inSection:5]];
}

- (void)getProfileImage: (NSString *)user_id name: (NSString *)name email: (NSString *)email indexPath: (NSIndexPath *)indexPath {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=104&height=104", user_id]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:data];
    if(image) {
        //image = [IJTUIImage cropImage:image];
        [self.imageArray addObject:image];
    }
    else {
        [self.imageArray addObject:[UIImage imageNamed:@"Facebook.png"]];
    }
    
    [self.nameArray addObject:name];
    [self.emailArray addObject:email];
    [IJTDispatch dispatch_main:^{
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

#pragma mark sysctl
- (void)sysctlSwitchChange:(id)sender {
    FUISwitch *sysctlSwitch = sender;
    
    __block SCLAlertView *alert = [IJTShowMessage baseAlertView];
    __block NSArray *list = list = [IJTSysctl suggestSettings];
    __block BOOL setNewValue = sysctlSwitch.isOn;
    
    NSString *message = @"";
    
    for(NSString *name in list) {
        int oldValue = [IJTSysctl sysctlValueByname:name];
        if(oldValue == -1)
            continue;
        if(setNewValue) {
            message = [message stringByAppendingString:[NSString stringWithFormat:@"\n%@ : %d -> %d",
                                                        name, oldValue, [IJTSysctl suggestValue:name]]];
        }
        else {
            message = [message stringByAppendingString:[NSString stringWithFormat:@"\n%@ : %d -> %d",
                                                        name, oldValue, [IJTSysctl oldValue:name]]];
        }
    }
    
    [alert addButton:@"Yes" actionBlock:^{
    
        BOOL fail = NO;
        for(NSString *name in list) {
            if(setNewValue) {
                int result = [IJTSysctl sysctlSetValue:[IJTSysctl suggestValue:name] name:name];
                if(result == -1)
                    fail = YES;
            }
            else {
                int result = [IJTSysctl sysctlSetValue:[IJTSysctl oldValue:name] name:name];
                if(result == -1)
                    fail = YES;
            }
        }
        
        if(fail) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(EPERM)]];
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [sysctlSwitch setOn:!sysctlSwitch.isOn animated:YES];
            }];
        }
        else {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                [self showSuccessMessage:@"Success"];
            }];
        }
    
    }];
    
    [alert addButton:@"No" actionBlock:^{
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [sysctlSwitch setOn:!sysctlSwitch.isOn animated:YES];
        }];
    }];
    
    UIImage *icon = [UIImage imageNamed:@"System Control.png"];
    icon = [icon imageWithColor:IJTWhiteColor];
    [alert showCustom:icon
                color:[UIColor colorWithRed:65.0/255.0 green:64.0/255.0 blue:144.0/255.0 alpha:1.0]
                title:@"Change"
             subTitle:message
     closeButtonTitle:nil
             duration:0];
}

#pragma mark moral mode
- (void)moralModeSwitchChange: (id)sender {
    __block FUISwitch *moralModeSwitch = sender;
    
    if(moralModeSwitch.isOn) { //create passcode
        SCLAlertView *alert = [IJTShowMessage baseAlertView];
        UITextField *password = [alert addTextField:@"Password"];
        UITextField *confirmPassword = [alert addTextField:@"Confirm password"];
        
        password.keyboardType = UIKeyboardTypeASCIICapable;
        confirmPassword.keyboardType = UIKeyboardTypeASCIICapable;
        
        password.secureTextEntry = YES;
        confirmPassword.secureTextEntry = YES;
        
        [alert addButton:@"OK" actionBlock:^{
            [password resignFirstResponder];
            [confirmPassword resignFirstResponder];
            
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                if(password == nil || password.text.length <= 0 ||
                   confirmPassword == nil || confirmPassword.text.length <= 0) {
                    [self showErrorMessage:@"Please enter a password."];
                }
                else {
                    if([password.text isEqualToString:confirmPassword.text]) {
                        NSString *encodePassword = [IJTOpenSSL sha256FromString:password.text];
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults setObject:encodePassword forKey:@"MoralMode"];
                        [userDefaults synchronize];
                        [self showSuccessMessage:@"Success"];
                    }
                    else {
                        [self showErrorMessage:@"Two password are not the same."];
                    }
                }
                
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }];
        }];
        
        [alert addButton:@"Cancle" actionBlock:^{
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        
        [alert showEdit:@"Enter password"
               subTitle:@"Enter a new password."
       closeButtonTitle:nil
               duration:0];
        
        return;
        
    }
    else { //delete passcode
        
        SCLAlertView *alert = [IJTShowMessage baseAlertView];
        UITextField *password = [alert addTextField:@"Password"];
        
        password.keyboardType = UIKeyboardTypeASCIICapable;
        password.secureTextEntry = YES;
        
        [alert addButton:@"Delete it" actionBlock:^{
            [password resignFirstResponder];
            
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                if(password == nil || password.text.length <= 0) {
                    [self showErrorMessage:@"Please enter your password."];
                }
                else {
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    NSString *hashCode = [userDefaults valueForKey:@"MoralMode"];
                    NSString *encodePassword = [IJTOpenSSL sha256FromString:password.text];
                    if([hashCode isEqualToString:encodePassword]) {
                        [userDefaults setValue:@"" forKey:@"MoralMode"];
                        [userDefaults synchronize];
                        [self showSuccessMessage:@"Success"];
                    }
                    else {
                        [self showErrorMessage:@"Fail to delete your password."];
                    }
                }
                
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }];
        }];
        
        [alert addButton:@"Cancle" actionBlock:^{
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        
        [alert showEdit:@"Enter password"
               subTitle:@"Enter your password to delete it."
       closeButtonTitle:nil
               duration:0];
    }
}

#pragma mark refresh delegate
- (void)beganRefreshing {
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        [self.refreshView endRefreshing];
    }];
}

- (void)forwardingSwitchChange: (id)sender {
    FUISwitch *forwardingSwitch = sender;
    int state = [IJTSysctl setIPForwarding:forwardingSwitch.isOn];
    if(state == -1) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(EPERM)]];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [forwardingSwitch setOn:!forwardingSwitch.isOn animated:YES];
        }];
    }
    else {
        [self showSuccessMessage:@"Success"];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 3;
    else if(section == 1)
        return 3;
    else if(section == 2)
        return 1;
    else if(section == 3)
        return 1;
    else if(section == 4)
        return 1;
    else if(section == 5)
        return 2;
    else if(section == 6)
        return 3;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        IJTSupportSocialTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SocialCell" forIndexPath:indexPath];
        
        cell.statusView.backgroundColor = [UIColor clearColor];
        if(indexPath.row == 0) {
            cell.iconImageView.image = [UIImage imageNamed:@"Facebook.png"];
            cell.nameLabel.text = @"Facebook";
            
            [cell.statusView addSubview:_facebookButton];
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.statusView.frame);
            self.facebookButton.frame = CGRectMake(width - 120-8, 0, 120, 55 - 16);
            
        }
        else if(indexPath.row == 1) {
            cell.iconImageView.image = [UIImage imageNamed:@"Google_plus.png"];
            cell.nameLabel.text = @"Google+";
            
            [cell.statusView addSubview:_googleButton];
            
            [cell layoutIfNeeded];
            
            CGFloat width = CGRectGetWidth(cell.statusView.frame);
            self.googleButton.frame = CGRectMake(width - 120-8, 0, 120, 55 - 16);
        }
        else if(indexPath.row == 2) {
            cell.iconImageView.image = [IJTUIImage imageWithImage:[UIImage imageNamed:@"Injector_icon.png"] scaledToSize:CGSizeMake(38, 38)];
            cell.nameLabel.text = @"Home";
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(cell.statusView.frame), CGRectGetHeight(cell.statusView.frame))];
            label.text = @"https://nrl.cce.mcu.edu.tw/injector";
            label.textAlignment = NSTextAlignmentLeft;
            label.textColor = IJTValueColor;
            label.adjustsFontSizeToFitWidth = YES;
            label.numberOfLines = 0;
            [cell.statusView addSubview:label];
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            [cell layoutIfNeeded];
            
            label.frame = CGRectMake(0, 0, CGRectGetWidth(cell.statusView.frame), CGRectGetHeight(cell.statusView.frame));
        }
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        if(indexPath.row == 0) {
            IJTSupportSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell" forIndexPath:indexPath];
            
            cell.nameLabel.text = @"Packet Forward";
            int state = [IJTSysctl ipForwarding];
            if(state == 1) {
                [cell.enableSwitch setOn:YES];
            }
            else if(state == 0) {
                [cell.enableSwitch setOn:NO];
            }
            else if(state == -1) {
                [cell.enableSwitch setOn:NO];
                [cell.enableSwitch setEnabled:NO];
                [self showErrorMessage:@"Couldn\'t get forwarding information"];
            }
            [cell.enableSwitch addTarget:self action:@selector(forwardingSwitchChange:) forControlEvents:UIControlEventValueChanged];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 1) {
            IJTSupportSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell" forIndexPath:indexPath];
            
            NSArray *list = [IJTSysctl suggestSettings];
            NSMutableArray *enables = [[NSMutableArray alloc] init];
            for(NSString *name in list) {
                int nowValue = [IJTSysctl sysctlValueByname:name];
                int suggest = [IJTSysctl suggestValue:name];
                if(nowValue == suggest) {
                    [enables addObject:@(YES)];
                }
                else {
                    [enables addObject:@(NO)];
                }
            }
            BOOL enable = YES;
            for(NSNumber *number in enables) {
                if([number boolValue] == NO) {
                    enable = NO;
                    break;
                }
            }
            
            [cell.enableSwitch setOn:enable];
            
            cell.nameLabel.text = @"System Protection";
            [cell.enableSwitch addTarget:self action:@selector(sysctlSwitchChange:) forControlEvents:UIControlEventValueChanged];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else if(indexPath.row == 2) {
            IJTSupportSwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell" forIndexPath:indexPath];
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSString *hashCode = [userDefaults valueForKey:@"MoralMode"];
            if(hashCode == nil || hashCode.length <= 0) {
                [cell.enableSwitch setOn:NO];
            }
            else {
                [cell.enableSwitch setOn:YES];
            }
            
            cell.nameLabel.text = @"Moral Mode";
            [cell.enableSwitch addTarget:self action:@selector(moralModeSwitchChange:) forControlEvents:UIControlEventValueChanged];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }
    else if(indexPath.section == 2 || indexPath.section == 3 || indexPath.section == 4 || indexPath.section == 5) {
        IJTSupportMaintainerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MaintainerCell" forIndexPath:indexPath];
        cell.nameLabel.textColor = IJTValueColor;
        
        NSInteger offset = 0;
        if(indexPath.section > 2) {
            NSInteger section = indexPath.section;
            while(section-- > 2)
                offset += [self.tableView numberOfRowsInSection:indexPath.section - 1];
        }
        
        if(self.imageArray.count > indexPath.row + offset && self.nameArray.count > indexPath.row + offset) {
            UIImage *image = self.imageArray[indexPath.row + offset];
            NSString *name = self.nameArray[indexPath.row + offset];
            UIImageView *facebookIcon = [[UIImageView alloc] initWithImage:
                                         [IJTUIImage imageWithImage:[UIImage imageNamed:@"Facebook.png"]
                                                       scaledToSize:CGSizeMake(30, 30)]];
            UIView *iconView = [[UIView alloc] initWithFrame:
                                CGRectMake(CGRectGetWidth(cell.profileImageView.frame)-30,
                                           CGRectGetHeight(cell.profileImageView.frame)-29,
                                           30, 30)];
            [iconView addSubview:facebookIcon];
            
            [[cell.profileImageView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            cell.profileImageView.image = image;
            [cell.profileImageView addSubview:iconView];
            cell.profileImageView.contentMode = UIViewContentModeScaleAspectFill;
            cell.nameLabel.text = name;
        }
        else {
            CGFloat position = CGRectGetWidth(cell.profileImageView.frame)/2;
            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithFrame:
                                                 CGRectMake(position-12.5, position-12.5, 25, 25)];
            
            [cell.profileImageView addSubview:activity];
            [activity startAnimating];
            cell.nameLabel.text = @"Loading...";
        }
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 6) {
        IJTSupportFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
        
        if(indexPath.row == 0) {
            cell.nameLabel.text = @"App Name";
            [IJTFormatUILabel dict:_appInfoDict
                               key:@"AppName"
                             label:cell.valueLabel
                             color:IJTValueColor
                              font:nil];
        }
        else if(indexPath.row == 1) {
            cell.nameLabel.text = @"Version";
            [IJTFormatUILabel dict:_appInfoDict
                               key:@"Version"
                             label:cell.valueLabel
                             color:IJTValueColor
                              font:nil];
        }
        else if(indexPath.row == 2) {
            cell.nameLabel.text = @"Build Date";
            [IJTFormatUILabel dict:_appInfoDict
                               key:@"BuildDate"
                             label:cell.valueLabel
                             color:IJTValueColor
                              font:nil];
        }
        
        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Social Media";
    else if(section == 1)
        return @"System control";
    else if(section == 2)
        return @"Advising Professor";
    else if(section == 3)
        return @"App Maintainer";
    else if(section == 4)
        return @"Website Maintainer";
    else if(section == 5)
        return @"Manager Interface Maintainer";
    else if(section == 6)
        return @"App Information";
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 0 && indexPath.row == 2) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://nrl.cce.mcu.edu.tw/injector"]];
    }
    else if(indexPath.section == 2 || indexPath.section == 3 || indexPath.section == 4 || indexPath.section == 5) {
        NSInteger offset = 0;
        if(indexPath.section > 2) {
            NSInteger section = indexPath.section;
            while(section-- > 2)
                offset += [self.tableView numberOfRowsInSection:indexPath.section - 1];
        }
        if(self.emailArray.count > indexPath.row + offset) {
            NSString *email = self.emailArray[indexPath.row + offset];
            
            MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
            controller.mailComposeDelegate = self;
            [controller setSubject:[NSString stringWithFormat:@"Send From Injector v%@", [_appInfoDict valueForKey:@"Version"]]];
            [controller setMessageBody:[NSString stringWithFormat:@"\n\n\nSN : %@", [IJTID serialNumber]] isHTML:NO];
            [controller setToRecipients:@[email]];
            [controller setCcRecipients:@[_emailArray[1]]];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            if ([MFMailComposeViewController canSendMail]) {
                [self presentViewController:controller animated:YES completion:^{
                    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                }];
            }//end if
#pragma GCC diagnostic pop
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0)
        return 55.0f;
    else if(indexPath.section == 2 || indexPath.section == 3 || indexPath.section == 4 || indexPath.section == 5)
        return 120.0f;
    else if(indexPath.section == 1 || indexPath.section == 6)
        return 44.0f;
    return 0.0;
}

#pragma mark email
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"It's away!");
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}
@end
