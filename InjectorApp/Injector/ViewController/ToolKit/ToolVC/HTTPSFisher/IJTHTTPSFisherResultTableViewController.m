//
//  IJTHTTPSFisherResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/12/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTHTTPSFisherResultTableViewController.h"
#import "IJTHTTPSFisherTaskTableViewCell.h"
#import "IJTHTTPSFisherEventTableViewCell.h"
@interface IJTHTTPSFisherResultTableViewController ()

@property (atomic, strong) UIBarButtonItem *startButton;
@property (atomic, strong) IJTHTTPSFisher *fisher;
@property (atomic, strong) Reachability *wifiReachability;
@property (atomic, strong) NSMutableArray *eventArray;
@property (atomic) BOOL fishing;
@property (atomic, strong) NSThread *serverThread;

@property (atomic, strong) NSTimer *updateTableViewTimer;
@property (atomic) NSInteger currentCellIndex;
@property (atomic) BOOL cancle;
@property (atomic, strong) NSMutableArray *connectArray;

@end

@implementation IJTHTTPSFisherResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"HTTPS Fisher";
    
    //self size
    self.tableView.estimatedRowHeight = 50;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.startButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"HTTPS FisherNav.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(startFishing)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopFishing)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_startButton, nil];
    
    self.fisher = [[IJTHTTPSFisher alloc] init];
    [self.fisher setDelegate:self];
    if(self.savepackets) {
        [self.fisher setNeedSavefileAndFilter:[NSString stringWithFormat:@"host not %@ && port 443", _redirectIpAddress]];
    }
    
    self.messageLabel.text = @"Click icon to fishing";
    
    
    self.messageLabel.text = [NSString stringWithFormat:@"Redirect to : %@(%@)", _rediectHostname, _redirectIpAddress];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
    if([IJTNetowrkStatus supportWifi]) {
        self.wifiReachability = [IJTNetowrkStatus wifiReachability];
        [self.wifiReachability startNotifier];
        [self reachabilityChanged:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if([IJTNetowrkStatus supportWifi])
        [self.wifiReachability stopNotifier];
}

- (void)dismissVC {
    self.fisher = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)startFishing {
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    self.eventArray = [[NSMutableArray alloc] init];
    self.connectArray = [[NSMutableArray alloc] init];
    self.currentCellIndex = 0;
    self.fishing = YES;
    self.cancle = NO;
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    [self.dismissButton setEnabled:NO];
    
    self.updateTableViewTimer =
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(updateTableView)
                                   userInfo:nil repeats:YES];

    self.serverThread = [[NSThread alloc] initWithTarget:self selector:@selector(startFishingThread) object:nil];
    [self.serverThread start];
}

- (void)startFishingThread {
    [IJTDispatch dispatch_global:IJTDispatchPriorityHigh block:^{
        [self.fisher redirectTo:_redirectIpAddress hostname:_rediectHostname];
        [self.fisher start];
        _cancle = YES;
    }];
    while (!_cancle) {
        usleep(100);
    }
    
    usleep(1500000);
    
    self.serverThread = nil;
    
    if(self.updateTableViewTimer) {
        [self.updateTableViewTimer invalidate];
        self.updateTableViewTimer = nil;
    }
    
    [IJTDispatch dispatch_main:^{
        [self.dismissButton setEnabled:YES];
        [self.stopButton setEnabled:YES];
        self.fishing = NO;
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_startButton, nil];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

- (void)stopFishing {
    [self.stopButton setEnabled:NO];
    [self.fisher stop];
    self.cancle = YES;
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        if(self.updateTableViewTimer) {
            [self.updateTableViewTimer invalidate];
            self.updateTableViewTimer = nil;
        }
    }];
}

