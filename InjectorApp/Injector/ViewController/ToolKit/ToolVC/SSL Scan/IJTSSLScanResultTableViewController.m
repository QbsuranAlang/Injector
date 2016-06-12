//
//  IJTSSLScanResultTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/12/16.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTSSLScanResultTableViewController.h"
#import "IJTSSLScanTaskTableViewCell.h"
#import "IJTSSLScanErrorTableViewCell.h"
#import "IJTSSLScanCiphersTableViewCell.h"
#import "IJTSSLScanEventTableViewCell.h"
@interface IJTSSLScanResultTableViewController ()

@property (nonatomic, strong) UIBarButtonItem *scanButton;
@property (nonatomic, strong) IJTSSLScan *sslScan;
@property (nonatomic, strong) NSThread *scanThread;
@property (nonatomic) BOOL cancle;
@property (nonatomic, strong) NSMutableArray *clientCipherArray;
@property (nonatomic, strong) NSMutableArray *renegotiationArray;
@property (nonatomic, strong) NSMutableArray *compressionArray;
@property (nonatomic, strong) NSMutableArray *heartbleedArray;
@property (nonatomic, strong) NSMutableArray *serverCipherArray;
@property (nonatomic, strong) NSMutableArray *showCertificateArray;
@property (nonatomic, strong) NSMutableArray *showTrustedCAsArray;

@property (nonatomic, strong) NSArray *messageArray;
@property (nonatomic) BOOL scanning;

@end

