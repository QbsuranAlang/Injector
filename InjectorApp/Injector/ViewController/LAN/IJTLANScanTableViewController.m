//
//  IJTLANScanTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/9/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTLANScanTableViewController.h"
#import "IJTLANDetailTableViewController.h"
#import "IJTLANOnlineTableViewCell.h"
#import "IJTLANTaskTableViewCell.h"

#define TIMEOUT 1000
struct bits {
    uint16_t	b_mask;
    char	b_val;
} lan_bits[] = {
    { IJTLANStatusFlagsMyself,	'M' },
    { IJTLANStatusFlagsGateway,	'G' },
    { IJTLANStatusFlagsArping,	'A' },
    { IJTLANStatusFlagsArpoison,   'O' },
    { IJTLANStatusFlagsDNS,     'D' },
    { IJTLANStatusFlagsMDNS,	'N' },
    { IJTLANStatusFlagsNetbios,	'B' },
    { IJTLANStatusFlagsPing,	'P' },
    { IJTLANStatusFlagsSSDP,	'S' },
    { IJTLANStatusFlagsLLMNR,   'L' },
    { IJTLANStatusFlagsFirewalled,   'F' },
    { 0 }
};

@interface IJTLANScanTableViewController ()

@property (nonatomic) BOOL scanning;
@property (nonatomic) BOOL cancle;
@property (nonatomic) BOOL arpScanning;

@property (nonatomic, strong) ASProgressPopUpView *progressView;
@property (nonatomic, strong) NSTimer *updateProgressViewTimer;

@property (nonatomic, strong) IJTArp_scan *arpScan;
@property (nonatomic, strong) NSThread *scanThread;
@property (nonatomic, strong) NSThread *mdnsThread;
@property (nonatomic, strong) NSThread *netbiosThread;
@property (nonatomic, strong) NSThread *pingThread;
@property (nonatomic, strong) NSThread *ssdpThread;
@property (nonatomic, strong) NSThread *dnsThread;
@property (nonatomic, strong) NSThread *llmnrThread;
@property (nonatomic, strong) NSThread *arpReadThread;
@property (nonatomic, strong) NSThread *ackScanThread;

@property (nonatomic, strong) NSString *gatewayAddress;
@property (nonatomic, strong) NSString *currentAddress;

@property (nonatomic, strong) NSMutableDictionary *taskInfoDict;
@property (atomic, strong) NSMutableArray *onlineArray;
@property (nonatomic, strong) NSMutableArray *searchResultOnlineArray;
@property (nonatomic, strong) NSThread *postThread;
@property (nonatomic) BOOL lessFlags;
@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation IJTLANScanTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 84;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.navigationItem.title = @"LAN";
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItem = self.dismissButton;
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopScan)];
    
    self.taskInfoDict = [[NSMutableDictionary alloc] init];
    [self.taskInfoDict setValue:[NSString stringWithFormat:@"%@ - %@", _startIp, _endIp] forKey:@"Range"];
    [self.taskInfoDict setValue:_bssid forKey:@"BSSID"];
    [self.taskInfoDict setValue:_ssid forKey:@"SSID"];
    
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        if(self.startScan) {
            [self scan];
        }
        else {
            [self addSearchBar];
            self.onlineArray = [[NSMutableArray alloc] init];
            NSMutableArray *insertArray = [[NSMutableArray alloc] init];
            for(NSInteger i = 0 ; i < _historyArray.count; i++) {
                NSDictionary *dict = _historyArray[i];
                [self.onlineArray addObject:dict];
                [insertArray addObject:[NSIndexPath indexPathForRow:i inSection:1]];
            }
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:insertArray withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView setContentOffset:CGPointMake(0,44) animated:NO];
        }
        [self showInfoMessage:@"Shake to switch flags display method."];
    }];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    self.lessFlags = [[user valueForKey:@"LANDisplayFlags"] boolValue];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:IJTLANColor];
#else
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTintColor:IJTLANColor];
#endif
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(!_startScan) {
        [self.tableView setContentOffset:CGPointMake(0,44) animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.searchController.active = NO;
}

- (void)addSearchBar {
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
    
    self.messageLabel.text = @"Search IP address, MAC address or Flags";
}

#pragma mark search bar
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.searchResultOnlineArray = [[NSMutableArray alloc] init];
    NSString *text = searchController.searchBar.text.uppercaseString;
    for(NSDictionary *dict in self.onlineArray) {
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        NSString *macAddress = [dict valueForKey:@"MacAddress"];
        NSNumber *flags = [dict valueForKey:@"Flags"];
        
        
        macAddress = macAddress.uppercaseString;
        
        if([ipAddress containsString:text]) {
            [self.searchResultOnlineArray addObject:dict];
        }
        if([macAddress containsString:text]) {
            [self.searchResultOnlineArray addObject:dict];
        }
        if([flags unsignedShortValue] & [self textToFlags:text]) {
            [self.searchResultOnlineArray addObject:dict];
        }
    }
    self.searchResultOnlineArray =
    [NSMutableArray arrayWithArray:[[NSSet setWithArray:self.searchResultOnlineArray] allObjects]];
    
    [self.tableView reloadData];
}