- (void)updateTableView {
    NSMutableArray *needInsert = [[NSMutableArray alloc] init];
    NSUInteger count = _eventArray.count;
    for(; _currentCellIndex < count ; _currentCellIndex++) {
        [needInsert addObject:[NSIndexPath indexPathForRow:_currentCellIndex inSection:1]];
    }
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:needInsert withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    if(needInsert.count != 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_currentCellIndex - 1 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

#pragma https fisher delegate

- (void)IJTHTTPSFisherAcceptClientFailure:(NSString *)message {
    [self insertEvent:[NSString stringWithFormat:@"Accept client failure: %@.", message] red:YES];
    [self showErrorMessage:[NSString stringWithFormat:@"Accept client failure: %@.", message]];
}

- (void)IJTHTTPSFisherClientCertificateUsing:(NSString *)cipher subject:(NSString *)subject issuer:(NSString *)issuer {
    [self insertEvent:[NSString stringWithFormat:@"Client use:\nCipher: %@\nSubject: %@\nIssuer: %@", cipher, subject, issuer] red:NO];
}

- (void)IJTHTTPSFisherClientConnectionClosedIpAddress:(NSString *)ipAddress port:(u_int16_t)port {
    if([self.connectArray containsObject:ipAddress]) {
        [self.connectArray removeObject:ipAddress];
        [self insertEvent:[NSString stringWithFormat:@"%@ connection is closed.", ipAddress] red:NO];
    }
}

- (void)IJTHTTPSFisherClientConnectionEstablishedIpAddress:(NSString *)ipAddress port:(u_int16_t)port {
    if(![self.connectArray containsObject:ipAddress]) {
        [self.connectArray addObject:ipAddress];
        [self insertEvent:[NSString stringWithFormat:@"%@ connection is established.", ipAddress] red:NO];
    }
}

- (void)IJTHTTPSFisherExchangeDataFailure:(NSString *)message {
    [self insertEvent:[NSString stringWithFormat:@"Exchange data failure: %@.", message] red:YES];
    [self showErrorMessage:[NSString stringWithFormat:@"Exchange data failure: %@.", message]];
}

- (void)IJTHTTPSFisherForkFailure:(NSString *)message {
    [self insertEvent:[NSString stringWithFormat:@"Fork failure: %@.", message] red:YES];
    [self showErrorMessage:[NSString stringWithFormat:@"Fork failure: %@.", message]];
}

- (void)IJTHTTPSFisherGeneratedSSLKeyFailure {
    [self insertEvent:@"Generate certificate key failure." red:YES];
    [self showErrorMessage:@"Generate certificate key failure."];
}

- (void)IJTHTTPSFisherGeneratedCertificate:(NSString *)certificate publicKey:(NSString *)publicKey privateKey:(NSString *)privateKey {
    [self insertEvent:[NSString stringWithFormat:@"Certificate using: \n%@\nPublic key using: \n%@\nPrivate key using: \n%@", certificate, publicKey, privateKey] red:NO];
}

- (void)IJTHTTPSFisherGeneratingSSLKey {
    [self insertEvent:@"Start generating certificate..." red:NO];
}

- (void)IJTHTTPSFisherHandleClientFailure:(NSString *)message {
    [self insertEvent:[NSString stringWithFormat:@"Handle client failure: %@.", message] red:YES];
    [self showErrorMessage:[NSString stringWithFormat:@"Handle client failure: %@.", message]];
}

- (void)IJTHTTPSFisherInitSecuritySocketServerFailure:(NSString *)message {
    [self insertEvent:[NSString stringWithFormat:@"Initializing security socket server failure: %@.", message] red:YES];
    [self showErrorMessage:[NSString stringWithFormat:@"Initializing security socket server failure: %@.", message]];
}

- (void)IJTHTTPSFisherRetrieveRedirectHostCertificateFailure:(NSString *)message {
    [self insertEvent:[NSString stringWithFormat:@"Retrieve redirect host certificate failure: %@.", message] red:YES];
    [self showErrorMessage:[NSString stringWithFormat:@"Retrieve redirect host certificate failure: %@.", message]];
}

- (void)IJTHTTPSFisherSavePacketFilename:(NSString *)filename {
    [self insertEvent:[NSString stringWithFormat:@"Save to: %@", filename] red:NO];
}

- (void)IJTHTTPSFisherSaveToFileDone:(NSString *)filename outputLocation:(NSString *)outputLocation {
    [self insertEvent:[NSString stringWithFormat:@"File location: %@", outputLocation] red:NO];
}

- (void)IJTHTTPSFisherSaveToFileFailure:(NSString *)message {
    [self insertEvent:[NSString stringWithFormat:@"Saving file failure: %@.", message] red:YES];
    [self showErrorMessage:[NSString stringWithFormat:@"Saving file failure: %@.", message]];
}

- (void)IJTHTTPSFisherSendToServerData:(char *)data length:(int)length modify:(BOOL)modify {
    /*__block NSString *string = [NSString stringWithUTF8String:data];
    [IJTDispatch dispatch_main:^{
        if ([self dataContain:string]) {
            NSLog(@"%@", string);
            if([string containsString:@"&"] && [string containsString:@"="]) {
                [self insertEvent:[NSString stringWithFormat:@"Data maybe contain username or password:\n%@", string]
                              red:YES];
                [self showWarningMessage:@"Data maybe contain username or password."];
            }
        }
    }];*/
}


- (BOOL)dataContain: (NSString *)string {
    NSArray *search = @[@"username", @"pass", @"email"];
    BOOL found = NO;
    for(NSString *s in search) {
        if([string localizedCaseInsensitiveContainsString:s]) {
            found = YES;
            break;
        }//end if found
    }//end for
    return found;
}

- (void)IJTHTTPSFisherReceivePOSTData:(char *)data length:(int)length {
    NSArray *header = nil;
    __block NSString *body = nil;
    NSArray *bodyArray = nil;
    NSMutableString *string = [[NSMutableString alloc] init];
    [IJTHTTPSFisher decodeNSData:data length:length HTTPHeader:&header HTTPBody:&body];
    
    for(NSString *s in header) {
        [string appendFormat:@"%@\n", s];
    }//end for header
    [string appendString:@"\n"];
    
    bodyArray = [body componentsSeparatedByString:@"&"];
    for(NSString *s in bodyArray) {
        [string appendFormat:@"%@\n", s];
    }//end for body
    
    [self insertEvent:[IJTHTTPSFisher httpPost2string:string] red:YES];
    [IJTDispatch dispatch_main:^{
        if ([self dataContain:body]) {
            [self showWarningMessage:@"Data maybe contain username or password."];
        }
    }];
}

- (void)IJTHTTPSFisherServerCertificateUsing:(NSString *)cipher subject:(NSString *)subject issuer:(NSString *)issuer {
    [self insertEvent:[NSString stringWithFormat:@"Redirect host use:\nCipher: %@\nSubject: %@\nIssuer: %@", cipher, subject, issuer] red:NO];
}

- (void)IJTHTTPSFisherClientSentData:(char *)data length:(int)length {
    
}

- (void)IJTHTTPSFisherServerSentData:(char *)data length:(int)length {
    
}

- (void)IJTHTTPSFisherSendToClientData:(char *)data length:(int)length modify:(BOOL)modify {
    
}

- (void)IJTHTTPSFisherServerStart {
    [self insertEvent:@"Server start." red:NO];
}

- (void)IJTHTTPSFisherServerStop {
    [self insertEvent:@"Server stop." red:NO];
}

- (void)insertEvent: (NSString *)event red: (BOOL)red {
    if(event.length <= 0) {
        return;
    }
    
    struct timeval time;
    gettimeofday(&time, NULL);
    
    [self.eventArray addObject:@{@"Time": [IJTFormatString formatTimestamp:time secondsPadding:3 decimalPoint:3],
                                 @"Event": event,
                                 @"Red": @(red)}];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note {
    if(self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWiFiOnlyNoteWithToolName:@"HTTPS Fisher"];
        [self.startButton setEnabled:NO];
        [self stopFishing];
    }
    else if(self.wifiReachability.currentReachabilityStatus == ReachableViaWiFi) {
        [self.startButton setEnabled:YES];
    }
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(self.eventArray.count == 0) {
        [self.tableView addSubview:self.messageLabel];
    }
    else {
        [self.messageLabel removeFromSuperview];
    }
    
    if(section == 0)
        return 1;
    else if(section == 1)
        return self.eventArray.count;
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        IJTHTTPSFisherTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel text:_rediectHostname
                         label:cell.hostnameLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel text:_redirectIpAddress
                         label:cell.ipAddressLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1) {
        IJTHTTPSFisherEventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EventCell" forIndexPath:indexPath];
        
        NSDictionary *dict = _eventArray[indexPath.row];
        
        [IJTFormatUILabel text:[NSString stringWithFormat:@"%d", (int)indexPath.row + 1]
                         label:cell.indexLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Time"
                         label:cell.timeLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel dict:dict
                           key:@"Event"
                         label:cell.eventLabel
                         color:[[dict valueForKey:@"Red"] boolValue] ? IJTErrorMessageColor : IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0) {
        return @"Task Information";
    }
    else if (section == 1) {
        if(self.fishing)
            return @"Event";
        else
            return [NSString stringWithFormat:@"Event(%lu)", (unsigned long)_eventArray.count];
    }
    return @"";
}

@end