@implementation IJTSSLScanResultTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"SSL Scan";
    
    //self size
    self.tableView.estimatedRowHeight = 45;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"left.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, self.multiToolButton, nil];
    
    self.scanButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"SSL ScanNav.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(startScan)];
    
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopScan)];
    
    self.navigationItem.rightBarButtonItem = self.scanButton;
    
    self.messageLabel.text = [NSString stringWithFormat:@"%@:%d", _target, _port];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissVC {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark SSL scan
- (void)IJTSSLScanConnectTimeout {
    [self showErrorMessage:@"Timeout"];
}

- (void)IJTSSLScanCreateSocketFailure:(NSString *)message {
    [self showErrorMessage:message];
    [IJTDispatch dispatch_main:^{
        [self stopScan];
    }];
}

- (void)IJTSSLScanResolveHostnameFailure:(NSString *)message {
    [self showErrorMessage:message];
    [IJTDispatch dispatch_main:^{
        [self stopScan];
    }];
}

//section 1
- (void)IJTSSLScanPopulateCipherFailure:(NSString *)message {
    [self showErrorMessage:message];
    
    [IJTDispatch dispatch_main:^{
        [_clientCipherArray addObject:[self getErrorDictionaryMessage:message]];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

- (void)IJTSSLScanSupportedClientCiphers:(NSArray *)ciphers {
    [IJTDispatch dispatch_main:^{
        for(NSMutableDictionary *dict in ciphers) {
            NSNumber *bits = [dict valueForKey:@"Bits"];
            [dict setValue:[NSString stringWithFormat:@"%d bits", [bits intValue]] forKey:@"Bits"];
            [_clientCipherArray addObject:dict];
        }//end for
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

//section 2
- (void)IJTSSLScanTestRenegotiationFailure:(NSString *)message {
    [self showErrorMessage:message];
    
    [IJTDispatch dispatch_main:^{
        [_renegotiationArray addObject:[self getErrorDictionaryMessage:message]];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

- (void)IJTSSLScanTestRenegotiationResultMessage:(NSString *)message insecure:(BOOL)insecure {
    [IJTDispatch dispatch_main:^{
        NSDictionary *dict = @{@"Message": message,
                               @"Red": @(insecure)};
        
        [_renegotiationArray addObject:dict];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

//section 3
- (void)IJTSSLScanTestCompressionFailure:(NSString *)message {
    [self showErrorMessage:message];
    
    [IJTDispatch dispatch_main:^{
        [_compressionArray addObject:[self getErrorDictionaryMessage:message]];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

- (void)IJTSSLScanTestCompressionResultMessage:(NSString *)message disable:(BOOL)disable {
    [IJTDispatch dispatch_main:^{
        NSDictionary *dict = @{@"Message": message,
                               @"Red": @(!disable)};
        
        [_compressionArray addObject:dict];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

//section 4
- (void)IJTSSLScanTestHeartbleedFailure:(NSString *)message {
    [self showErrorMessage:message];
    
    [IJTDispatch dispatch_main:^{
        [_heartbleedArray addObject:[self getErrorDictionaryMessage:message]];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

- (void)IJTSSLScanTestHeartbleedResultVersion:(NSString *)version vulnerable:(BOOL)vulnerable {
    [IJTDispatch dispatch_main:^{
        NSString *message = @"";
        if(vulnerable) {
            message = [NSString stringWithFormat:@"%@ vulnerable to heartbleed", version];
        }
        else {
            message = [NSString stringWithFormat:@"%@ not vulnerable to heartbleed", version];
        }
        
        NSDictionary *dict = @{@"Message": message,
                               @"Red": @(vulnerable)};
        
        [_heartbleedArray addObject:dict];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_heartbleedArray.count - 1 inSection:4]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

//section 5
- (void)IJTSSLScanTestSupportedServerCiphersFailure:(NSString *)message {
/*
    [self showErrorMessage:message];
    
    [IJTDispatch dispatch_main:^{
        [_serverCipherArray addObject:[self getErrorDictionaryMessage:message]];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:5] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
 */
}

- (void)IJTSSLScanTestSupportedServerCiphersResultVersion:(NSString *)version preferred:(BOOL)preferred bits:(int)bits cipherId:(NSString *)cipherId cipher:(NSString *)cipher cipher_details:(NSString *)cipher_details {
    [IJTDispatch dispatch_main:^{
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        [dict setObject:[NSString stringWithFormat:@"%@(%@)", cipher, cipherId] forKey:@"Name"];
        [dict setObject:cipher_details forKey:@"Description"];
        [dict setObject:[NSString stringWithFormat:@"%d bits", bits] forKey:@"Bits"];
        [dict setObject:[NSString stringWithFormat:@"%@%@", version, preferred ? @"(Preferred)" : @""] forKey:@"Version"];
        [dict setObject:@(preferred) forKey:@"Red"];
        
        
        [_serverCipherArray addObject:dict];
        
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_serverCipherArray.count - 1 inSection:5]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

//section 6
- (void)IJTSSLScanShowCertificateFailure:(NSString *)message {
    [self showErrorMessage:message];
    
    [IJTDispatch dispatch_main:^{
        [_heartbleedArray addObject:[self getErrorDictionaryMessage:message]];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

- (void)IJTSSLScanShowCertificate:(NSString *)certificate verion:(long)version serialNumber:(NSString *)serialNumber signatureAlgorithm:(NSString *)signatureAlgorithm issuer:(NSString *)issuer notValidBefore:(NSString *)notValidBefore notValidAfter:(NSString *)notValidAfter subject:(NSString *)subject publicKeyAlgorithm:(NSString *)publicKeyAlgorithm publicKeyLength:(int)publicKeyLength publicKeyType:(NSString *)publicKeyType publicKeyString:(NSString *)publicKeyString x509v3Extensions:(NSString *)x509v3Extensions verifyCertificate:(NSString *)verifyCertificate {
    [IJTDispatch dispatch_main:^{
        NSString *message = [NSString stringWithFormat:@"Certificate: \n%@\n"
                             "Version: %ld\n"
                             "Serial Number: %@\n"
                             "Signature Algorithm: %@\n"
                             "Issuer: %@\n"
                             "Not valid before: %@\n"
                             "Not valid after: %@\n"
                             "Subject: %@\n"
                             "Public Key Algorithm: %@\n"
                             "%d Public Key: %@\n"
                             "%@\n"
                             "X509v3 Extensions: %@",
                             certificate, version, serialNumber,
                             signatureAlgorithm, issuer, notValidBefore,
                             notValidAfter, subject, publicKeyAlgorithm,
                             publicKeyLength, [publicKeyType isEqualToString:@"RSA"] ?
                             [NSString stringWithFormat:@"(%d bits)", publicKeyLength] : @"",
                             publicKeyString, x509v3Extensions];
        
        NSDictionary *dict = @{@"Message": message};
        
        [_showCertificateArray addObject:dict];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

//section 7
- (void)IJTSSLScanShowTrustedCAs:(NSArray *)CAs {
    [IJTDispatch dispatch_main:^{
        for(NSArray *s in CAs) {
            NSDictionary *dict = @{@"Message": s};
            
            [_showTrustedCAsArray addObject:dict];
        }
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:7] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

- (void)IJTSSLScanShowTrustedCAsFailure:(NSString *)message {
    [self showErrorMessage:message];
    
    [IJTDispatch dispatch_main:^{
        [_showTrustedCAsArray addObject:[self getErrorDictionaryMessage:message]];
        
        [self.tableView beginUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:7] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }];
}

- (NSDictionary *)getErrorDictionaryMessage: (NSString *)message {
    struct timeval time;
    gettimeofday(&time, NULL);
    return @{@"Error": @(YES),
             @"Message": message,
             @"Time": [IJTFormatString formatTimestamp:time secondsPadding:3 decimalPoint:3]};
}

- (void)stopScan {
    if(self.scanThread != nil) {
        [self.stopButton setEnabled:NO];
        [self.sslScan stop];
        self.cancle = YES;
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            if(![self.scanThread isFinished]) {
                while(self.scanThread) {
                    usleep(100);
                }
            }
            [self.stopButton setEnabled:YES];
        }];
    }
}

- (void)startScan {
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.stopButton, nil];
    self.clientCipherArray = [[NSMutableArray alloc] init];
    self.renegotiationArray = [[NSMutableArray alloc] init];
    self.compressionArray = [[NSMutableArray alloc] init];
    self.heartbleedArray = [[NSMutableArray alloc] init];
    self.serverCipherArray = [[NSMutableArray alloc] init];
    self.showCertificateArray = [[NSMutableArray alloc] init];
    self.showTrustedCAsArray = [[NSMutableArray alloc] init];
    self.cancle = NO;
    self.scanning = YES;
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:3] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:5] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:6] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:7] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    [self.dismissButton setEnabled:NO];
    
    self.scanThread = [[NSThread alloc] initWithTarget:self selector:@selector(startScanThread) object:nil];
    [self.scanThread start];
}

- (void)startScanThread {
    _sslScan = [[IJTSSLScan alloc] init];
    int ret =
    [_sslScan setTarget:_target port:_port family:_family timeout:_timeout];
    if(ret == 0) {
        [_sslScan setGetSupportedClient:_clientCipher
                      testRenegotiation:_renegotiation
                        testCompression:_compression
                         testHeartbleed:_heartbleed
                    testServerSupported:_serverCipher
                        showCertificate:_showCertificate
                         showTrustedCAs:_showTrustedCAs];
        [_sslScan setDelegate:self];
        [_sslScan scan];
    }
    else {
        [self showErrorMessage:@"Host seems refused connect."];
    }
    
    self.scanning = NO;
    self.scanThread = nil;
    
    _clientCipherArray = [self removeDup:_clientCipherArray];
    _serverCipherArray = [self removeDup:_serverCipherArray];
    
    [IJTDispatch dispatch_main:^{
        [self.dismissButton setEnabled:YES];
        [self.stopButton setEnabled:YES];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_scanButton, nil];
        
        [self.tableView reloadData];
    }];
}

- (NSMutableArray *)removeDup: (NSMutableArray *)array {
    NSSet *set = [[NSSet alloc] initWithArray:array];
    return [[NSMutableArray alloc] initWithArray:[set allObjects]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 8;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    
    if(_clientCipherArray.count != 0 || _renegotiationArray.count != 0 || _compressionArray.count != 0 || _heartbleedArray.count != 0 || _serverCipherArray.count != 0 || _showCertificateArray.count != 0 || _showTrustedCAsArray.count != 0) {
        [self.messageLabel removeFromSuperview];
    }
    else {
        [self.tableView addSubview:self.messageLabel];
    }
    
    if(section == 0)
        return 1;
    else if(section == 1)
        return _clientCipherArray.count;
    else if(section == 2)
        return _renegotiationArray.count;
    else if(section == 3)
        return _compressionArray.count;
    else if(section == 4)
        return _heartbleedArray.count;
    else if(section == 5)
        return _serverCipherArray.count;
    else if(section == 6)
        return _showCertificateArray.count;
    else if(section == 7)
        return _showTrustedCAsArray.count;
    return 0;
}

#define ERROR_CELL NSNumber *error = [dict valueForKey:@"Error"]; \
if([error boolValue]) { \
    IJTSSLScanErrorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ErrorCell" forIndexPath:indexPath]; \
    [IJTFormatUILabel dict:dict \
                       key:@"Time" \
                     label:cell.timeLabel \
                     color:IJTValueColor \
                      font:[UIFont systemFontOfSize:11]]; \
    [IJTFormatUILabel dict:dict \
                       key:@"Message" \
                     label:cell.messageLabel \
                     color:IJTErrorMessageColor \
                      font:[UIFont systemFontOfSize:11]]; \
    [cell layoutIfNeeded]; \
    return cell; \
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTSSLScanTaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel text:[NSString stringWithFormat:@"%@:%d", _target, _port]
                         label:cell.hostnameLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel text:_clientCipher ? @"YES" : @"NO"
                         label:cell.clientCipherLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [IJTFormatUILabel text:_renegotiation ? @"YES" : @"NO"
                         label:cell.renegotiationLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];

        [IJTFormatUILabel text:_compression ? @"YES" : @"NO"
                         label:cell.compressionLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];

        [IJTFormatUILabel text:_heartbleed ? @"YES" : @"NO"
                         label:cell.heartbleedLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];

        [IJTFormatUILabel text:_serverCipher ? @"YES" : @"NO"
                         label:cell.serverCipherLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];

        [IJTFormatUILabel text:_showCertificate ? @"YES" : @"NO"
                         label:cell.showCertificateLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];

        [IJTFormatUILabel text:_showTrustedCAs ? @"YES" : @"NO"
                         label:cell.trustedCAsLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];

        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == 1 || indexPath.section == 5) {
        NSDictionary *dict = nil;
        
        if(indexPath.section == 1)
            dict = _clientCipherArray[indexPath.row];
        else if(indexPath.section == 5)
            dict = _serverCipherArray[indexPath.row];
        else
            return nil;//crash
        
        ERROR_CELL
        else {
            IJTSSLScanCiphersTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CiphersCell" forIndexPath:indexPath];
            
            [IJTFormatUILabel dict:dict
                               key:@"Version"
                             label:cell.versionLabel
                             color:[[dict valueForKey:@"Red"] boolValue] ? IJTErrorMessageColor : IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"Bits"
                             label:cell.bitsLabel
                             color:[[dict valueForKey:@"Red"] boolValue] ? IJTErrorMessageColor : IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"Name"
                             label:cell.cipherLabel
                             color:[[dict valueForKey:@"Red"] boolValue] ? IJTErrorMessageColor : IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [IJTFormatUILabel dict:dict
                               key:@"Description"
                             label:cell.descriptionLabel
                             color:[[dict valueForKey:@"Red"] boolValue] ? IJTErrorMessageColor : IJTValueColor
                              font:[UIFont systemFontOfSize:11]];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }//end if section 1 or 5
    else if(indexPath.section == 2 || indexPath.section == 3 || indexPath.section == 4 || indexPath.section == 6 || indexPath.section == 7) {
        NSDictionary *dict = nil;
        
        if(indexPath.section == 2)
            dict = _renegotiationArray[indexPath.row];
        else if(indexPath.section == 3)
            dict = _compressionArray[indexPath.row];
        else if(indexPath.section == 4)
            dict = _heartbleedArray[indexPath.row];
        else if(indexPath.section == 6)
            dict = _showCertificateArray[indexPath.row];
        else if(indexPath.section == 7)
            dict = _showTrustedCAsArray[indexPath.row];
        else
            return nil; //crash
        
        ERROR_CELL
        else {
            IJTSSLScanEventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EventCell" forIndexPath:indexPath];
            
            [IJTFormatUILabel dict:dict
                               key:@"Message"
                             label:cell.eventLabel
                             color:[[dict valueForKey:@"Red"] boolValue] ? IJTErrorMessageColor : IJTValueColor
                              font:indexPath.section == 6 ? [UIFont systemFontOfSize:11] :[UIFont systemFontOfSize:17]];
            
            [cell layoutIfNeeded];
            return cell;
        }
    }//end if section 2, 3 or 4
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Task Information";
    
    if(self.scanning) {
        if(section == 1)
            return @"Client Ciphers";
        else if(section == 2)
            return @"Renegotiation";
        else if(section == 3)
            return @"Compression";
        else if(section == 4)
            return @"Heartbleed";
        else if(section == 5)
            return @"Server Ciphers";
        else if(section == 6)
            return @"Certficate";
        else if(section == 7)
            return @"Trusted CAs";
    }
    else {
        if(section == 1)
            return [NSString stringWithFormat:@"Client Ciphers(%lu)", (unsigned long)_clientCipherArray.count];
        else if(section == 2)
            return [NSString stringWithFormat:@"Renegotiation(%lu)", (unsigned long)_renegotiationArray.count];
        else if(section == 3)
            return [NSString stringWithFormat:@"Compression(%lu)", (unsigned long)_compressionArray.count];
        else if(section == 4)
            return [NSString stringWithFormat:@"Heartbleed(%lu)", (unsigned long)_heartbleedArray.count];
        else if(section == 5)
            return [NSString stringWithFormat:@"Server Ciphers(%lu)", (unsigned long)_serverCipherArray.count];
        else if(section == 6)
            return [NSString stringWithFormat:@"Certficate(%lu)", (unsigned long)_showCertificateArray.count];
        else if(section == 7)
            return [NSString stringWithFormat:@"Trusted CAs(%lu)", (unsigned long)_showTrustedCAsArray.count];
    }
    
    return @"";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