- (IJTLANStatusFlags)textToFlags: (NSString *)text {
    if([text isEqualToString:@"M"])
        return IJTLANStatusFlagsMyself;
    else if([text isEqualToString:@"G"])
        return IJTLANStatusFlagsGateway;
    else if([text isEqualToString:@"A"])
        return IJTLANStatusFlagsArping;
    else if([text isEqualToString:@"O"])
        return IJTLANStatusFlagsArpoison;
    else if([text isEqualToString:@"D"])
        return IJTLANStatusFlagsDNS;
    else if([text isEqualToString:@"N"])
        return IJTLANStatusFlagsMDNS;
    else if([text isEqualToString:@"B"])
        return IJTLANStatusFlagsNetbios;
    else if([text isEqualToString:@"P"])
        return IJTLANStatusFlagsPing;
    else if([text isEqualToString:@"S"])
        return IJTLANStatusFlagsSSDP;
    else if([text isEqualToString:@"L"])
        return IJTLANStatusFlagsLLMNR;
    else if([text isEqualToString:@"F"])
        return IJTLANStatusFlagsFirewalled;
    else
        return 0;
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


#pragma mark shake
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        _lessFlags = !_lessFlags;
        NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
        [user setValue:@(_lessFlags) forKey:@"LANDisplayFlags"];
        [user synchronize];
        
        [self.tableView reloadData];
    }//end if shake
}

- (void)dismissVC {
    if(_arpScan != nil) {
        [_arpScan close];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)stopScan {
    if(_scanThread != nil || _arpReadThread != nil || _mdnsThread != nil ||
       _netbiosThread != nil ||
       _pingThread != nil || _ssdpThread != nil || _dnsThread != nil ||
       _llmnrThread != nil || _ackScanThread != nil ||
       _updateProgressViewTimer != nil) {
        [self.stopButton setEnabled:NO];
        self.cancle = YES;
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            if(![_scanThread isFinished]) {
                while(_scanThread) {
                    usleep(100);
                }
            }
            if(![_arpReadThread isFinished]) {
                while(_arpReadThread) {
                    usleep(100);
                }
            }
            if(![_mdnsThread isFinished]) {
                while(_mdnsThread) {
                    usleep(100);
                }
            }
            if(![_netbiosThread isFinished]) {
                while(_netbiosThread) {
                    usleep(100);
                }
            }
            if(![_pingThread isFinished]) {
                while(_pingThread) {
                    usleep(100);
                }
            }
            if(![_ssdpThread isFinished]) {
                while(_ssdpThread) {
                    usleep(100);
                }
            }
            if(![_llmnrThread isFinished]) {
                while(_llmnrThread) {
                    usleep(100);
                }
            }
            if(![_ackScanThread isFinished]) {
                while(_ackScanThread) {
                    usleep(100);
                }
            }
            if(self.updateProgressViewTimer) {
                [self.updateProgressViewTimer invalidate];
                self.updateProgressViewTimer = nil;
            }
            [self.stopButton setEnabled:YES];
        }];
    }
}

- (void)postToDatabaseStore: (id)object {
    NSDate *date = object;
    NSString *json = [IJTJson array2string:_onlineArray];
    json = [IJTHTTP string2post:json];
    [IJTHTTP retrieveFrom:@"ReceiveLANScanHistory.php"
                     post:[NSString stringWithFormat:@"SerialNumber=%@&StartIpAddress=%@&EndIpAddress=%@&BSSID=%@&SSID=%@&Date=%ld&Data=%@", [IJTID serialNumber], _startIp, _endIp, [IJTHTTP string2post:_bssid], [IJTHTTP string2post:_ssid], (time_t)[date timeIntervalSince1970], json]
                  timeout:5
                    block:^(NSData *data) {
                        
                        NSString *result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                        
                        if([result integerValue] != IJTStatusServerSuccess) {
                            [self showErrorMessage:@"Fail to store to online database."];
                        }
                        self.postThread = nil;
                    }];
}

