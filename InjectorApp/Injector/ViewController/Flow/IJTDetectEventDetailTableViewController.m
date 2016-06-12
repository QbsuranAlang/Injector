//
//  IJTDetectEventDetailTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/5/7.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTDetectEventDetailTableViewController.h"
#import "IJTCountryInformationTableViewCell.h"
#import "IJTDetectedDateTableViewCell.h"
#import "IJTIpRelatedAppTableViewCell.h"

@interface IJTDetectEventDetailTableViewController ()

@property (nonatomic, weak) NSString *ipAddress;
@property (nonatomic, strong) NSMutableArray *messageArray;
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic) NSInteger oldIndex;
@property (nonatomic) BOOL loaded;

@end

@implementation IJTDetectEventDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.ipAddress = [self.detectEventDetail valueForKey:@"IpAddress"];
    self.navigationItem.title = self.ipAddress;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithImage:[UIImage imageNamed:@"left.png"]
                                   style:UIBarButtonItemStylePlain
                                   target:self action:@selector(back:)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:backButton, nil];
    NSMutableArray *times = [NSMutableArray arrayWithArray:[self.detectEventDetail valueForKey:@"DetectTime"]];
    for(int i = 0 ; i < times.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSString *time1 = [times objectAtIndex:i];
            NSString *time2 = [times objectAtIndex:j];
            if([time1 longLongValue] > [time2 longLongValue]) {
                [times exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }
    [self.detectEventDetail setValue:times forKey:@"DetectTime"];
    
    self.loaded = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)back: (id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)allowIt: (id)sender {
    NSString *ipAddress = self.ipAddress;
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
    NSString *ipAddress = self.ipAddress;
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

- (void)misunderstanding {
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    
    [alert addButton:@"Yes" actionBlock:^{
        [KVNProgress showWithStatus:@"Reporting..."];
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            NSString *post = [NSString stringWithFormat:@"SerialNumber=%@&IpAddress=%@", [IJTID serialNumber], self.ipAddress];
            [IJTHTTP retrieveFrom:@"ReceiveMisunderstandingHost.php"
                             post:post
                          timeout:5
                            block:^(NSData *data){
                                NSString *result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                                [IJTDispatch dispatch_main:^{
                                    
                                    [KVNProgress dismissWithCompletion:^{
                                        if([result integerValue] == IJTStatusServerDataExsit) {
                                            [self showWarningMessage:@"It is already reported before."];
                                        }
                                        else if([result integerValue] == IJTStatusServerSuccess) {
                                            [self showSuccessMessage:@"Success"];
                                        }
                                        else {
                                            [self showErrorMessage:@"Fail to report."];
                                        }
                                    }];
                                }];
                            }];
            
        }];
    }];
    
    [alert showInfo:@"Misunderstanding"
           subTitle:[NSString stringWithFormat:@"Is \"%@\" misunderstanding?", self.ipAddress]
   closeButtonTitle:@"No"
           duration:0];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    switch (section) {
        case 0:
        case 1:
            return 1;
        case 2:
            return 3;
        case 3: {
            NSString *value = [self.detectEventDetail valueForKey:@"Count"];
            return [value integerValue];
        }
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Country Information";
    else if(section == 1)
        return @"Application Information";
    else if(section == 2)
        return @"Firewall";
    else {
        return [NSString stringWithFormat:@"Detected Date (%@)",
                [self.detectEventDetail valueForKey:@"Count"]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1) {
        return SCREEN_WIDTH;
    }
    else if(indexPath.section == 2) {
        return 55.f;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        IJTCountryInformationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CountryInfomationCell" forIndexPath:indexPath];
        [IJTFormatUILabel dict:self.detectEventDetail
                           key:@"CountryName"
                         label:cell.countryNameLabel
                         color:[IJTColor darker:IJTValueColor times:2]
                          font:[UIFont systemFontOfSize:11]];
        [IJTFormatUILabel dict:self.detectEventDetail
                           key:@"RegionName"
                         label:cell.regionNameLabel
                         color:[IJTColor darker:IJTValueColor times:2]
                          font:[UIFont systemFontOfSize:11]];
        [IJTFormatUILabel dict:self.detectEventDetail
                           key:@"CityName"
                         label:cell.cityNameLabel
                         color:[IJTColor darker:IJTValueColor times:2]
                          font:[UIFont systemFontOfSize:11]];
        [IJTFormatUILabel dict:self.detectEventDetail
                           key:@"ResolveHostname" prefix:@"Resolve Hostname : "
                         label:cell.resolveHostnameLabel
                         color:[IJTColor darker:IJTValueColor times:2]
                          font:[UIFont systemFontOfSize:11]];

        cell.countryFlagImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"CountryIcon.bundle/%@.png", [self.detectEventDetail valueForKey:@"CountryCode"]]];
        cell.countryFlagImageView.contentMode = UIViewContentModeScaleAspectFill;
        
        CALayer *layer = cell.countryFlagImageView.layer;
        //圓形
        layer.cornerRadius = CGRectGetHeight(layer.frame) / 2;
        layer.masksToBounds = YES;
        //邊框
        layer.borderWidth = 0.5;
        layer.borderColor = [IJTInjectorIconBackgroundColor CGColor];
        
        if(cell.countryFlagImageView.image == nil) {
            CAGradientLayer *gradient = [CAGradientLayer layer];
            gradient.frame = cell.countryFlagImageView.bounds;
            gradient.colors =
            [NSArray arrayWithObjects:(id)[IJTInjectorIconBackgroundColor CGColor],
             (id)[[IJTColor lighter:IJTInjectorIconBackgroundColor times:2] CGColor], nil];
            [cell.countryFlagImageView.layer insertSublayer:gradient atIndex:0];
        }
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTIpRelatedAppTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IpRelatedAppCell"];
        cell.graphView.frame = CGRectMake(8, 8, SCREEN_WIDTH - 16, SCREEN_WIDTH - 16);
        cell.graphView.backgroundColor = [UIColor clearColor];
        
        if(!self.loaded) {
            [cell.activityView startAnimating];
            [IJTDispatch dispatch_main_after:0.1 block:^{
                [self retrieveIpRelatedApplication:cell.graphView];
                [cell.activityView stopAnimating];
                cell.activityView.hidden = YES;
                self.loaded = YES;
            }];
        }
        
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
        else if(indexPath.row == 2) {
            [button setTitle:@"Misunderstanding" forState:UIControlStateNormal];
            [button addTarget:self action:@selector(misunderstanding) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [cell.contentView addSubview:button];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 2 && indexPath.row == 2) {
        
    }
    else if(indexPath.section == 3) {
        IJTDetectedDateTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetectedDateCell" forIndexPath:indexPath];
        NSArray *times = [self.detectEventDetail valueForKey:@"DetectTime"];
        
        [IJTFormatUILabel text:[IJTFormatString formatDetectedDate:[times objectAtIndex:indexPath.row]]
                         label:cell.detectedDateLabel
                         color:[IJTColor darker:IJTDetectedDateColor
                                          times:indexPath.row
                                          level:2]
                          font:[UIFont systemFontOfSize:17]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    return [[UITableViewCell alloc] init];
}

- (void)retrieveIpRelatedApplication: (UIView *)graphView {
    _colors = @[IJTFlowColor,
                IJTSnifferColor,
                IJTLANColor,
                IJTToolsColor,
                IJTFirewallColor,
                IJTSupportColor];
    
    
    
    [IJTHTTP retrieveFrom:@"RetrieveIpRelatedApplication.php"
                     post:[NSString stringWithFormat:@"IpAddress=%@", self.ipAddress]
                  timeout:5
                    block:^(NSData *data){
                        NSDictionary *appdict = nil;
                        NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                        if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                            appdict = nil;
                        }
                        if(jsonstring) {
                            appdict = [IJTJson json2dictionary:jsonstring];
                        }
                        
                        NSMutableArray *array = [[NSMutableArray alloc] init];
                        UIColor *descriptionColor = IJTWhiteColor;
                        self.messageArray = [[NSMutableArray alloc] init];
                        
                        if(appdict && appdict.count > 0) {
                            int i = 0;
                            for(NSDictionary *dict in appdict) {
                                //NSString *bundleID = [dict valueForKey:@"BundleID"];
                                //NSString *displayName = [dict valueForKey:@"DisplayName"];
                                NSString *count = [dict valueForKey:@"Count"];
                                NSString *message = [dict valueForKey:@"Message"];
                                
                                [array addObject:
                                 [PNPieChartDataItem
                                  dataItemWithValue:count.integerValue
                                  color:_colors[i++ % _colors.count]]];
                                [self.messageArray addObject:message];
                            }
                        }
                        else {
                            [array addObject:[PNPieChartDataItem
                                              dataItemWithValue:100
                                              color:IJTLightBlueColor
                                              description:@"No data"]];
                            descriptionColor = [UIColor darkGrayColor];
                        }
                        [IJTDispatch dispatch_main:^{
                            PNPieChart *pieChart =
                            [[PNPieChart alloc]
                             initWithFrame:CGRectMake(14, 14,
                                                      CGRectGetWidth(graphView.frame) - 28,
                                                      CGRectGetWidth(graphView.frame) - 28)
                             items:array];
                            pieChart.descriptionTextColor = descriptionColor;
                            pieChart.descriptionTextFont  = [UIFont systemFontOfSize:14];
                            [graphView addSubview:pieChart];
                            pieChart.delegate = self;
                            [pieChart strokeChart];
                            self.oldIndex = -1;
                        }];
                    }];
}

- (void)userClickedOnPieIndexItem:(NSInteger)pieIndex {
    //need click twice
    if(self.oldIndex != pieIndex) {
        self.oldIndex = pieIndex;
        [IJTDispatch dispatch_main_after:0.5 block:^{
            self.oldIndex = -1;
        }];
        return;
    }
    
    if(self.messageArray.count <= 0)
        return;
    
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    
    [alert showCustom:[SCLAlertViewStyleKit imageOfInfo]
                color:_colors[pieIndex % _colors.count]
                title:@"Application"
             subTitle:self.messageArray[pieIndex]
     closeButtonTitle:@"OK" duration:0];
}

@end
