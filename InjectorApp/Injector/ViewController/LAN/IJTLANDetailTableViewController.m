//
//  IJTLANDetailTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTLANDetailTableViewController.h"
#import "IJTLANDeviceDetailTableViewCell.h"
#import "IJTMultiSelectTableViewCell.h"
#import "IJTLANDeviceStatusTableViewCell.h"
@interface IJTLANDetailTableViewController ()

@property (nonatomic, strong) NSArray *toolArray;

@end

@implementation IJTLANDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 75;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = [_dict valueForKey:@"IpAddress"];
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    
    self.toolArray = [IJTBaseViewController getLANSupportToolArray];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark firewall
- (void)allowIt: (id)sender {
    NSString *ipAddress = [_dict valueForKey:@"IpAddress"];
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    BOOL exsitAllowList = [IJTAllowAndBlock exsitInAllow:ipAddress];
    BOOL exsitBlockList = [IJTAllowAndBlock exsitInBlock:ipAddress];
    
    if(exsitAllowList) {
        [self showInfoMessage:
         [NSString stringWithFormat:@"\"%@\" is already exsit in allow list.", ipAddress]];
        return;
    }
    else if(exsitBlockList) {
        [alert addButton:@"Yes" actionBlock:^{
            if([IJTAllowAndBlock blockMoveToAllow:ipAddress target:self]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showSuccessMessage:@"Success"];
                }];
            }
        }];
        [alert showWarning:@"Warning"
                  subTitle:[NSString stringWithFormat:@"\"%@\" is exsit in block list.\nDo you want to move to allow list?", ipAddress]
          closeButtonTitle:@"No"
                  duration:0];
    }
    else {
        [alert addButton:@"Yes" actionBlock:^{
            if([IJTAllowAndBlock newAllow:ipAddress time:time(NULL) displayName:@"Injector" enable:YES]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showSuccessMessage:@"Success"];
                }];
            }
        }];
        
        [alert showInfo:@"Confirm"
               subTitle:[NSString stringWithFormat:@"Are you sure want to add \"%@\" to allow list?", ipAddress]
       closeButtonTitle:@"No"
               duration:0];
    }
}

- (void)blockIt: (id)sender {
    NSString *ipAddress = [_dict valueForKey:@"IpAddress"];
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    BOOL exsitAllowList = [IJTAllowAndBlock exsitInAllow:ipAddress];
    BOOL exsitBlockList = [IJTAllowAndBlock exsitInBlock:ipAddress];
    
    if(exsitBlockList) {
        [self showInfoMessage:
         [NSString stringWithFormat:@"\"%@\" is already exsit in block list.", ipAddress]];
        return;
    }
    else if(exsitAllowList) {
        [alert addButton:@"Yes" actionBlock:^{
            if([IJTAllowAndBlock allowMoveToBlock:ipAddress target:self]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showSuccessMessage:@"Success"];
                }];
            }
        }];
        [alert showWarning:@"Warning"
                  subTitle:[NSString stringWithFormat:@"\"%@\" is exsit in allow list.\nDo you want to move to block list?", ipAddress]
          closeButtonTitle:@"No"
                  duration:0];
    }
    else {
        [alert addButton:@"Yes" actionBlock:^{
            if([IJTAllowAndBlock newBlock:ipAddress time:time(NULL) displayName:@"Injector" enable:YES target:self]) {
                [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                    [self showSuccessMessage:@"Success"];
                }];
            }
        }];
        
        [alert showInfo:@"Confirm"
               subTitle:[NSString stringWithFormat:@"Are you sure want to add \"%@\" to block list?", ipAddress]
       closeButtonTitle:@"No"
               duration:0];
    }
}

#pragma mark animation
- (void) startAnimation: (UITapGestureRecognizer *)recognizer {
    CSAnimationView *animation = (CSAnimationView *)recognizer.view;
    [animation startCanvasAnimation];
}