#pragma mark arp scan
- (void)scan {
    if(_arpScan == nil) {
        _arpScan = [[IJTArp_scan alloc] initWithInterface:@"en0"];
        if(_arpScan.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(_arpScan.errorCode)]];
            return;
        }
    }//end if
    
    self.scanning = YES;
    self.cancle = NO;
    
    self.currentAddress = [IJTNetowrkStatus currentIPAddress:@"en0"];
    [_arpScan setLAN];
    if(_arpScan.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"ARP-scan : %s.", strerror(_arpScan.errorCode)]];
        return;
    }
    
    self.onlineArray = [[NSMutableArray alloc] init];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    [self.dismissButton setEnabled:NO];
    
    //add progress view
    
    self.progressView = [IJTProgressView baseProgressPopUpView];
    self.progressView.dataSource = self;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:
                                      CGRectMake(0, 0, SCREEN_WIDTH, CGRectGetHeight(_progressView.frame))];
    [self.tableView setContentOffset:CGPointMake(0, -60) animated:YES];
    [self.tableView.tableHeaderView addSubview:self.progressView];
    
    //read inject and read
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        self.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(60, 0, 0, 0);
        [self.tableView setUserInteractionEnabled:NO];
        [self.tabBarController.tabBar setUserInteractionEnabled:NO];
        [[[[self.tabBarController tabBar] items] objectAtIndex:1] setEnabled:NO];
        self.scanThread = [[NSThread alloc] initWithTarget:self selector:@selector(scanLANThread) object:nil];
        [self.scanThread start];
        self.updateProgressViewTimer =
        [NSTimer scheduledTimerWithTimeInterval:0.01
                                         target:self
                                       selector:@selector(updateProgressView:)
                                       userInfo:nil repeats:YES];
    }];
    
}

- (void)scanLANThread {
    IJTRoutetable *route = [[IJTRoutetable alloc] init];
    if(route.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"%s.", strerror(route.errorCode)]];
        self.cancle = YES;
    }
    [route getGatewayByDestinationIpAddress:@"0.0.0.0"
                                     target:self
                                   selector:ROUTETABLE_SHOW_CALLBACK_SEL
                                     object:nil];
    [route close];
    
    //add my self
    if(_currentAddress) {
        NSString *macAddress = [IJTNetowrkStatus wifiMacAddress];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:_currentAddress forKey:@"IpAddress"];
        [dict setValue:macAddress forKey:@"MacAddress"];
        [dict setValue:@(IJTLANStatusFlagsMyself | IJTLANStatusFlagsArping | IJTLANStatusFlagsArpoison) forKey:@"Flags"];
        [dict setValue:[ALHardware deviceName] forKey:@"Self"];
        [self.onlineArray addObject:dict];
        [IJTDispatch dispatch_main:^{
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_onlineArray.count - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }];
    }//end if
    
    self.arpScanning = YES;
    self.arpReadThread = [[NSThread alloc] initWithTarget:self selector:@selector(arpReadTimeout) object:_onlineArray];
    [self.arpReadThread start];
    
    while([_arpScan getRemainInjectCount] != 0) {
        if(self.cancle)
            break;
        [_arpScan injectWithInterval:10000];
        
        if(_arpScan.errorHappened) {
            if(_arpScan.errorCode == ENOBUFS) {
                sleep(1);
            }
            else {
                [self showErrorMessage:[NSString stringWithFormat:@"ARP-scan : %s.", strerror(_arpScan.errorCode)]];
                break;
            }
        }
    }//end while arp scan
    self.arpScanning = NO;
    while(self.arpReadThread != nil)
        usleep(100);
    
    [_arpScan close];
    
    //oui
    NSMutableArray *macAddresses = [[NSMutableArray alloc] init];
    for(int i = 0 ; i < [_onlineArray count] ; i++) {
        NSMutableDictionary *dict = [_onlineArray objectAtIndex:i];
        [macAddresses addObject:[dict valueForKey:@"MacAddress"]];
    }
    NSArray *ouis = [IJTDatabase ouiArray:macAddresses];
    for(int i = 0 ; i < [_onlineArray count] ; i++) {
        NSMutableDictionary *dict = [_onlineArray objectAtIndex:i];
        [dict setValue:[ouis objectAtIndex:i] forKey:@"OUI"];
    }
    
    //sort
    for(int i = 0 ; i < _onlineArray.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSMutableDictionary *dict1 = _onlineArray[i];
            NSMutableDictionary *dict2 = _onlineArray[j];
            NSString *ipAddress1 = [dict1 valueForKey:@"IpAddress"];
            NSString *ipAddress2 = [dict2 valueForKey:@"IpAddress"];
            in_addr_t addr1, addr2;
            inet_pton(AF_INET, [ipAddress1 UTF8String], &addr1);
            inet_pton(AF_INET, [ipAddress2 UTF8String], &addr2);
            addr1 = ntohl(addr1);
            addr2 = ntohl(addr2);
            if(addr1 < addr2) {
                [_onlineArray exchangeObjectAtIndex:i withObjectAtIndex:j];
            }//end swap
        }//end for
    }//end for
    [IJTDispatch dispatch_main:^{
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
    
    if(self.cancle)
        goto DONE;
    
    //mdns
    self.mdnsThread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(mdnsInjectAndReadThread:)
                                                object:_onlineArray];
    [self.mdnsThread start];
    
    //netbios
    self.netbiosThread = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(netbiosInjectAndReadThread:)
                                                   object:_onlineArray];
    [self.netbiosThread start];
    
    //dns
    self.dnsThread = [[NSThread alloc] initWithTarget:self
                                             selector:@selector(dnsInjectAndReadThread:)
                                               object:_onlineArray];
    [self.dnsThread start];
    
    NSLog(@"mDNS NetBIOS DNS");
    while(_mdnsThread != nil || _netbiosThread != nil || _dnsThread != nil)
        usleep(100);
    
    //ping
    self.pingThread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(pingInjectAndReadThread:)
                                                object:_onlineArray];
    [self.pingThread start];
    
    //ssdp
    self.ssdpThread = [[NSThread alloc] initWithTarget:self
                                              selector:@selector(ssdpInjectAndReadThread:)
                                                object:_onlineArray];
    [self.ssdpThread start];
    
    //llmnr
    self.llmnrThread = [[NSThread alloc] initWithTarget:self
                                               selector:@selector(llmnrInjectAndReadThread:)
                                                 object:_onlineArray];
    [self.llmnrThread start];
    
    NSLog(@"ping SSDP LLMNR");
    while(_pingThread != nil || _ssdpThread != nil || _llmnrThread != nil)
        usleep(100);
    
    //ack scan
    self.ackScanThread = [[NSThread alloc] initWithTarget:self
                                                 selector:@selector(ackScanInjectAndReadThread:)
                                                   object:_onlineArray];
    [self.ackScanThread start];
    
    NSLog(@"ACK Scan");
    while(_ackScanThread != nil)
        usleep(100);
    
