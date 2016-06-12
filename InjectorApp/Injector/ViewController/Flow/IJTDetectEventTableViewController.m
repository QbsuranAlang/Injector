//
//  IJTDetectEventTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/5/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTDetectEventTableViewController.h"
#import "IJTDetectEventTableViewCell.h"
#import "IJTDetectEventDetailTableViewController.h"

@interface IJTDetectEventTableViewController ()

@property (nonatomic, strong) NSMutableArray *detectEventArray;
@property (nonatomic, strong) NSMutableArray *searchResultDetectEventArray;
@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation IJTDetectEventTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    //set back button clear
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc]
     initWithTitle:@""
     style:UIBarButtonItemStylePlain
     target:nil
     action:nil];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithImage:[UIImage imageNamed:@"left.png"]
                                   style:UIBarButtonItemStylePlain
                                   target:self action:@selector(back:)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:backButton, nil];
    
    self.navigationItem.title = @"Detected Event";
    
    self.detectEventArray = [[NSMutableArray alloc] init];
    for(NSDictionary *dict in self.detectEvent) {
        [self.detectEventArray addObject:dict];
    }
    //sort, descend
    for(int i = 0 ; i < self.detectEventArray.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSString *count1 = [self.detectEventArray[i] valueForKey:@"Count"];
            NSString *count2 = [self.detectEventArray[j] valueForKey:@"Count"];
            if([count1 longLongValue] > [count2 longLongValue]) {
                NSDictionary *temp = self.detectEventArray[i];
                self.detectEventArray[i] = self.detectEventArray[j];
                self.detectEventArray[j] = temp;
            }
        }
    }//end for sort
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    self.searchController.delegate = self;
    self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit];
    self.searchController.searchBar.placeholder = @"";
    self.searchController.searchBar.keyboardType = UIKeyboardTypeASCIICapable;
    self.searchController.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchController.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:IJTFlowColor];
#else
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTintColor:IJTFlowColor];
#endif
    
    self.messageLabel.text = @"Search IP address, Country code or Amount";
}

- (void)back: (id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView setContentOffset:CGPointMake(0,44) animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.searchController.active = NO;
}

#pragma mark search bar
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.searchResultDetectEventArray = [[NSMutableArray alloc] init];
    NSString *text = searchController.searchBar.text.uppercaseString;
    for(NSDictionary *dict in self.detectEventArray) {
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        NSString *countryCode = [dict valueForKey:@"CountryCode"];
        NSString *count = [dict valueForKey:@"Count"];
        
        countryCode = countryCode.uppercaseString;
        
        if([ipAddress containsString:text]) {
            [self.searchResultDetectEventArray addObject:dict];
        }
        if([countryCode containsString:text]) {
            [self.searchResultDetectEventArray addObject:dict];
        }
        if([count isEqualToString:text]) {
            [self.searchResultDetectEventArray addObject:dict];
        }
    }
    self.searchResultDetectEventArray =
    [NSMutableArray arrayWithArray:[[NSSet setWithArray:self.searchResultDetectEventArray] allObjects]];
    
    for(int i = 0 ; i < self.searchResultDetectEventArray.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSDictionary *dict1 = self.searchResultDetectEventArray[i];
            NSDictionary *dict2 = self.searchResultDetectEventArray[j];
            NSString *count1 = [dict1 valueForKey:@"Count"];
            NSString *count2 = [dict2 valueForKey:@"Count"];
            
            if([count1 longLongValue] > [count2 longLongValue]) {
                [self.searchResultDetectEventArray exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }
    
    [self.tableView reloadData];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)willPresentSearchController:(UISearchController *)searchController {
    //[[UIApplication sharedApplication] setStatusBarHidden:YES];
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    self.searchController.searchBar.placeholder = @"Search";
    self.navigationController.navigationBar.translucent = YES;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    //[[UIApplication sharedApplication] setStatusBarHidden:NO];
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.searchController.searchBar.placeholder = @"";
    self.navigationController.navigationBar.translucent = NO;
}
#pragma GCC diagnostic pop

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    if(searchBar.isFirstResponder)
        [self.tableView endEditing:YES];
    
    [self.tableView reloadData];
}

