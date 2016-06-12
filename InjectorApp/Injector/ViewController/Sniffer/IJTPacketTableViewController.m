//
//  IJTPacketTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTPacketTableViewController.h"
#import "IJTPacketOutlineTableViewCell.h"
#import "IJTPacketDetailTableViewController.h"

@interface IJTPacketTableViewController ()

@property (nonatomic, strong) UILabel *noSearchDataLabel;
@property (nonatomic) BOOL reloading;
@property (nonatomic, strong) NSMutableArray *displayPacket;
@property (nonatomic, strong) UIBarButtonItem *clearButton;

@property (nonatomic, strong) NSMutableArray *searchResultPacketArray;
@property (strong, nonatomic) UISearchController *searchController;

@end

@implementation IJTPacketTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 106;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    if(self.dismissButton == nil) {
        if(self.multiToolButton == nil) {
            self.dismissButton = [[UIBarButtonItem alloc]
                                  initWithImage:[UIImage imageNamed:@"close.png"]
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(dismissVC)];
        }
        else {
            self.dismissButton = self.multiToolButton;
        }
    }
    
    self.clearButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"trash.png"]
                        style:UIBarButtonItemStylePlain
                        target:self action:@selector(clearPacket)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.dismissButton, nil];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_clearButton, nil];
    
    [self.messageLabel setFrame:CGRectMake(self.view.center.x - SCREEN_WIDTH/2 + 8,
                                          SCREEN_HEIGHT/2 - CGRectGetHeight(self.tabBarController.tabBar.frame)/2 - 20 + 22,
                                           SCREEN_WIDTH - 16, 40)];
    self.messageLabel.text = @"No Packet Data";
    
    self.noSearchDataLabel =
    [[UILabel alloc] initWithFrame:
     CGRectMake(self.view.center.x - SCREEN_WIDTH/2 + 8,
                SCREEN_HEIGHT/2 - CGRectGetHeight(self.tabBarController.tabBar.frame)/2 - 20 + 22,
                SCREEN_WIDTH - 16, 40)];
    self.noSearchDataLabel.text = @"Search Number, Source, Destination, Length or Protocol";
    self.noSearchDataLabel.textAlignment = NSTextAlignmentCenter;
    self.noSearchDataLabel.textColor = IJTSupportColor;
    self.noSearchDataLabel.font = [UIFont boldSystemFontOfSize:30];
    self.noSearchDataLabel.numberOfLines = 0;
    self.noSearchDataLabel.adjustsFontSizeToFitWidth = YES;
    self.reloading = NO;
    
    [self analyserPacket];
    [self changeType:self.type];
    
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
    [[UIBarButtonItem appearanceWhenContainedIn: [UISearchBar class], nil] setTintColor:IJTSnifferColor];
#else
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTintColor:IJTSnifferColor];
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0,44) animated:YES];
    if(self.type == IJTPacketReaderTypeWiFi) {
        self.navigationItem.title = @"Packet(Wi-Fi)";
    }
    else {
        self.navigationItem.title = @"Packet(Cellular)";
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.searchController.active = NO;
}

- (void)loadPacketAndTableView {
    if(!self.reloading) {
        self.reloading = YES;
        [self analyserPacket];
        [self.tableView reloadData];
        self.reloading = NO;
    }
}