DONE:
    self.scanning = NO;
    [self.updateProgressViewTimer invalidate];
    self.updateProgressViewTimer = nil;
    
    [IJTDispatch dispatch_main:^{
        [self.stopButton setEnabled:NO];
        self.scanning = NO;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
        
        if(self.onlineArray.count > 0) {
            NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
            NSString *path = nil;
            if(geteuid()) {
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
                path = [NSString stringWithFormat:@"%@/%@", basePath, @"LANHistory"];
            }
            else {
                path = @"/var/root/Injector/LANHistory";
            }
            NSMutableArray *array = [NSMutableArray arrayWithContentsOfFile:path];
            if(array == nil) {
                array = [[NSMutableArray alloc] init];
            }
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setValue:_startIp forKey:@"StartIP"];
            [dict setValue:_endIp forKey:@"EndIP"];
            [dict setValue:_bssid forKey:@"BSSID"];
            [dict setValue:_ssid forKey:@"SSID"];
            [dict setValue:date forKey:@"Date"];
            [dict setValue:_onlineArray forKey:@"Data"];
            [array addObject:dict];
            [array writeToFile:path atomically:YES];
            
            [self.delegate callback];
            self.postThread = [[NSThread alloc] initWithTarget:self selector:@selector(postToDatabaseStore:) object:date];
            [self.postThread start];
        }
        
        [self.tableView setContentOffset:CGPointMake(0, 0) animated:YES];
        [self.dismissButton setEnabled:YES];
        [self.stopButton setEnabled:YES];
        [self.tableView setUserInteractionEnabled:YES];
        [self.tabBarController.tabBar setUserInteractionEnabled:YES];
        [[[[self.tabBarController tabBar] items] objectAtIndex:1] setEnabled:YES];
        self.navigationItem.rightBarButtonItems = nil;
        [self.progressView setProgress:1.0 animated:YES];
        [self.progressView removeFromSuperview];
        
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
            [self.tableView setContentOffset:CGPointMake(0,44) animated:NO];
            [self addSearchBar];
        }];
    }];
    self.scanThread = nil;
}

- (void)arpReadTimeout {
    while(_arpScanning) {
        //read who reply
        [_arpScan readTimeout:TIMEOUT*2
                       target:self
                     selector:ARPSCAN_CALLBACK_SEL
                       object:_onlineArray];
        if(self.cancle) {
            break;
        }
    }
    self.arpReadThread = nil;
}