#pragma mark table view deleagte

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.searchController.active) {
        if(self.searchResultDetectEventArray.count == 0) {
            [self.tableView addSubview:self.messageLabel];
        }
        else {
            [self.messageLabel removeFromSuperview];
        }
        return self.searchResultDetectEventArray.count;
    }
    else {
        if(self.detectEventArray.count == 0) {
            [self.tableView addSubview:self.messageLabel];
        }
        else {
            [self.messageLabel removeFromSuperview];
        }
        return self.detectEventArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTDetectEventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DetectEventCell" forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *dict = nil;
    if(self.searchController.active)
        dict = self.searchResultDetectEventArray[indexPath.row];
    else
        dict = self.detectEventArray[indexPath.row];
    
    [IJTFormatUILabel dict:dict key:@"IpAddress"
                     label:cell.ipAddressLabel
                     color:[IJTColor darker:IJTValueColor times:2]
                      font:[UIFont systemFontOfSize:11]];
    [IJTFormatUILabel dict:dict key:@"CountryCode"
                     label:cell.countryCodeLabel
                     color:[IJTColor darker:IJTValueColor times:2]
                      font:[UIFont systemFontOfSize:11]];
    [IJTFormatUILabel dict:dict key:@"Count"
                     label:cell.detectTimesLabel
                     color:[IJTColor darker:IJTValueColor times:2]
                      font:[UIFont systemFontOfSize:11]];
    
    cell.countryFlagView.image = [UIImage imageNamed:[NSString stringWithFormat:@"CountryIcon.bundle/%@.png", [dict valueForKey:@"CountryCode"]]];
    
    cell.countryFlagView.contentMode = UIViewContentModeScaleAspectFill;
    
    CALayer *layer = cell.countryFlagView.layer;
    //圓形
    layer.cornerRadius = CGRectGetHeight(layer.frame) / 2;
    layer.masksToBounds = YES;
    //邊框
    layer.borderWidth = 0.5;
    layer.borderColor = [IJTInjectorIconBackgroundColor CGColor];
    
    if(cell.countryFlagView.image == nil) {
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = cell.countryFlagView.bounds;
        gradient.colors =
        [NSArray arrayWithObjects:(id)[IJTInjectorIconBackgroundColor CGColor],
         (id)[[IJTColor lighter:IJTInjectorIconBackgroundColor times:2] CGColor], nil];
        [cell.countryFlagView.layer insertSublayer:gradient atIndex:0];
    }
    
    [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:11];
    }];
    
    [cell layoutIfNeeded];
    
    return cell;
}

- (NSArray *)detectString: (NSString *)detect
{
    detect = [detect substringWithRange:NSMakeRange(1, [detect length]-2)];
    NSArray *arr = [detect componentsSeparatedByString:@","];
    return arr;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        if(self.searchController.isActive)
            return [NSString stringWithFormat:@"Search Detected Event(%lu)", (unsigned long)self.searchResultDetectEventArray.count];
        else
            return [NSString stringWithFormat:@"Detected Event(%lu)", (unsigned long)self.detectEventArray.count];
    }
    return @"";
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([[segue identifier] isEqualToString:@"DetectEventDetail"]) {
        IJTDetectEventDetailTableViewController *vc = [segue destinationViewController];
        NSIndexPath *index = [self.tableView indexPathForSelectedRow];
        if(self.searchController.active) {
            vc.detectEventDetail =
            [NSMutableDictionary dictionaryWithDictionary:self.searchResultDetectEventArray[index.row]];
        }
        else {
            vc.detectEventDetail =
            [NSMutableDictionary dictionaryWithDictionary:self.detectEventArray[index.row]];
        }
    }
}


@end