- (void)loadCell {
    if(self.tabBarController.selectedIndex != 0 && !self.reloading &&
       self.navigationController.visibleViewController == self &&
       !self.searchController.active) {
        [self loadPacketAndTableView];
    }
}

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark search bar
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    self.searchResultPacketArray = [[NSMutableArray alloc] init];
    NSString *text = searchController.searchBar.text.uppercaseString;
    for(NSDictionary *dict in self.displayPacket) {
        NSNumber *number = [dict valueForKey:@"Number"];
        NSString *source = [dict valueForKey:@"Source"];
        NSString *destination = [dict valueForKey:@"Destination"];
        NSNumber *length = [dict valueForKey:@"Length"];
        NSString *proto = [dict valueForKey:@"Protocol"];
        NSNumber *sourcePort = [dict valueForKey:@"SourcePort"];
        NSNumber *destinationPort = [dict valueForKey:@"DestinationPort"];
        
        proto = proto.uppercaseString;
        
        if([number unsignedIntegerValue] == [text longLongValue]) {
            [self.searchResultPacketArray addObject:dict];
        }
        if([source containsString:text]) {
            [self.searchResultPacketArray addObject:dict];
        }
        if([destination containsString:text]) {
            [self.searchResultPacketArray addObject:dict];
        }
        if([length unsignedIntegerValue] == [text longLongValue]) {
            [self.searchResultPacketArray addObject:dict];
        }
        if([proto containsString:text]) {
            [self.searchResultPacketArray addObject:dict];
        }
        if([text integerValue] != 0 && [sourcePort unsignedShortValue] == [text integerValue]) {
            [self.searchResultPacketArray addObject:dict];
        }
        if([text integerValue] != 0 && [destinationPort unsignedShortValue] == [text integerValue]) {
            [self.searchResultPacketArray addObject:dict];
        }
        
    }
    self.searchResultPacketArray =
    [NSMutableArray arrayWithArray:[[NSSet setWithArray:self.searchResultPacketArray] allObjects]];
    
    for(int i = 0 ; i < self.searchResultPacketArray.count ; i++) {
        for(int j = 0 ; j < i ; j++) {
            NSDictionary *dict1 = self.searchResultPacketArray[i];
            NSDictionary *dict2 = self.searchResultPacketArray[j];
            NSString *number1 = [dict1 valueForKey:@"Number"];
            NSString *number2 = [dict2 valueForKey:@"Number"];
            
            if([number1 longLongValue] > [number2 longLongValue]) {
                [self.searchResultPacketArray exchangeObjectAtIndex:i withObjectAtIndex:j];
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
    
    [self loadPacketAndTableView];
}

#pragma mark packet analysis
- (void)clearPacket {
    SCLAlertView *alert = [IJTShowMessage baseAlertView];
    
    [alert addButton:@"Yes" actionBlock:^{
        while(self.reloading) {
            [NSThread sleepForTimeInterval:0.01];
        }
        self.displayPacket = [[NSMutableArray alloc] init];
        self.packetQueueArray = [[NSMutableArray alloc] init];
        [self loadCell];
    }];
    
    [alert showWarning:@"Warning"
              subTitle:@"Are you sure clear all packet?"
      closeButtonTitle:@"No"
              duration:0];
}

- (void) analyserPacket {
    self.displayPacket = [[NSMutableArray alloc] init];
    NSArray *tempArray = [NSArray arrayWithArray:self.packetQueueArray];
    
    for(IJTPacketReader *reader in tempArray) {
        
        NSString *timestamp = [IJTFormatString formatTimestamp:reader.timestamp secondsPadding:3 decimalPoint:3];

        IJTPacketReaderProtocol protocol = reader.finalProtocolType;
        NSString *proto = [IJTPacketReader protocol2DetailString:protocol];
        NSString *source = reader.sourceIPAddress;
        NSString *destination = reader.destinationIPAddress;
        NSString *info = @"N/A";
        
        if(protocol != IJTPacketReaderProtocolTCP && protocol != IJTPacketReaderProtocolUDP) {
            proto = [proto stringByAppendingString:[NSString stringWithFormat:@"%@",
                                                    reader.ip_portocol == IPPROTO_TCP ? @"(TCP)" :
                                                    (reader.ip_portocol == IPPROTO_UDP ? @"(UDP)" : @"")]];
        }
        
        if(protocol == IJTPacketReaderProtocolARPRequest || protocol == IJTPacketReaderProtocolARPReply) {
            
            source = reader.sourceMacAddress;
            destination = reader.destinationMacAddress;
            
            if(protocol == IJTPacketReaderProtocolARPRequest) {
                info = [NSString stringWithFormat:@"Who has %@? Tell %@",
                        reader.destinationIPAddress, reader.sourceIPAddress];
            }
            else {
                info = [NSString stringWithFormat:@"%@ is at %@", reader.sourceIPAddress, reader.sourceMacAddress];
            }
        }
        else if(protocol == IJTPacketReaderProtocolICMPEcho || protocol == IJTPacketReaderProtocolICMPEchoReply) {
            if(protocol == IJTPacketReaderProtocolICMPEcho) {
                info = [NSString stringWithFormat:@"Echo request %@ => %@",
                        reader.sourceIPAddress, reader.destinationIPAddress];
            }
            else {
                info = [NSString stringWithFormat:@"Echo reply id = %#06x, seq = %d/%d, ttl = %d",
                        reader.icmp_ID,
                        ntohs(reader.icmp_Seq), reader.icmp_Seq,
                        reader.ip_ttl];
            }
        }
        else if(protocol == IJTPacketReaderProtocolTCP ||
                protocol == IJTPacketReaderProtocolUDP) {
            
            info = [NSString stringWithFormat:@"Source port : %d, Destination port : %d",
                    reader.sourcePort, reader.destinationPort];
        }
        else if(protocol == IJTPacketReaderProtocolOtherTransport ||
                protocol == IJTPacketReaderProtocolIPv4 ||
                protocol == IJTPacketReaderProtocolIPv6) {
            
            info = [NSString stringWithFormat:@"Protocol : %d", reader.ip_portocol];
        }
        else if(protocol == IJTPacketReaderProtocolOtherNetwork) {
            if(self.type == IJTPacketReaderTypeWiFi) {
                struct libnet_ethernet_hdr *ethernet = reader.ethernetHeader;
                info = [NSString stringWithFormat:@"Network : %#06x", ethernet->ether_type];
            }
            else if(self.type == IJTPacketReaderTypeCellular) {
                struct bsd_null_hdr *bsd = reader.bsdNullHeader;
                info = [NSString stringWithFormat:@"Network : %#010x", bsd->null_type];
            }
        }
        else if(protocol == IJTPacketReaderProtocolOtherApplication) {
            info = [NSString stringWithFormat:@"Source port : %d, Destination port : %d%@",
                    reader.sourcePort, reader.destinationPort,
                    reader.ip_portocol == IPPROTO_TCP ? @"(TCP)" :
                    (reader.ip_portocol == IPPROTO_UDP ? @"(UDP)" : @"")];
        }
        else if(protocol == IJTPacketReaderProtocolWOL) {
            source = [NSString stringWithFormat:@"%@(%@)", reader.sourceMacAddress, reader.sourceIPAddress];
            destination = [NSString stringWithFormat:@"%@(%@)", reader.destinationMacAddress, reader.destinationIPAddress];
            info = [NSString stringWithFormat:@"Sender : %@(%@)", reader.sourceMacAddress, reader.sourceIPAddress];
        }
        else if(protocol == IJTPacketReaderProtocolSNAP || protocol == IJTPacketReaderProtocolEAPOL) {
            source = reader.sourceMacAddress;
            destination = reader.destinationMacAddress;
        }
        else if(protocol == IJTPacketReaderProtocolIGMP) {
            struct libnet_igmp_hdr *igmp = reader.igmpHeader;
            info = [NSString stringWithFormat:@"Multicast Address : %@", [IJTFormatString formatIpAddress:&igmp->igmp_group family:AF_INET]];
        }
        else if(protocol == IJTPacketReaderProtocolICMPRedirect) {
            struct libnet_icmpv4_hdr *icmpv4 = reader.icmpv4Header;
            info = [NSString stringWithFormat:@"Gateway Address : %@", [IJTFormatString formatIpAddress:&icmpv4->hun.gateway family:AF_INET]];
        }
        else if(protocol == IJTPacketReaderProtocolICMPUnreach || protocol == IJTPacketReaderProtocolICMPTimexceed) {
            info = [NSString stringWithFormat:@"Source : %@", reader.sourceIPAddress];
        }
        else if(reader.ipv4Header == NULL && reader.ipv6Header == NULL) {
            source = reader.sourceMacAddress;
            destination = reader.destinationMacAddress;
        }
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        [dict setValue:@(reader.index) forKey:@"Number"];
        [dict setValue:timestamp forKey:@"Timestamp"];
        [dict setValue:source forKey:@"Source"];
        [dict setValue:destination forKey:@"Destination"];
        [dict setValue:proto forKey:@"Protocol"];
        [dict setValue:info forKey:@"Info"];
        [dict setValue:@(reader.captureLengh) forKey:@"Length"];
        [dict setValue:@(reader.sourcePort) forKey:@"SourcePort"];
        [dict setValue:@(reader.destinationPort) forKey:@"DestinationPort"];
        [dict setObject:reader forKey:@"Reader"];
        
        [self.displayPacket addObject:dict];
    }
    
    self.displayPacket = [NSMutableArray arrayWithArray:[[self.displayPacket reverseObjectEnumerator] allObjects]];
}

- (void)startRecordType: (IJTPacketReaderType)type {
    if(self.dismissButton == nil) {
        if(self.multiToolButton == nil) {
            self.dismissButton = [[UIBarButtonItem alloc]
                                  initWithImage:[UIImage imageNamed:@"close.png"]
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(dismissVC)];
        }
        else {
            self.dismissButton = self.multiToolButton;
        }
    }
    if(self.dismissButton.tag != MULTIBUTTONTAG)
        [self.dismissButton setEnabled:NO];
    self.type = type;
    self.reloading = YES;
    [self analyserPacket];
    [self.tableView reloadData];
    self.reloading = NO;
}

- (void) stopRecord {
    if(self.dismissButton == nil) {
        self.dismissButton = [[UIBarButtonItem alloc]
                              initWithImage:[UIImage imageNamed:@"close.png"]
                              style:UIBarButtonItemStylePlain
                              target:self action:@selector(dismissVC)];
    }
    [self.dismissButton setEnabled:YES];
    while(self.reloading);
    [self analyserPacket];
    [self.tableView reloadData];
}

- (void)changeType: (IJTPacketReaderType)type {
    self.type = type;
    if(type == IJTPacketReaderTypeWiFi) {
        self.navigationItem.title = @"Packet(Wi-Fi)";
    }
    else {
        self.navigationItem.title = @"Packet(Cellular)";
    }
}

#pragma mark table view delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IJTPacketOutlineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PacketCell" forIndexPath:indexPath];
    
    NSDictionary *dict = nil;
    if(self.searchController.active) {
        dict = self.searchResultPacketArray[indexPath.row];
    }
    else {
        dict = self.displayPacket[indexPath.row];
    }
    
    [IJTFormatUILabel dict:dict
                       key:@"Number"
                     label:cell.numberLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Timestamp"
                     label:cell.timeLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Source"
                     label:cell.sourceLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Destination"
                     label:cell.destinationLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Protocol"
                     label:cell.protocolLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Length"
                     label:cell.lengthLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    [IJTFormatUILabel dict:dict
                       key:@"Info"
                     label:cell.infoLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    
    
    NSString *proto = [dict valueForKey:@"Protocol"];
    
    UIColor *color = nil;
    
    if([proto hasPrefix:@"Other"])
        color = [IJTColor lighter:IJTOtherColor times:6];
    else if([proto hasPrefix:@"ARP"])
        color = [IJTColor lighter:IJTArpColor times:6];
    else if([proto hasPrefix:@"IP"])
        color = [IJTColor lighter:IJTIpColor times:2];
    else if([proto hasPrefix:@"ICMP"] || [proto isEqualToString:@"IGMP"])
        color = IJTIcmpIgmpColor;
    else if([proto isEqualToString:@"TCP"] || [proto isEqualToString:@"UDP"])
        color = IJTTcpUdpColor;
    else if([proto isEqualToString:@"SNAP"] || [proto isEqualToString:@"EAPOL"])
        color = [IJTColor lighter:IJTOtherColor times:4];
    else
        color = IJTOtherelseColor;
    
    cell.backgroundColor = color;
    
    
    [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:11];
    }];
    
    [cell layoutIfNeeded];
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(self.searchController.active) {
        [self.messageLabel removeFromSuperview];
        if(self.searchResultPacketArray.count == 0) {
            [self.tableView addSubview:self.noSearchDataLabel];
        }
        else {
            [self.noSearchDataLabel removeFromSuperview];
        }
        return self.searchResultPacketArray.count;
    }
    else {
        [self.noSearchDataLabel removeFromSuperview];
        if(self.displayPacket.count == 0) {
            [self.tableView addSubview:self.messageLabel];
            [self.clearButton setEnabled:NO];
            [self.tableView setContentOffset:CGPointMake(0,44) animated:NO];
        }
        else {
            [self.messageLabel removeFromSuperview];
            [self.clearButton setEnabled:YES];
            [self.tableView setContentOffset:CGPointMake(0,0) animated:NO];
        }
        return self.displayPacket.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(self.searchController.active) {
        return [NSString stringWithFormat:@"Filtered Packet(%lu)", (unsigned long)self.searchResultPacketArray.count];
    } {
        return [NSString stringWithFormat:@"Captured Packet(%lu)", (unsigned long)self.displayPacket.count];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"PacketDetail"]) {
        IJTPacketDetailTableViewController *vc = [segue destinationViewController];
        
        NSIndexPath *index = [self.tableView indexPathForSelectedRow];
        if(self.searchController.active) {
            vc.packetDictionary = [NSMutableDictionary dictionaryWithDictionary:self.searchResultPacketArray[index.row]];
        }
        else {
            vc.packetDictionary = [NSMutableDictionary dictionaryWithDictionary:self.displayPacket[index.row]];
        }
        vc.multiToolButton = self.multiToolButton;
    }
}
@end