ARPSCAN_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSMutableArray *list = [(NSMutableArray *)object copy];
        
        //dont dup
        for(int i = 0 ; i < [list count] ; i++) {
            NSDictionary *dict = [list objectAtIndex:i];
            if([[dict valueForKey:@"IpAddress"] isEqualToString:ipAddress])
                return;
        }
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:ipAddress forKey:@"IpAddress"];
        [dict setValue:macAddress forKey:@"MacAddress"];
        NSNumber *flags = nil;
        
        if([ipAddress isEqualToString:_gatewayAddress]) {
            flags = @(IJTLANStatusFlagsGateway | IJTLANStatusFlagsArping);
        }
        else if([ipAddress isEqualToString:_currentAddress]) {
            return;//skip my self
        }
        else {
            flags = @(IJTLANStatusFlagsArping);
        }
        
        //no arp proxy protect
        if([macAddress isEqualToString:etherSourceAddress]) {
            flags = [NSNumber numberWithUnsignedShort:[flags unsignedShortValue] | IJTLANStatusFlagsArpoison];
            [dict setValue:@(YES) forKey:@"arpoison"];
        }
        
        [dict setValue:flags forKey:@"Flags"];
        [_onlineArray addObject:dict];
        
        if(list.count < 15) {
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:list.count - 1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        }
    }];
}

ROUTETABLE_SHOW_CALLBACK_METHOD {
    if(![interface isEqualToString:@"en0"])
        return;
    
    if(type == IJTRoutetableTypeInet4 && [destinationIpAddress isEqualToString:@"0.0.0.0"]) {
        self.gatewayAddress = [NSString stringWithString:gateway];
    }
}

#pragma mark ack scan
- (void)ackScanInjectAndReadThread: (id)object {
    
    NSArray *list = object;
    IJTACK_Scan *ackScan = [[IJTACK_Scan alloc] init];
    if(ackScan.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"ACK Scan : %s.", strerror(ackScan.errorCode)]];
        self.ackScanThread = nil;
        return;
    }
    
    in_addr_t src_ip =
    [ackScan openSniffer];
    if(ackScan.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"ACK Scan : %s.", strerror(ackScan.errorCode)]];
        [ackScan close];
        self.ackScanThread = nil;
        return;
    }
    
    NSArray *listCopy = [list copy];
    for(NSDictionary *dict in listCopy) {
        if(self.cancle)
            break;
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        [ackScan injectTarget:ipAddress
                         stop:&_cancle
                         port:22
                       src_ip:src_ip];
        usleep(100);
    }
    NSArray *unfiltered = [ackScan readPort:22
                                    timeout:TIMEOUT];
    
    for(NSDictionary *dict in listCopy) {
        if(self.cancle)
            break;
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        BOOL found = NO;
        for(NSString *ipAddress2 in unfiltered) {
            if(self.cancle)
                break;
            if([ipAddress isEqualToString:ipAddress2]) {
                found = YES;
                break;
            }
        }//end
        if(!found) {
            [IJTDispatch dispatch_main:^{
                [self setValue:@(YES) forKey:@"Firewalled" ipAddress:ipAddress flags:IJTLANStatusFlagsFirewalled withObject:object];
            }];
        }//end if not found
    }//end for
    
    [ackScan close];
    self.ackScanThread = nil;
}

#pragma mark llmnr scan
- (void)llmnrInjectAndReadThread: (id)object {
    NSArray *list = object;
    
    IJTLLMNR *llmnr = [[IJTLLMNR alloc] init];
    if(llmnr.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"LLMNR : %s.", strerror(llmnr.errorCode)]];
        self.mdnsThread = nil;
        return;
    }
    
    [llmnr setReadUntilTimeout:YES];
    
    NSArray *listCopy = [list copy];
    for(NSDictionary *dict in listCopy) {
        if(self.cancle)
            break;
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        
        [llmnr setOneTarget:ipAddress];
        [llmnr injectWithInterval:100];
        if(llmnr.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"LLMNR : %s.", strerror(llmnr.errorCode)]];
            if(llmnr.errorCode == ENOBUFS) {
                sleep(1);
            }
            else
                break;
        }
    }
    
    [llmnr readTimeout:TIMEOUT
                target:self
              selector:LLMNR_PTR_CALLBACK_SEL
                object:_onlineArray];
    [llmnr close];
    self.llmnrThread = nil;
}

LLMNR_PTR_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        [self setValue:resolveHostname forKey:@"LLMNRName" ipAddress:ipAddress flags:IJTLANStatusFlagsLLMNR withObject:object];
    }];
}

#pragma mark dns
- (void)dnsInjectAndReadThread: (id)object {
    NSArray *list = object;
    NSMutableArray *dnsServer = [[NSMutableArray alloc] init];
    [IJTDNS getDNSListRegisterTarget:self selector:DNS_LIST_CALLBACK_SEL object:dnsServer];
    if(dnsServer.count <= 0) {
        self.dnsThread = nil;
        return;
    }
    IJTDNS *dns = [[IJTDNS alloc] init];
    if(dns.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"DNS : %s.", strerror(dns.errorCode)]];
        self.dnsThread = nil;
        return;
    }
    [dns setReadUntilTimeout:YES];
    
    NSString *server = [dnsServer firstObject];
    NSArray *listCopy = [list copy];
    for(NSDictionary *dict in listCopy) {
        if(self.cancle)
            break;
        
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        
        [dns injectWithInterval:100 server:server ipAddress:ipAddress];
    }
    [dns readTimeout:TIMEOUT target:self selector:DNS_PTR_CALLBACK_SEL object:_onlineArray];
    [dns close];
    self.dnsThread = nil;
}