- (void)drawCell: (IJTLANDeviceStatusTableViewCell *)cell flag: (IJTLANStatusFlags)flag forKey:(NSString *)key {
    
    NSNumber *flagNumber = [_dict valueForKey:@"Flags"];
    IJTLANStatusFlags flags = [flagNumber unsignedShortValue];
    
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(startAnimation:)];
    
    CSAnimationView *animationView = [[CSAnimationView alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
    
    animationView.backgroundColor = [UIColor clearColor];
    
    animationView.duration = 0.5;
    animationView.delay    = 0;
    animationView.type     = CSAnimationTypeMorph;
    [animationView addGestureRecognizer:singleFingerTap];
    
    if(flags & flag) {
        [IJTGradient drawCircle:animationView color:IJTOkColor];
    }
    else {
        [IJTGradient drawCircle:animationView color:IJTErrorColor];
    }
    
    if(key) {
        if(flags & flag) {
            [_dict setValue:@"Yes" forKey:key];
        }
        else {
            [_dict setValue:@"No" forKey:key];
        }
    }
    
    cell.statusView.backgroundColor = [UIColor clearColor];
    [[cell.statusView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [cell.statusView addSubview:animationView];
    [animationView startCanvasAnimation];
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 3) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ToolKitStoryboard" bundle:nil];
        NSString *vcid = [NSString stringWithFormat:@"%@NavVC", _toolArray[indexPath.row]];
        UINavigationController *navVC = [storyboard instantiateViewControllerWithIdentifier:vcid];
        IJTBaseViewController *vc = [[navVC viewControllers] firstObject];
        vc.fromLAN = YES;
        vc.popButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"left.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(dismissVC)];
        vc.ipAddressFromLan = [_dict valueForKey:@"IpAddress"];
        vc.macAddressFromLan = [_dict valueForKey:@"MacAddress"];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 9;
    else if(section == 1)
        return 6;
    else if(section == 2)
        return 2;
    else if(section == 3)
        return _toolArray.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(indexPath.row < 3) {
            IJTLANDeviceDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
            
            NSString *name = @"";
            NSString *key = @"";
            
            
            if(indexPath.row == 0) {
                name = @"IP Address";
                key = @"IpAddress";
            }
            else if(indexPath.row == 1) {
                name = @"MAC Address";
                key = @"MacAddress";
            }
            else if(indexPath.row == 2) {
                name = @"OUI";
                key = @"OUI";
            }
            
            cell.nameLabel.text = name;
            
            [IJTFormatUILabel dict:_dict
                               key:key
                             label:cell.valueLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [cell layoutIfNeeded];
            return cell;
        }
        else {
            
            IJTLANDeviceStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell" forIndexPath:indexPath];
            
            NSString *name = @"";
            NSString *key = @"";
            
            if(indexPath.row == 3) {
                name = @"Gateway";
                key = @"Gateway";
                [self drawCell:cell flag:IJTLANStatusFlagsGateway forKey:key];
            }
            else if(indexPath.row == 4) {
                name = @"Myself";
                key = @"Myself";
                [self drawCell:cell flag:IJTLANStatusFlagsMyself forKey:key];
            }
            else if(indexPath.row == 5) {
                name = @"arping";
                key = @"arping";
                [self drawCell:cell flag:IJTLANStatusFlagsArping forKey:key];
            }
            else if(indexPath.row == 6) {
                name = @"arpoison";
                key = @"arpoison";
                [self drawCell:cell flag:IJTLANStatusFlagsArpoison forKey:key];
            }
            else if(indexPath.row == 7) {
                name = @"ping";
                key = @"ping";
                [self drawCell:cell flag:IJTLANStatusFlagsPing forKey:key];
            }
            else if(indexPath.row == 8) {
                name = @"Firewalled";
                key = @"Firewalled";
                [self drawCell:cell flag:IJTLANStatusFlagsFirewalled forKey:key];
            }
            
            cell.nameLabel.text = name;
            
            [IJTFormatUILabel dict:_dict
                               key:key
                             label:cell.booleanLabel
                             color:IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [cell layoutIfNeeded];
            return cell;
        }
        
    }
    else if(indexPath.section == 1) {
        IJTLANDeviceDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
        
        NSString *name = @"";
        NSString *key = @"";
        NSNumber *flagNumber = [_dict valueForKey:@"Flags"];
        IJTLANStatusFlags flags = [flagNumber unsignedShortValue];
        UIColor *color = IJTValueColor;
        
        cell.accessoryView = nil;
        if(indexPath.row == 0) {
            name = @"mDNS";
            if(flags & IJTLANStatusFlagsMDNS) {
                key = @"mDNSName";
            }
            else {
                color = [UIColor lightGrayColor];
            }
        }
        else if(indexPath.row == 1) {
            name = @"DNS";
            if(flags & IJTLANStatusFlagsDNS) {
                key = @"DNSName";
            }
            else {
                color = [UIColor lightGrayColor];
            }
        }
        else if(indexPath.row == 2) {
            name = @"LLMNR";
            if(flags & IJTLANStatusFlagsLLMNR) {
                key = @"LLMNRName";
            }
            else {
                color = [UIColor lightGrayColor];
            }
        }
        else if(indexPath.row == 3) {
            name = @"NetBIOS";
            if(flags & IJTLANStatusFlagsNetbios) {
               key = @"netbiosName";
            }
            else {
                color = [UIColor lightGrayColor];
            }
        }
        else if(indexPath.row == 4) {
            name = @"NetBIOS Group";
            if(flags & IJTLANStatusFlagsNetbios) {
                key = @"netbiosGroup";
            }
            else {
                color = [UIColor lightGrayColor];
            }
        }
        else if(indexPath.row == 5) {
            name = @"SSDP";
            if(flags & IJTLANStatusFlagsSSDP) {
                key = @"SSDPName";
            }
            else {
                color = [UIColor lightGrayColor];
            }
        }
        
        cell.nameLabel.text = name;
        
        cell.valueLabel.adjustsFontSizeToFitWidth = YES;
        
        [IJTFormatUILabel dict:_dict
                           key:key
                         label:cell.valueLabel
                         color:color
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.valueLabel layoutIfNeeded];
        
        [cell setNeedsUpdateConstraints];
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 2) {
        GET_EMPTY_CELL;
        FUIButton *button = [[FUIButton alloc] initWithFrame:CGRectMake(16, 8, SCREEN_WIDTH - 32, 55 - 16)];
        if(indexPath.row == 0) {
            [button setTitle:@"Allow it" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(allowIt:) forControlEvents:UIControlEventTouchUpInside];
        }
        else if(indexPath.row == 1) {
            [button setTitle:@"Block it" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(blockIt:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [cell.contentView addSubview:button];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 3) {
        IJTMultiSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ToolCell" forIndexPath:indexPath];
        
        NSString *tool = _toolArray[indexPath.row];
        [IJTFormatUILabel text:tool
                         label:cell.nameLabel
                          font:[UIFont systemFontOfSize:17]];
        
        cell.iconImageView.image = [UIImage imageNamed:[tool stringByAppendingString:@".png"]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 2)
        return 55.0f;
    else if(indexPath.section == 3)
        return 60.0f;
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [cell startCanvasAnimation];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Device";
    else if(section == 1)
        return @"Names";
    else if(section == 2)
        return @"Firewall";
    else if(section == 3)
        return @"Query with Tool";
    return @"";
}
@end