DNS_PTR_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        [self setValue:resolveHostname forKey:@"DNSName" ipAddress:ipAddress flags:IJTLANStatusFlagsDNS withObject:object];
    }];
}

DNS_LIST_CALLBACK_METHOD {
    NSMutableArray *list = (NSMutableArray *)object;
    [list addObject:ipAddress];
}

#pragma mark ssdp scan
- (void)ssdpInjectAndReadThread: (id)object {
    if(self.cancle) {
        self.ssdpThread = nil;
        return;
    }
    
    IJTSSDP *ssdp = [[IJTSSDP alloc] init];
    if(ssdp.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"SSDP : %s.", strerror(ssdp.errorCode)]];
        self.ssdpThread = nil;
        return;
    }
    [ssdp injectTargetIpAddress:SSDP_MULTICAST_ADDR
                        timeout:TIMEOUT
                         target:self
                       selector:SSDP_CALLBACK_SEL
                         object:_onlineArray];
    if(ssdp.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"SSDP : %s.", strerror(ssdp.errorCode)]];
    }
    [ssdp close];
    self.ssdpThread = nil;
}

SSDP_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        [self setValue:product forKey:@"SSDPName" ipAddress:sourceIpAddress flags:IJTLANStatusFlagsSSDP withObject:object];
    }];
}

#pragma mark ping scan
- (void)pingInjectAndReadThread: (id)object {
    NSArray *list = object;
    IJTPing *ping = [[IJTPing alloc] init];
    if(ping.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"ping : %s.", strerror(ping.errorCode)]];
        self.pingThread = nil;
        return;
    }
    NSArray *listCopy = [list copy];
    for(NSDictionary *dict in listCopy) {
        if(self.cancle)
            break;
        
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        [ping setTarget:ipAddress];
        
        int ret =
        [ping injectWithInterval:100];
        if(ret == -1) {
            [self showErrorMessage:[NSString stringWithFormat:@"ping : %s.", strerror(ping.errorCode)]];
            if(ping.errorCode == ENOBUFS) {
                sleep(1);
            }
            else
                break;
        }
    }//end for
    
    [ping readTimeout:TIMEOUT
               target:self
             selector:PING_CALLBACK_SEL
               object:_onlineArray];
    
    [ping close];
    self.pingThread = nil;
}

PING_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        [self setValue:@(YES) forKey:@"Ping" ipAddress:replyIpAddress flags:IJTLANStatusFlagsPing withObject:object];
    }];
}

#pragma mark netbios scan
- (void)netbiosInjectAndReadThread: (id)object {
    NSArray *list = object;
    IJTNetbios *netbios = [[IJTNetbios alloc] init];
    if(netbios.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"NetBIOS : %s.", strerror(netbios.errorCode)]];
        self.netbiosThread = nil;
        return;
    }
    [netbios setReadUntilTimeout:YES];
    
    NSArray *listCopy = [list copy];
    for(NSDictionary *dict in listCopy) {
        if(self.cancle)
            break;
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        
        [netbios setOneTarget:ipAddress];
        [netbios injectWithInterval:100];
        if(netbios.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"NetBIOS : %s.", strerror(netbios.errorCode)]];
            if(netbios.errorCode == ENOBUFS) {
                sleep(1);
            }
            else
                break;
        }
    }//end for
    
    
    [netbios readTimeout:TIMEOUT
                  target:self
                selector:NETBIOS_CALLBACK_SEL
                  object:_onlineArray];
    [netbios close];
    self.netbiosThread = nil;
}

NETBIOS_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        NSString *nameString = @"";
        for(NSString *name in netbiosNames) {
            if(nameString.length <= 0) {
                nameString = [NSString stringWithString:name];
            }
            else {
                nameString = [nameString stringByAppendingString:[NSString stringWithFormat:@"\n%@", name]];
            }
        }//end for
        
        NSString *groupString = @"";
        for(NSString *name in groupNames) {
            if(groupString.length <= 0) {
                groupString = [NSString stringWithString:name];
            }
            else {
                groupString = [groupString stringByAppendingString:[NSString stringWithFormat:@"\n%@", name]];
            }
        }//end for
        [self setValue:nameString forKey:@"netbiosName" ipAddress:sourceIpAddress flags:IJTLANStatusFlagsNetbios withObject:object];
        
        [self setValue:groupString forKey:@"netbiosGroup" ipAddress:sourceIpAddress flags:IJTLANStatusFlagsNetbios withObject:object];
    }];
}

#pragma mark mdns scan
- (void)mdnsInjectAndReadThread: (id)object {
    NSArray *list = object;
    
    IJTMDNS *mdns = [[IJTMDNS alloc] init];
    if(mdns.errorHappened) {
        [self showErrorMessage:[NSString stringWithFormat:@"mDNS : %s.", strerror(mdns.errorCode)]];
        self.mdnsThread = nil;
        return;
    }
    
    [mdns setReadUntilTimeout:YES];
    
    NSArray *listCopy = [list copy];
    for(NSDictionary *dict in listCopy) {
        if(self.cancle)
            break;
        NSString *ipAddress = [dict valueForKey:@"IpAddress"];
        
        [mdns setOneTarget:ipAddress];
        [mdns injectWithInterval:100];
        if(mdns.errorHappened) {
            [self showErrorMessage:[NSString stringWithFormat:@"mDNS : %s.", strerror(mdns.errorCode)]];
            if(mdns.errorCode == ENOBUFS) {
                sleep(1);
            }
            else
                break;
        }
    }
    
    [mdns readTimeout:TIMEOUT
               target:self
             selector:MDNS_PTR_CALLBACK_SEL
               object:_onlineArray];
    [mdns close];
    self.mdnsThread = nil;
}

MDNS_PTR_CALLBACK_METHOD {
    [IJTDispatch dispatch_main:^{
        [self setValue:resolveHostname forKey:@"mDNSName" ipAddress:ipAddress flags:IJTLANStatusFlagsMDNS withObject:object];
    }];
}

- (void)setValue: (id)value forKey: (NSString *)key ipAddress: (NSString *)ipAddress flags: (IJTLANStatusFlags)flag withObject: (id)object {
    int index = 0;
    NSMutableArray *list = [(NSMutableArray *)object copy];
    NSMutableDictionary *dict = nil;
    for(index = 0; index < list.count ; index++) {
        dict = list[index];
        if([[dict valueForKey:@"IpAddress"] isEqualToString:ipAddress]) {
            break;
        }
    }//end for search array
    
    //out of range
    if(index == list.count)
        return;
    
    NSNumber *flagNumber = [dict valueForKey:@"Flags"];
    
    [dict setValue:value forKey:key];
    [dict setValue:[NSNumber numberWithUnsignedShort:[flagNumber unsignedShortValue] | flag] forKey:@"Flags"];
    
    if(index < 15) {
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }
}

#pragma mark - ASProgressPopUpView dataSource

- (void)updateProgressView: (id)sender {
    u_int64_t total = [_arpScan getTotalInjectCount];
    u_int64_t remain = [_arpScan getRemainInjectCount];
    float value = (total - remain)/(float)total;
    
    [self.progressView setProgress:value animated:YES];
}

// <ASProgressPopUpViewDataSource> is entirely optional
// it allows you to supply custom NSStrings to ASProgressPopUpView
- (NSString *)progressView:(ASProgressPopUpView *)progressView stringForProgress:(float)progress
{
    NSString *s;
    if(progress == 0.0)
        return @"Initializing...";
    else if(progress < 0.99) {
        u_int64_t count = [_arpScan getRemainInjectCount];
        s = [NSString stringWithFormat:@"Left : %lu(%2d%%)", (unsigned long)count, (int)(progress*100)%100];
    }
    else {
        s = @"Querying with tool...";
    }
    return s;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 1;
    else if(section == 1) {
        
        if(self.searchController.active) {
            if(self.searchResultOnlineArray.count == 0) {
                [self.tableView addSubview:self.messageLabel];
            }
            else {
                [self.messageLabel removeFromSuperview];
            }
            return self.searchResultOnlineArray.count;
        }
        else {
            [self.messageLabel removeFromSuperview];
            return self.onlineArray.count;
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTLANTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"Range"
                         label:cell.rangeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"BSSID"
                         label:cell.bssidLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        
        [IJTFormatUILabel dict:_taskInfoDict
                           key:@"SSID"
                         label:cell.ssidLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTLANOnlineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OnlineCell" forIndexPath:indexPath];
        NSDictionary *dict = nil;
        if(self.searchController.active) {
            dict = _searchResultOnlineArray[indexPath.row];
        }
        else {
            dict = _onlineArray[indexPath.row];
        }
        
        NSString *nameKey = @"None";
        UIColor *nameColor = IJTValueColor;
        NSNumber *flagsNumner = [dict valueForKey:@"Flags"];
        
        if([dict valueForKey:@"DNSName"]) {
            nameKey = @"DNSName";
        }
        else if([dict valueForKey:@"LLMNRName"]) {
            nameKey = @"LLMNRName";
        }
        else if([dict valueForKey:@"mDNSName"]) {
            nameKey = @"mDNSName";
        }
        else if([dict valueForKey:@"netbiosName"]) {
            nameKey = @"netbiosName";
        }
        else if([dict valueForKey:@"SSDPName"]) {
            nameKey = @"SSDPName";
        }
        else if([dict valueForKey:@"Self"]) {
            nameKey = @"Self";
        }
        else {
            nameColor = [UIColor lightGrayColor];
        }
        
        [IJTFormatUILabel dict:dict
                           key:nameKey
                         label:cell.nameLabel
                         color:nameColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"IpAddress"
                         label:cell.ipAddressLabel
                         color:[UIColor darkGrayColor]
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"MacAddress"
                         label:cell.macAddressLabel
                         color:[UIColor darkGrayColor]
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"OUI"
                         label:cell.ouiLabel
                         color:[UIColor lightGrayColor]
                          font:[UIFont systemFontOfSize:11]];
        
        [self drawStatusAtView:cell.statusView flags:[flagsNumner unsignedShortValue]];

        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

- (void)drawStatusAtView: (UIView *)view flags:(IJTLANStatusFlags)flags {
    
    [[view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    view.backgroundColor = [UIColor clearColor];
    
    CGFloat height = CGRectGetHeight(view.frame);
    CGFloat width = CGRectGetHeight(view.frame)*4./5.;
    CGFloat xposition = 0;
    struct bits *p = NULL;
    for (p = lan_bits; p->b_mask; p++) {
        if (p->b_mask & flags) {
            
            FUIButton *button = [[FUIButton alloc] initWithFrame:CGRectMake(xposition, 0, width, height)];
            [button setTitle:[NSString stringWithFormat:@"%c", p->b_val] forState:UIControlStateNormal];
            [button.titleLabel setFont:[UIFont systemFontOfSize:12]];
            button.cornerRadius = 3.0f;
            button.shadowHeight = 2.0f;
            [view addSubview:button];
            xposition += width + 1;
            
            button.buttonColor = [self statusColor:p->b_mask];
            button.shadowColor = [IJTColor darker:[self statusColor:p->b_mask] times:1];
            [button setEnabled:YES];
        }
        else if(!_lessFlags) {
            
            FUIButton *button = [[FUIButton alloc] initWithFrame:CGRectMake(xposition, 0, width, height)];
            [button setTitle:[NSString stringWithFormat:@"%c", p->b_val] forState:UIControlStateNormal];
            [button.titleLabel setFont:[UIFont systemFontOfSize:12]];
            button.cornerRadius = 3.0f;
            button.shadowHeight = 2.0f;
            [view addSubview:button];
            xposition += width + 1;
            
            button.buttonColor = [UIColor paperColorGray600];
            button.shadowColor = [IJTColor darker:[UIColor paperColorGray600] times:1];
            [button setEnabled:NO];
        }
    }//end for each bits
}

- (UIColor *)statusColor: (IJTLANStatusFlags)flag {
    switch (flag) {
        case IJTLANStatusFlagsMyself: return [UIColor sunflowerColor];
        case IJTLANStatusFlagsGateway: return [UIColor carrotColor];
        case IJTLANStatusFlagsArping: return [UIColor alizarinColor];
        case IJTLANStatusFlagsDNS: return [UIColor paperColorPurple300];
        case IJTLANStatusFlagsMDNS: return [UIColor peterRiverColor];
        case IJTLANStatusFlagsNetbios: return [UIColor paperColorBrown500];
        case IJTLANStatusFlagsPing: return [UIColor nephritisColor];
        case IJTLANStatusFlagsSSDP: return [UIColor paperColorIndigo500];
        case IJTLANStatusFlagsLLMNR: return [UIColor paperColorGray800];
        case IJTLANStatusFlagsFirewalled: return [UIColor paperColorPink200];
        case IJTLANStatusFlagsArpoison: return [UIColor paperColorTeal300];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Target LAN Information";
    }
    else if(section == 1) {
        if(self.scanning)
            return @"Online";
        else {
            if(self.searchController.active) {
                return [NSString stringWithFormat:@"Search Online(%lu)", (unsigned long)_searchResultOnlineArray.count];
            }
            else {
                return [NSString stringWithFormat:@"Online(%lu)", (unsigned long)_onlineArray.count];
            }
        }
    }
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 1) {
        IJTLANDetailTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"LANDetailVC"];
        if(self.searchController.active) {
            vc.dict = [NSMutableDictionary dictionaryWithDictionary:_searchResultOnlineArray[indexPath.row]];
        }
        else {
            vc.dict = [NSMutableDictionary dictionaryWithDictionary:_onlineArray[indexPath.row]];
        }
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
