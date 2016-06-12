//
//  IJTPacketDetailTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/21.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTPacketDetailTableViewController.h"
#import "IJTPacketDetailTableViewCell.h"
#import "IJTPacketFieldTableViewCell.h"

@interface IJTPacketDetailTableViewController ()

@property (nonatomic, strong) IJTPacketReader *reader;
@property (nonatomic) NSUInteger section;
@property (nonatomic, strong) UITextView *hexDumpTextView;
@property (nonatomic, strong) UITextView *asciiDumpTextView;
@property (nonatomic, strong) NSAttributedString *hexDumpAttributedString;
@property (nonatomic, strong) NSAttributedString *asciiDumpAttributedString;
@property (nonatomic) NSIndexPath *selectIndexPath;

@end

@implementation IJTPacketDetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 105;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
                                   initWithImage:[UIImage imageNamed:@"left.png"]
                                   style:UIBarButtonItemStylePlain
                                   target:self action:@selector(back:)];
    
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:backButton, self.multiToolButton, nil];
    
    self.reader = [_packetDictionary valueForKey:@"Reader"];
    
    self.navigationItem.title = [_packetDictionary valueForKey:@"Protocol"];
    
    //hex dump text view
    self.hexDumpTextView = [[UITextView alloc] init];
    self.hexDumpTextView.text = [self.reader getHexFormat];
    self.hexDumpTextView.textColor = IJTValueColor;
    self.hexDumpTextView.font = [UIFont fontWithName:@"Menlo-Regular" size:20];
    //self.hexDumpTextView.selectable = NO;
    self.hexDumpTextView.editable = NO;
    self.hexDumpTextView.scrollEnabled = NO;
    CGFloat height = [IJTFormatUITextView textViewHeightForAttributedText:self.hexDumpTextView.attributedText
                                                                 andWidth:SCREEN_WIDTH - 16];
    [self.hexDumpTextView sizeToFit];
    CGFloat xpotion = (SCREEN_WIDTH - CGRectGetWidth(self.hexDumpTextView.frame))/2;
    self.hexDumpTextView.frame = CGRectMake(xpotion, 0, CGRectGetWidth(self.hexDumpTextView.frame), height);
    self.hexDumpAttributedString =
    [[NSAttributedString alloc] initWithAttributedString:self.hexDumpTextView.attributedText];
    
    //ascii dump texr view
    self.asciiDumpTextView = [[UITextView alloc] init];
    self.asciiDumpTextView.text = [self.reader getASCIIFormat];
    self.asciiDumpTextView.textColor = IJTValueColor;
    self.asciiDumpTextView.font = [UIFont fontWithName:@"Menlo-Regular" size:14];
    //self.asciiDumpTextView.selectable = NO;
    self.asciiDumpTextView.editable = NO;
    self.asciiDumpTextView.scrollEnabled = NO;
    height = [IJTFormatUITextView textViewHeightForAttributedText:self.asciiDumpTextView.attributedText
                                                         andWidth:SCREEN_WIDTH - 16];
    [self.asciiDumpTextView sizeToFit];
    xpotion = (SCREEN_WIDTH - CGRectGetWidth(self.asciiDumpTextView.frame))/2;
    self.asciiDumpTextView.frame = CGRectMake(xpotion, 0, CGRectGetWidth(self.asciiDumpTextView.frame), height);
    self.asciiDumpAttributedString =
    [[NSAttributedString alloc] initWithAttributedString:self.asciiDumpTextView.attributedText];
    
    //section count
    self.section = 3;
    NSString *protocolInFrame = @"";
    if(self.reader.layer1Type != IJTPacketReaderProtocolUnknown) {
        self.section++;
        protocolInFrame = [IJTPacketReader protocol2String:self.reader.layer1Type];
    }
    if(self.reader.layer2Type != IJTPacketReaderProtocolUnknown) {
        self.section++;
        if(protocolInFrame.length <= 0) {
            protocolInFrame = [IJTPacketReader protocol2String:self.reader.layer2Type];
        }
        else {
            protocolInFrame = [protocolInFrame stringByAppendingString:
                               [NSString stringWithFormat:@"=>%@", [IJTPacketReader protocol2String:self.reader.layer2Type]]];
        }
    }
    if(self.reader.layer3Type != IJTPacketReaderProtocolUnknown && self.reader.layer2Type != IJTPacketReaderProtocolIPv6) {
        self.section++;
        if(protocolInFrame.length <= 0) {
            protocolInFrame = [IJTPacketReader protocol2String:self.reader.layer3Type];
        }
        else {
            protocolInFrame = [protocolInFrame stringByAppendingString:
                               [NSString stringWithFormat:@"=>%@", [IJTPacketReader protocol2String:self.reader.layer3Type]]];
        }
    }
    if(self.reader.layer4Type != IJTPacketReaderProtocolUnknown) {
        NSUInteger dataLength = self.reader.captureLengh - self.reader.layer4StartPosition;
        if(dataLength > 0)
            self.section++;
        if(protocolInFrame.length <= 0) {
            protocolInFrame = [IJTPacketReader protocol2String:self.reader.layer4Type];
        }
        else {
            protocolInFrame = [protocolInFrame stringByAppendingString:
                               [NSString stringWithFormat:@"=>%@", [IJTPacketReader protocol2String:self.reader.layer4Type]]];
        }
    }
    if(self.reader.icmpLayer1Type != IJTPacketReaderProtocolUnknown) {
        self.section++;
        if(protocolInFrame.length <= 0) {
            protocolInFrame = [IJTPacketReader protocol2String:self.reader.icmpLayer1Type];
        }
        else {
            protocolInFrame = [protocolInFrame stringByAppendingString:
                               [NSString stringWithFormat:@"=>%@", [IJTPacketReader protocol2String:self.reader.icmpLayer1Type]]];
        }
    }
    if(self.reader.icmpLayer2Type != IJTPacketReaderProtocolUnknown) {
        self.section++;
        if(protocolInFrame.length <= 0) {
            protocolInFrame = [IJTPacketReader protocol2String:self.reader.icmpLayer2Type];
        }
        else {
            protocolInFrame = [protocolInFrame stringByAppendingString:
                               [NSString stringWithFormat:@"=>%@", [IJTPacketReader protocol2String:self.reader.icmpLayer2Type]]];
        }
    }
    [_packetDictionary setValue:protocolInFrame forKey:@"ProtocolInFrame"];
    
    self.selectIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)back: (id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return self.section;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if(section == 0)
        return 1;
    else if(section == self.section - 1 || section == self.section - 2)
        return 1;
    else if(section == 1) {
        return [self numberOfRowProtocol:self.reader.layer1Type];
    }
    else if(section == 2) {
        return [self numberOfRowProtocol:self.reader.layer2Type];
    }
    else if(section == 3) {
        return [self numberOfRowProtocol:self.reader.layer3Type];
    }
    else if(section == 4) {
        if(self.reader.layer4Type != IJTPacketReaderProtocolUnknown)
            return [self numberOfRowProtocol:self.reader.layer4Type];
        else
            return [self numberOfRowProtocol:self.reader.icmpLayer1Type];
    }
    else if(section == 5) {
        return [self numberOfRowProtocol:self.reader.icmpLayer2Type];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0 && indexPath.row == 0) {
        IJTPacketDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PacketDetailCell" forIndexPath:indexPath];
        
        [IJTFormatUILabel dict:_packetDictionary
                           key:@"Number"
                         label:cell.numberLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        if(self.reader.dataLinkData == IJTPacketReaderTypeWiFi) {
            cell.interfaceLabel.text = [NSString stringWithFormat:@"en0 <%d>", if_nametoindex("en0")];
            cell.typeLabel.text = [NSString stringWithUTF8String:pcap_datalink_val_to_description(DLT_EN10MB)];
        }
        else {
            cell.interfaceLabel.text = [NSString stringWithFormat:@"pdp_ip0 <%d>", if_nametoindex("pdp_ip0")];
            cell.typeLabel.text = [NSString stringWithUTF8String:pcap_datalink_val_to_description(DLT_NULL)];
        }
        
        cell.arrivalLabel.text = [IJTFormatString formatTimestampWithWholeInfo:self.reader.timestamp decimalPoint:6];
        
        cell.captureLengthLabel.text =
        [NSString stringWithFormat:@"%d %@", self.reader.captureLengh, self.reader.captureLengh == 0 ? @"byte": @"bytes"];
        
        cell.frameLengthLabel.text =
        [NSString stringWithFormat:@"%d %@", self.reader.frameLengh, self.reader.frameLengh == 0 ? @"byte": @"bytes"];
        
        [IJTFormatUILabel dict:_packetDictionary
                           key:@"ProtocolInFrame"
                         label:cell.protocolLabel
                         color:IJTValueColor
                          font:[UIFont systemFontOfSize:11]];
        
        [cell.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
        }];
        
        [cell.dataLabels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
            label.font = [UIFont systemFontOfSize:11];
            label.textColor = IJTValueColor;
        }];
    
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == self.section - 1 && indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EmptyCell" forIndexPath:indexPath];
        
        [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [cell.contentView addSubview:self.hexDumpTextView];
        
        [cell layoutIfNeeded];
        return cell;
    }
    else if(indexPath.section == self.section - 2 && indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EmptyCell" forIndexPath:indexPath];
        
        [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [cell.contentView addSubview:self.asciiDumpTextView];
        
        [cell layoutIfNeeded];
        return cell;
    }
    
    else if(indexPath.section == 1) {
        return [self tableView:tableView cellForRowAtIndexPath:indexPath protocol:self.reader.layer1Type];
    }
    else if(indexPath.section == 2) {
        return [self tableView:tableView cellForRowAtIndexPath:indexPath protocol:self.reader.layer2Type];
    }
    else if(indexPath.section == 3) {
        return [self tableView:tableView cellForRowAtIndexPath:indexPath protocol:self.reader.layer3Type];
    }
    else if(indexPath.section == 4) {
        if(self.reader.layer4Type != IJTPacketReaderProtocolUnknown)
            return [self tableView:tableView cellForRowAtIndexPath:indexPath protocol:self.reader.layer4Type];
        else
            return [self tableView:tableView cellForRowAtIndexPath:indexPath protocol:self.reader.icmpLayer1Type];
    }
    else if(indexPath.section == 5) {
        return [self tableView:tableView cellForRowAtIndexPath:indexPath protocol:self.reader.icmpLayer2Type];
    }
    
    return nil;
}

- (NSInteger)numberOfRowProtocol: (IJTPacketReaderProtocol)protocol {
    switch (protocol) {
        case IJTPacketReaderProtocolNULL:
        case IJTPacketReaderProtocolICMPFragment:
        case IJTPacketReaderProtocolTCPFragment:
        case IJTPacketReaderProtocolUDPFragment:
        case IJTPacketReaderProtocolARPOther:
        case IJTPacketReaderProtocolOtherNetwork:
        case IJTPacketReaderProtocolSNAP:
        case IJTPacketReaderProtocolEAPOL:
        case IJTPacketReaderProtocolICMPOther:
            return 1;
        case IJTPacketReaderProtocolEthernet:
            return 3;
        case IJTPacketReaderProtocolUDP:
            return 4;
        case IJTPacketReaderProtocolUDPOverICMP: {
            if(self.reader.captureLengh - self.reader.icmpLayer2StartPosition - LIBNET_UDP_H == 0)
                return 4;
            else
                return 5;
        }
        case IJTPacketReaderProtocolICMPEcho:
        case IJTPacketReaderProtocolICMPEchoReply:
            return 6;
        case IJTPacketReaderProtocolARPRequest:
        case IJTPacketReaderProtocolARPReply:
            return 9;
        case IJTPacketReaderProtocolTCP:
            if(self.reader.layer3Type == IJTPacketReaderProtocolICMPRedirect)
                return 3;
            else
                return 11;
        case IJTPacketReaderProtocolTCPOverICMP:
            return 12;
        case IJTPacketReaderProtocolIPv4:
        case IJTPacketReaderProtocolIPv4OverIcmp:
            return 13;
        case IJTPacketReaderProtocolICMPUnreach:
        case IJTPacketReaderProtocolICMPTimexceed:
            return 3;
        case IJTPacketReaderProtocolDHCP:
        case IJTPacketReaderProtocolDNS:
        case IJTPacketReaderProtocolHTTP:
        case IJTPacketReaderProtocolHTTPS:
        case IJTPacketReaderProtocolIMAP:
        case IJTPacketReaderProtocolIMAPS:
        case IJTPacketReaderProtocolMDNS:
        case IJTPacketReaderProtocolNTPv4:
        case IJTPacketReaderProtocolOtherApplication:
        case IJTPacketReaderProtocolSMTP:
        case IJTPacketReaderProtocolSSDP:
        case IJTPacketReaderProtocolSSH:
        case IJTPacketReaderProtocolWhois:
            return self.reader.captureLengh - self.reader.layer4StartPosition <= 0 ? 0 : 1;
        case IJTPacketReaderProtocolWOL: {
            if(self.reader.layer3StartPosition > 0)
                return 2;
            else if(self.reader.captureLengh == 122)
                return 3;
            else if(self.reader.captureLengh <= LIBNET_ETH_H + 6)
                return 1;
            else
                return 2;
        }
        case IJTPacketReaderProtocolIPv6: {
            if(self.reader.layer2Type == IJTPacketReaderProtocolIPv6)
                return 8;
            else
                return 0;
        }
        case IJTPacketReaderProtocolICMPv6:
            return 4;
        case IJTPacketReaderProtocolIGMP:
            return 4;
        case IJTPacketReaderProtocolOtherTransport:
            return 1;
        case IJTPacketReaderProtocolICMPRedirect:
            return 4;
        default: return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
                      protocol:(IJTPacketReaderProtocol)protocol {
    
    NSString *fieldName = @"";
    NSString *fieldValue = @"";
    NSUInteger dataLength = 0;
    
    switch (protocol) {
        case IJTPacketReaderProtocolEthernet: {
            if(indexPath.row == 0) {
                fieldName = @"Destination";
                fieldValue = [NSString stringWithFormat:@"%@\n(%@)", _reader.destinationMacAddress, [IJTDatabase oui:_reader.destinationMacAddress]];
                dataLength = 6;
                
            }
            else if(indexPath.row == 1) {
                fieldName = @"Source";
                fieldValue = [NSString stringWithFormat:@"%@\n(%@)", _reader.sourceMacAddress, [IJTDatabase oui:_reader.sourceMacAddress]];
                dataLength = 6;
            }
            else if(indexPath.row == 2) {
                struct libnet_ethernet_hdr *ethernet = self.reader.ethernetHeader;
                if(ethernet->ether_type == ntohs(290) && //snap length
                   (self.reader.layer1Type == IJTPacketReaderProtocolSNAP ||
                    self.reader.layer2Type == IJTPacketReaderProtocolSNAP ||
                    self.reader.layer3Type == IJTPacketReaderProtocolSNAP ||
                    self.reader.layer4Type == IJTPacketReaderProtocolSNAP)) {
                       fieldName = @"Length";
                       fieldValue = [NSString stringWithFormat:@"SNAP(%d bytes)",
                                     ntohs(ethernet->ether_type)];
                }
                else {
                    fieldName = @"Type";
                    fieldValue = [IJTFormatString formatEthernetType2String:ethernet->ether_type];
                }
                dataLength = 2;
            }
        }//end if ethernet
            break;
        case IJTPacketReaderProtocolNULL: {
            if(indexPath.row == 0) {
                struct bsd_null_hdr *bsd = self.reader.bsdNullHeader;
                fieldName = @"Type";
                fieldValue = [IJTFormatString formatNullType2String:bsd->null_type];
                dataLength = 4;
            }
        }//end if null
            break;
        case IJTPacketReaderProtocolIPv4:
        case IJTPacketReaderProtocolIPv4OverIcmp: {
            struct libnet_ipv4_hdr *ipv4 = NULL;
            if(protocol == IJTPacketReaderProtocolIPv4)
                ipv4 = self.reader.ipv4Header;
            else
                ipv4 = self.reader.ipv4OverIcmpHeader;
            if(indexPath.row == 0) {
                fieldName = @"Version";
                fieldValue = [NSString stringWithFormat:@"%d", ipv4->ip_v];
                dataLength = 1;
            }
            else if(indexPath.row == 1) {
                fieldName = @"Header Length";
                fieldValue = [IJTFormatString formatBytes:ipv4->ip_hl << 2 carry:NO];
                dataLength = 1;
            }
            else if(indexPath.row == 2) {
                fieldName = @"Type of Service";
                fieldValue = [IJTFormatString formatIpTypeOfSerivce:ipv4->ip_tos];
                dataLength = 1;
            }
            else if(indexPath.row == 3) {
                fieldName = @"Total Length";
                fieldValue = [IJTFormatString formatBytes:ntohs(ipv4->ip_len) carry:NO];
                dataLength = 2;
            }
            else if(indexPath.row == 4) {
                fieldName = @"Identification";
                fieldValue = [NSString stringWithFormat:@"%#06x(%u)", ntohs(ipv4->ip_id), ntohs(ipv4->ip_id)];
                dataLength = 2;
            }
            else if(indexPath.row == 5) {
                fieldName = @"Flags";
                fieldValue = [IJTFormatString formatIpFlags:ipv4->ip_off];
                dataLength = 1;
            }
            else if(indexPath.row == 6) {
                fieldName = @"Offset";
                fieldValue = [NSString stringWithFormat:@"%d", (ntohs(ipv4->ip_off) & IP_OFFMASK) << 3];
                dataLength = 2;
            }
            else if(indexPath.row == 7) {
                fieldName = @"TTL";
                fieldValue = [NSString stringWithFormat:@"%d", ipv4->ip_ttl];
                dataLength = 1;
            }
            else if(indexPath.row == 8) {
                fieldName = @"Protocol";
                fieldValue = [IJTFormatString formatIpProtocol:ipv4->ip_p];
                dataLength = 1;
            }
            else if(indexPath.row == 9) {
                fieldName = @"Header checksum";
                fieldValue = [IJTFormatString formatChecksum:ipv4->ip_sum];
                dataLength = 2;
            }
            else if(indexPath.row == 10) {
                fieldName = @"Source";
                fieldValue = [IJTFormatString formatIpAddress:&ipv4->ip_src family:AF_INET];
                dataLength = 4;
            }
            else if(indexPath.row == 11) {
                fieldName = @"Destination";
                fieldValue = [IJTFormatString formatIpAddress:&ipv4->ip_dst family:AF_INET];
                dataLength = 4;
            }
            else if(indexPath.row == 12) {
                NSInteger length = 0;
                if(ipv4 == self.reader.ipv4OverIcmpHeader && self.reader.icmpLayer2StartPosition == 0) { //redirect
                    fieldName = @"Data";
                    length = self.reader.captureLengh - self.reader.icmpLayer1StartPosition - LIBNET_IPV4_H;
                }
                else {
                    fieldName = @"IP Option";
                    length = [self.reader getIpOptionLength];
                }
                if(length <= 0)
                    fieldValue = @"N/A";
                else {
                    fieldValue = [IJTFormatString formatBytes:length carry:NO];
                    dataLength = (u_int32_t)length;
                }
            }
            
        }//end if ipv4
            break;
        case IJTPacketReaderProtocolICMPEcho:
        case IJTPacketReaderProtocolICMPEchoReply: {
            struct libnet_icmpv4_hdr *icmpv4 = self.reader.icmpv4Header;
            
            if(indexPath.row == 0) {
                fieldName = @"Type";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", icmpv4->icmp_type,
                              [IJTFormatString formatIcmpType:icmpv4->icmp_type]];
                dataLength = 1;
            }
            else if(indexPath.row == 1) {
                fieldName = @"Code";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", icmpv4->icmp_code,
                              [IJTFormatString formatIcmpCode:icmpv4->icmp_code type:icmpv4->icmp_type]];
                dataLength = 1;
            }
            else if(indexPath.row == 2) {
                fieldName = @"Checksum";
                fieldValue = [IJTFormatString formatChecksum:icmpv4->icmp_sum];
                dataLength = 2;
            }
            else if(indexPath.row == 3) {
                fieldName = @"Identification";
                fieldValue = [NSString stringWithFormat:@"%#06x", ntohs(self.reader.icmp_ID)];
                dataLength = 2;
            }
            else if(indexPath.row == 4) {
                fieldName = @"Sequence Number";
                fieldValue = [NSString stringWithFormat:@"%d/%d", ntohs(self.reader.icmp_Seq), self.reader.icmp_Seq];
                dataLength = 2;
            }
            else if(indexPath.row == 5) {
                dataLength = self.reader.captureLengh - self.reader.layer3StartPosition - LIBNET_ICMPV4_ECHO_H;
                fieldName = @"Data";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }//end if icmp echo or echo reply
            break;
        case IJTPacketReaderProtocolICMPFragment:
        case IJTPacketReaderProtocolTCPFragment:
        case IJTPacketReaderProtocolUDPFragment: {
            if(indexPath.row == 0) {
                dataLength = self.reader.captureLengh - self.reader.layer3StartPosition;
                fieldName = @"Length";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }
            break;
        case IJTPacketReaderProtocolARPReply:
        case IJTPacketReaderProtocolARPRequest: {
            struct arp_header *arp = self.reader.arpHeader;
            if(indexPath.row == 0) {
                dataLength = 2;
                fieldName = @"Hardware Type";
                fieldValue = [NSString stringWithFormat:@"%d", ntohs(arp->ar_hrd)];
            }
            else if(indexPath.row == 1) {
                dataLength = 2;
                fieldName = @"Protocol Type";
                fieldValue = [IJTFormatString formatEthernetType2String:arp->ar_pro];
            }
            else if(indexPath.row == 2) {
                dataLength = 1;
                fieldName = @"Hardware Length";
                fieldValue = [NSString stringWithFormat:@"%d", arp->ar_hln];
            }
            else if(indexPath.row == 3) {
                dataLength = 1;
                fieldName = @"Protocol Length";
                fieldValue = [NSString stringWithFormat:@"%d", arp->ar_pln];
            }
            else if(indexPath.row == 4) {
                dataLength = 2;
                fieldName = @"Opcode";
                fieldValue = [IJTFormatString formatArpOpcode:arp->ar_op];
            }
            else if(indexPath.row == 5) {
                dataLength = arp->ar_hln;
                fieldName = @"Sender MAC Address";
                fieldValue = [self ether_ntoa:&arp->ar_sha];
            }
            else if(indexPath.row == 6) {
                dataLength = arp->ar_pln;
                fieldName = @"Sender IP Address";
                fieldValue = [IJTFormatString formatIpAddress:&arp->ar_spa family:AF_INET];
            }
            else if(indexPath.row == 7) {
                dataLength = arp->ar_hln;
                fieldName = @"Target MAC Address";
                fieldValue = [self ether_ntoa:&arp->ar_tha];
            }
            else if(indexPath.row == 8) {
                dataLength = arp->ar_pln;
                fieldName = @"Target IP Address";
                fieldValue = [IJTFormatString formatIpAddress:&arp->ar_tpa family:AF_INET];
            }
        }
            break;
        case IJTPacketReaderProtocolARPOther: {
            if(indexPath.row == 0) {
                dataLength = self.reader.captureLengh - self.reader.layer2StartPosition;
                fieldName = @"Length";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }
            break;
        case IJTPacketReaderProtocolOtherNetwork: {
            if(indexPath.row == 0) {
                dataLength = self.reader.captureLengh - self.reader.layer2StartPosition;
                fieldName = @"Length";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }
            break;
        case IJTPacketReaderProtocolOtherTransport: {
            if(indexPath.row == 0) {
                dataLength = self.reader.captureLengh - self.reader.layer3StartPosition;
                fieldName = @"Length";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }
            break;
        case IJTPacketReaderProtocolTCP:
        case IJTPacketReaderProtocolTCPOverICMP: {
            struct libnet_tcp_hdr *tcp = NULL;
            if(protocol == IJTPacketReaderProtocolTCP)
                tcp = self.reader.tcpHeader;
            else
                tcp = self.reader.tcpOverIcmpHeader;
            if(indexPath.row == 0) {
                dataLength = 2;
                fieldName = @"Source Port";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", ntohs(tcp->th_sport), [IJTFormatString portName:ntohs(tcp->th_sport) protocol:@"tcp"]];
            }
            else if(indexPath.row == 1) {
                dataLength = 2;
                fieldName = @"Destination Port";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", ntohs(tcp->th_dport), [IJTFormatString portName:ntohs(tcp->th_dport) protocol:@"tcp"]];
            }
            else if(indexPath.row == 2) {
                dataLength = 4;
                fieldName = @"Sequence Number";
                fieldValue = [NSString stringWithFormat:@"%u(%#010x)", ntohl(tcp->th_seq), ntohl(tcp->th_seq)];
            }
            else if(indexPath.row == 3) {
                dataLength = 4;
                fieldName = @"Ack Number";
                fieldValue = [NSString stringWithFormat:@"%u(%#010x)", ntohl(tcp->th_ack), ntohl(tcp->th_ack)];
            }
            else if(indexPath.row == 4) {
                dataLength = 1;
                fieldName = @"Header Length";
                fieldValue = [IJTFormatString formatBytes:tcp->th_off << 2 carry:NO];
            }
            else if(indexPath.row == 5) {
                dataLength = 1;
                fieldName = @"Reserved";
                fieldValue = [NSString stringWithFormat:@"%d", tcp->th_x2];
            }
            else if(indexPath.row == 6) {
                dataLength = 1;
                fieldName = @"Flags";
                fieldValue = [IJTFormatString formatTcpFlags:tcp->th_flags];
            }
            else if(indexPath.row == 7) {
                dataLength = 2;
                fieldName = @"Window Size";
                fieldValue = [NSString stringWithFormat:@"%u", ntohs(tcp->th_win)];
            }
            else if(indexPath.row == 8) {
                dataLength = 2;
                fieldName = @"Checksum";
                fieldValue = [IJTFormatString formatChecksum:tcp->th_sum];
            }
            else if(indexPath.row == 9) {
                dataLength = 2;
                fieldName = @"Urgent Pointer";
                fieldValue = [NSString stringWithFormat:@"%d", ntohs(tcp->th_urp)];
            }
            else if(indexPath.row == 10) {
                fieldName = @"TCP Option";
                NSInteger length = [self.reader getTcpOptionLength];
                if(length <= 0)
                    fieldValue = @"N/A";
                else {
                    fieldValue = [IJTFormatString formatBytes:length carry:NO];
                    dataLength = (u_int32_t)length;
                }
            }
            else if(indexPath.row == 11) {
                dataLength = self.reader.captureLengh - self.reader.icmpLayer2StartPosition - (tcp->th_off << 2);
                fieldName = @"Data";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }
            break;
        case IJTPacketReaderProtocolUDP:
        case IJTPacketReaderProtocolUDPOverICMP: {
            struct libnet_udp_hdr *udp = NULL;
            if(protocol == IJTPacketReaderProtocolUDP)
                udp = self.reader.udpHeader;
            else
                udp = self.reader.udpOverIcmpHeader;
            if(indexPath.row == 0) {
                fieldName = @"Source Port";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", ntohs(udp->uh_sport), [IJTFormatString portName:ntohs(udp->uh_sport) protocol:@"udp"]];
                dataLength = 2;
            }
            else if(indexPath.row == 1) {
                fieldName = @"Destination Port";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", ntohs(udp->uh_dport), [IJTFormatString portName:ntohs(udp->uh_dport) protocol:@"udp"]];
                dataLength = 2;
            }
            else if(indexPath.row == 2) {
                fieldName = @"Length";
                fieldValue = [IJTFormatString formatBytes:ntohs(udp->uh_ulen) carry:NO];
                dataLength = 2;
            }
            else if(indexPath.row == 3) {
                fieldName = @"Checksum";
                fieldValue = [IJTFormatString formatChecksum:udp->uh_sum];
                dataLength = 2;
            }
            else if(indexPath.row == 4) {
                dataLength = self.reader.captureLengh - self.reader.icmpLayer2StartPosition - LIBNET_UDP_H;
                fieldName = @"Data";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }
            break;
        case IJTPacketReaderProtocolICMPTimexceed:
        case IJTPacketReaderProtocolICMPUnreach: {
            struct libnet_icmpv4_hdr *icmpv4 = self.reader.icmpv4Header;
            if(indexPath.row == 0) {
                dataLength = 1;
                fieldName = @"Type";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", icmpv4->icmp_type, [IJTFormatString formatIcmpType:icmpv4->icmp_type]];
            }
            else if(indexPath.row == 1) {
                dataLength = 1;
                fieldName = @"Code";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", icmpv4->icmp_code, [IJTFormatString formatIcmpCode:icmpv4->icmp_code type:icmpv4->icmp_type]];
            }
            else if(indexPath.row == 2) {
                dataLength = 2;
                fieldName = @"Checksum";
                fieldValue = [IJTFormatString formatChecksum:icmpv4->icmp_sum];
            }
        }
            break;
        case IJTPacketReaderProtocolDHCP:
        case IJTPacketReaderProtocolDNS:
        case IJTPacketReaderProtocolHTTP:
        case IJTPacketReaderProtocolHTTPS:
        case IJTPacketReaderProtocolIMAP:
        case IJTPacketReaderProtocolIMAPS:
        case IJTPacketReaderProtocolMDNS:
        case IJTPacketReaderProtocolNTPv4:
        case IJTPacketReaderProtocolOtherApplication:
        case IJTPacketReaderProtocolSMTP:
        case IJTPacketReaderProtocolSSDP:
        case IJTPacketReaderProtocolSSH:
        case IJTPacketReaderProtocolWhois: {
            if(indexPath.row == 0) {
                dataLength = self.reader.captureLengh - self.reader.layer4StartPosition;
                fieldName = @"Length";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }
            break;
        case IJTPacketReaderProtocolSNAP:
        case IJTPacketReaderProtocolEAPOL: {
            if(indexPath.row == 0) {
                dataLength = self.reader.captureLengh - self.reader.layer2StartPosition;
                fieldName = @"Length";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }
            break;
        case IJTPacketReaderProtocolICMPOther: {
            if(indexPath.row == 0) {
                dataLength = self.reader.captureLengh - self.reader.layer3StartPosition;
                fieldName = @"Length";
                fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
            }
        }
            break;
        case IJTPacketReaderProtocolWOL: {
            struct wol_header *wol = self.reader.wolHeader;
            if(indexPath.row == 0) {
                if(self.reader.captureLengh <= LIBNET_ETH_H + 6) {
                    dataLength = self.reader.captureLengh - LIBNET_ETH_H;
                    fieldName = @"Length";
                    fieldValue = [IJTFormatString formatBytes:dataLength carry:NO];
                }
                else {
                    dataLength = 6;
                    fieldName = @"Sync Stream";
                    fieldValue = [IJTFormatString formatByteStream:wol->wol_sync_stream length:sizeof(wol->wol_sync_stream)];
                }
            }
            else if(indexPath.row == 1) {
                if(self.reader.layer3StartPosition == 0) {
                    if(self.reader.captureLengh == 122) {
                        dataLength = 6 * 16;
                    }
                    else {
                        dataLength = self.reader.captureLengh - self.reader.layer2StartPosition - 6;
                    }
                }
                else {
                    dataLength = self.reader.captureLengh - self.reader.layer4StartPosition - 6;
                }
                fieldName = @"MAC Address";
                fieldValue = [self ether_ntoa:((struct ether_addr *)&wol->wol_ether_addr)];
            }
            else if(indexPath.row == 2) {
                dataLength = 6;
                fieldName = @"Password";
                fieldValue = [self ether_ntoa:((struct ether_addr *)&wol->wol_password)];
            }
        }
            break;
        case IJTPacketReaderProtocolIPv6: {
            struct libnet_ipv6_hdr *ipv6 = self.reader.ipv6Header;
            if(indexPath.row == 0) {
                dataLength = 4;
                fieldName = @"Version";
                fieldValue = [NSString stringWithFormat:@"%d", (ipv6->ip_flags[0] & 0xf0) >> 4];
            }
            else if(indexPath.row == 1) {
                dataLength = 4;
                fieldName = @"Traffic Class";
                fieldValue = [IJTFormatString formatTrafficClass:ipv6->ip_flags length:sizeof(ipv6->ip_flags)];
            }
            else if(indexPath.row == 2) {
                dataLength = 4;
                fieldName = @"Flow Label";
                fieldValue = [IJTFormatString formatFlowLabel:ipv6->ip_flags length:sizeof(ipv6->ip_flags)];
            }
            else if(indexPath.row == 3) {
                dataLength = 2;
                fieldName = @"Payload Length";
                fieldValue = [IJTFormatString formatBytes:ntohs(ipv6->ip_len) carry:NO];
            }
            else if(indexPath.row == 4) {
                dataLength = 1;
                fieldName = @"Next Header";
                fieldValue = [IJTFormatString formatIpProtocol:ipv6->ip_nh];
            }
            else if(indexPath.row == 5) {
                dataLength = 1;
                fieldName = @"Hop Limit";
                fieldValue = [NSString stringWithFormat:@"%d", ipv6->ip_hl];
            }
            else if(indexPath.row == 6) {
                dataLength = 16;
                fieldName = @"Source";
                fieldValue = [IJTFormatString formatIpAddress:&ipv6->ip_src family:AF_INET6];
            }
            else if(indexPath.row == 7) {
                dataLength = 16;
                fieldName = @"Destination";
                fieldValue = [IJTFormatString formatIpAddress:&ipv6->ip_dst family:AF_INET6];
            }
        }
            break;
        case IJTPacketReaderProtocolICMPv6: {
            struct libnet_icmpv6_hdr *icmpv6 = self.reader.icmpv6Header;
            if(indexPath.row == 0) {
                dataLength = 1;
                fieldName = @"Type";
                fieldValue = [NSString stringWithFormat:@"%d", icmpv6->icmp_type];
            }
            else if(indexPath.row == 1) {
                dataLength = 1;
                fieldName = @"Code";
                fieldValue = [NSString stringWithFormat:@"%d", icmpv6->icmp_code];
            }
            else if(indexPath.row == 2) {
                dataLength = 2;
                fieldName = @"Checksum";
                fieldValue = [IJTFormatString formatChecksum:icmpv6->icmp_sum];
            }
            else if(indexPath.row == 3) {
                dataLength = 4;
                fieldName = @"Reserved";
                u_int32_t *reserved = (u_int32_t *)((u_char *)icmpv6 + 4);
                fieldValue = [NSString stringWithFormat:@"%06x", ntohl(*reserved)];
            }
        }
            break;
        case IJTPacketReaderProtocolIGMP: {
            struct libnet_igmp_hdr *igmp = self.reader.igmpHeader;
            if(indexPath.row == 0) {
                dataLength = 1;
                fieldName = @"Type";
                fieldValue = [NSString stringWithFormat:@"%#02x", igmp->igmp_type];
            }
            else if(indexPath.row == 1) {
                dataLength = 1;
                fieldName = @"Max Resp Time";
                fieldValue = [NSString stringWithFormat:@"%2.2f sec(%#02x)", igmp->igmp_code/10.f, igmp->igmp_code];
            }
            else if(indexPath.row == 2) {
                dataLength = 2;
                fieldName = @"Header Checksum";
                fieldValue = [IJTFormatString formatChecksum:igmp->igmp_sum];
            }
            else if(indexPath.row == 3) {
                dataLength = 4;
                fieldName = @"Multicast Address";
                fieldValue = [IJTFormatString formatIpAddress:&igmp->igmp_group family:AF_INET];
            }
        }
            break;
        case IJTPacketReaderProtocolICMPRedirect: {
            struct libnet_icmpv4_hdr *icmpv4 = self.reader.icmpv4Header;
            if(indexPath.row == 0) {
                dataLength = 1;
                fieldName = @"Type";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", icmpv4->icmp_type, [IJTFormatString formatIcmpType:icmpv4->icmp_type]];
            }
            else if(indexPath.row == 1) {
                dataLength = 1;
                fieldName = @"Code";
                fieldValue = [NSString stringWithFormat:@"%d(%@)", icmpv4->icmp_code, [IJTFormatString formatIcmpCode:icmpv4->icmp_code type:icmpv4->icmp_type]];
            }
            else if(indexPath.row == 2) {
                dataLength = 2;
                fieldName = @"Checksum";
                fieldValue = [IJTFormatString formatChecksum:icmpv4->icmp_sum];
            }
            else if(indexPath.row == 3) {
                dataLength = 4;
                fieldName = @"Gateway Address";
                fieldValue = [IJTFormatString formatIpAddress:&icmpv4->hun.gateway family:AF_INET];
            }
        }
            break;
        default: break;
    }
    
    IJTPacketFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PacketFieldCell"
                                                                        forIndexPath:indexPath];
    
    cell.protocol = protocol;
    cell.dataLength = dataLength;
    [IJTFormatUILabel text:fieldName
                     label:cell.fieldNameLabel
                      font:[UIFont systemFontOfSize:11]];
    [IJTFormatUILabel text:fieldValue
                     label:cell.fieldValueLabel
                     color:IJTValueColor
                      font:[UIFont systemFontOfSize:11]];
    cell.fieldValueLabel.adjustsFontSizeToFitWidth = YES;
    if(indexPath.row == self.selectIndexPath.row && indexPath.section == self.selectIndexPath.section) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [cell layoutIfNeeded];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section == self.section - 1 || indexPath.section == self.section - 2)
        return;
    
    self.hexDumpTextView.attributedText = self.hexDumpAttributedString;
    self.asciiDumpTextView.attributedText = self.asciiDumpAttributedString;
    
    if(indexPath.section == 0) {
        self.selectIndexPath = nil;
    }
    else if(indexPath.section == 1) {
        [self tableView:tableView
  selectDataAtIndexPath:indexPath
               protocol:self.reader.layer1Type
          startLocation:self.reader.layer1StartPosition];
    }
    else if(indexPath.section == 2) {
        [self tableView:tableView
  selectDataAtIndexPath:indexPath
               protocol:self.reader.layer2Type
          startLocation:self.reader.layer2StartPosition];
    }
    else if(indexPath.section == 3) {
        [self tableView:tableView
  selectDataAtIndexPath:indexPath
               protocol:self.reader.layer3Type
          startLocation:self.reader.layer3StartPosition];
    }
    else if(indexPath.section == 4) {
        if(self.reader.layer4Type != IJTPacketReaderProtocolUnknown) {
            [self tableView:tableView
      selectDataAtIndexPath:indexPath
                   protocol:self.reader.layer4Type
              startLocation:self.reader.layer4StartPosition];
        }
        else {
            [self tableView:tableView
      selectDataAtIndexPath:indexPath
                   protocol:self.reader.icmpLayer1Type
              startLocation:self.reader.icmpLayer1StartPosition];
        }
    }
    else if(indexPath.section == 5) {
        [self tableView:tableView
  selectDataAtIndexPath:indexPath
               protocol:self.reader.icmpLayer2Type
          startLocation:self.reader.icmpLayer2StartPosition];
    }
    
    for (NSInteger section = 1, sectionCount = self.tableView.numberOfSections - 2; section < sectionCount; ++section) {
        for (NSInteger row = 0, rowCount = [self.tableView numberOfRowsInSection:section]; row < rowCount; ++row) {
            IJTPacketFieldTableViewCell *cell =
            (IJTPacketFieldTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            if(indexPath.row == row && indexPath.section == section) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                self.selectIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
            }
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
            [cell layoutIfNeeded];
        }
    }
}

- (void)tableView:(UITableView *)tableView
selectDataAtIndexPath: (NSIndexPath *)indexPath
         protocol: (IJTPacketReaderProtocol)protocol
    startLocation: (NSInteger)startLocation {
    
    NSInteger inverseLocation = startLocation;
    NSInteger selectLocation = inverseLocation;
    NSUInteger dataLength = 0;
    NSUInteger inverseLength = 0;
    
    switch (protocol) {
        case IJTPacketReaderProtocolEthernet: {
            inverseLength = LIBNET_ETH_H;
            
            if(indexPath.row == 1) {
                selectLocation += 6;
            }
            else if(indexPath.row == 2) {
                selectLocation += 6 + 6;
            }
        }
            break;
        case IJTPacketReaderProtocolNULL: {
            inverseLength = 4;
        }
            break;
        case IJTPacketReaderProtocolIPv4:
        case IJTPacketReaderProtocolIPv4OverIcmp: {
            if(protocol == IJTPacketReaderProtocolIPv4)
                inverseLength = self.reader.ipv4Header->ip_hl << 2;
            else if(self.reader.icmpLayer2Type == IJTPacketReaderProtocolUnknown) { //redirect
                inverseLength = self.reader.captureLengh - self.reader.icmpLayer1StartPosition;
            }
            else
                inverseLength = self.reader.ipv4OverIcmpHeader->ip_hl << 2;
            
            if(indexPath.row == 2) {
                selectLocation += 1;
            }
            else if(indexPath.row == 3) {
                selectLocation += 1 + 1;
            }
            else if(indexPath.row == 4) {
                selectLocation += 1 + 1 + 2;
            }
            else if(indexPath.row == 5) {
                selectLocation += 1 + 1 + 2 + 2;
            }
            else if(indexPath.row == 6) {
                selectLocation += 1 + 1 + 2 + 2;
            }
            else if(indexPath.row == 7) {
                selectLocation += 1 + 1 + 2 + 2 + 2;
            }
            else if(indexPath.row == 8) {
                selectLocation += 1 + 1 + 2 + 2 + 2 + 1;
            }
            else if(indexPath.row == 9) {
                selectLocation += 1 + 1 + 2 + 2 + 2 + 2;
            }
            else if(indexPath.row == 10) {
                selectLocation += 1 + 1 + 2 + 2 + 2 + 2 + 2;
            }
            else if(indexPath.row == 11) {
                selectLocation += 1 + 1 + 2 + 2 + 2 + 2 + 2 + 4;
            }
            else if(indexPath.row == 12) {
                selectLocation += 1 + 1 + 2 + 2 + 2 + 2 + 2 + 4 + 4;
            }
        }
            break;
        case IJTPacketReaderProtocolICMPEcho:
        case IJTPacketReaderProtocolICMPEchoReply: {
            inverseLength = self.reader.captureLengh - self.reader.layer3StartPosition;
            
            if(indexPath.row == 1) {
                selectLocation += 1;
            }
            else if(indexPath.row == 2) {
                selectLocation += 1 + 1;
            }
            else if(indexPath.row == 3) {
                selectLocation += 1 + 1 + 2;
            }
            else if(indexPath.row == 4) {
                selectLocation += 1 + 1 + 2 + 2;
            }
            else if(indexPath.row == 5) {
                selectLocation += 1 + 1 + 2 + 2 + 2;
            }
        }
            break;
        case IJTPacketReaderProtocolICMPRedirect: {
            inverseLength = LIBNET_ICMPV4_REDIRECT_H;
            if(indexPath.row == 1) {
                selectLocation += 1;
            }
            else if(indexPath.row == 2) {
                selectLocation += 1 + 1;
            }
            else if(indexPath.row == 3) {
                selectLocation += 1 + 1 + 2;
            }
        }
            break;
        case IJTPacketReaderProtocolICMPFragment:
        case IJTPacketReaderProtocolTCPFragment:
        case IJTPacketReaderProtocolUDPFragment: {
            //inverseLength = self.reader.captureLengh - self.reader.layer2StartPosition;
        }
            break;
        case IJTPacketReaderProtocolARPOther: {
            //inverseLength = self.reader.captureLengh - self.reader.layer2StartPosition;
        }
            break;
        case IJTPacketReaderProtocolARPReply:
        case IJTPacketReaderProtocolARPRequest: {
            inverseLength = self.reader.captureLengh - self.reader.layer2StartPosition;
            struct arp_header *arp = self.reader.arpHeader;
            if(indexPath.row == 1) {
                selectLocation += 2;
            }
            else if(indexPath.row == 2) {
                selectLocation += 2 + 2;
            }
            else if(indexPath.row == 3) {
                selectLocation += 2 + 2 + 1;
            }
            else if(indexPath.row == 4) {
                selectLocation += 2 + 2 + 1 + 1;
            }
            else if(indexPath.row == 5) {
                selectLocation += 2 + 2 + 1 + 1 + 2;
            }
            else if(indexPath.row == 6) {
                selectLocation += 2 + 2 + 1 + 1 + 2 + arp->ar_hln;
            }
            else if(indexPath.row == 7) {
                selectLocation += 2 + 2 + 1 + 1 + 2 + arp->ar_hln + arp->ar_pln;
            }
            else if(indexPath.row == 8) {
                selectLocation += 2 + 2 + 1 + 1 + 2 + arp->ar_hln + arp->ar_pln + arp->ar_hln;
            }
        }
            break;
        case IJTPacketReaderProtocolOtherNetwork: {
            inverseLength = self.reader.captureLengh - self.reader.layer2StartPosition;
        }
            break;
        case IJTPacketReaderProtocolOtherTransport: {
            inverseLength = self.reader.captureLengh - self.reader.layer3StartPosition;
        }
            break;
        case IJTPacketReaderProtocolTCP:
        case IJTPacketReaderProtocolTCPOverICMP: {
            if(IJTPacketReaderProtocolTCP == protocol) {
                struct libnet_tcp_hdr *tcp = self.reader.tcpHeader;
                inverseLength = tcp->th_off << 2;
            }
            else {
                inverseLength = self.reader.captureLengh - self.reader.icmpLayer2StartPosition;
            }
            
            if(indexPath.row == 1) {
                selectLocation += 2;
            }
            else if(indexPath.row == 2) {
                selectLocation += 2 + 2;
            }
            else if(indexPath.row == 3) {
                selectLocation += 2 + 2 + 4;
            }
            else if(indexPath.row == 4) {
                selectLocation += 2 + 2 + 4 + 4;
            }
            else if(indexPath.row == 5) {
                selectLocation += 2 + 2 + 4 + 4;
            }
            else if(indexPath.row == 6) {
                selectLocation += 2 + 2 + 4 + 4 + 1;
            }
            else if(indexPath.row == 7) {
                selectLocation += 2 + 2 + 4 + 4 + 1 + 1;
            }
            else if(indexPath.row == 8) {
                selectLocation += 2 + 2 + 4 + 4 + 1 + 1 + 2;
            }
            else if(indexPath.row == 9) {
                selectLocation += 2 + 2 + 4 + 4 + 1 + 1 + 2 + 2;
            }
            else if(indexPath.row == 10) {
                selectLocation += 2 + 2 + 4 + 4 + 1 + 1 + 2 + 2 + 2;
            }
        }
            break;
        case IJTPacketReaderProtocolUDP:
        case IJTPacketReaderProtocolUDPOverICMP: {
            if(IJTPacketReaderProtocolUDP == protocol) {
                inverseLength = LIBNET_UDP_H;
            }
            else {
                inverseLength = self.reader.captureLengh - self.reader.icmpLayer2StartPosition;
            }
            if(indexPath.row == 1) {
                selectLocation += 2;
            }
            else if(indexPath.row == 2) {
                selectLocation += 2 + 2;
            }
            else if(indexPath.row == 3) {
                selectLocation += 2 + 2 + 2;
            }
            else if(indexPath.row == 4) {
                selectLocation += 2 + 2 + 2 + 2;
            }
        }
            break;
        case IJTPacketReaderProtocolDHCP:
        case IJTPacketReaderProtocolDNS:
        case IJTPacketReaderProtocolHTTP:
        case IJTPacketReaderProtocolHTTPS:
        case IJTPacketReaderProtocolIMAP:
        case IJTPacketReaderProtocolIMAPS:
        case IJTPacketReaderProtocolMDNS:
        case IJTPacketReaderProtocolNTPv4:
        case IJTPacketReaderProtocolOtherApplication:
        case IJTPacketReaderProtocolSMTP:
        case IJTPacketReaderProtocolSSDP:
        case IJTPacketReaderProtocolSSH:
        case IJTPacketReaderProtocolWhois: {
            inverseLength = self.reader.captureLengh - self.reader.layer4StartPosition;
        }
            break;
        case IJTPacketReaderProtocolSNAP:
        case IJTPacketReaderProtocolEAPOL: {
            inverseLength = self.reader.captureLengh - self.reader.layer2StartPosition;
        }
            break;
        case IJTPacketReaderProtocolICMPOther: {
            inverseLength = self.reader.captureLengh - self.reader.layer3StartPosition;
        }
            break;
        case IJTPacketReaderProtocolWOL: {
            if(indexPath.row == 1) {
                selectLocation += 6;
            }
            else if(indexPath.row == 2) {
                selectLocation += 6 + 16 * 6;
            }
        }
            break;
        case IJTPacketReaderProtocolIPv6: {
            inverseLength = LIBNET_IPV6_H;
            if(indexPath.row == 3) {
                selectLocation += 4;
            }
            else if(indexPath.row == 4) {
                selectLocation += 4 + 2;
            }
            else if(indexPath.row == 5) {
                selectLocation += 4 + 2 + 1;
            }
            else if(indexPath.row == 6) {
                selectLocation += 4 + 2 + 1 + 1;
            }
            else if(indexPath.row == 7) {
                selectLocation += 4 + 2 + 1 + 1 + 16;
            }
        }
            break;
        case IJTPacketReaderProtocolICMPv6: {
            inverseLength = LIBNET_ICMPV6_H;
            if(indexPath.row == 1) {
                selectLocation += 1;
            }
            else if(indexPath.row == 2) {
                selectLocation += 1 + 1;
            }
            else if(indexPath.row == 3) {
                selectLocation += 1 + 1 + 2;
            }
        }
            break;
        case IJTPacketReaderProtocolIGMP: {
            inverseLength = LIBNET_IGMP_H;
            if(indexPath.row == 1) {
                selectLocation += 1;
            }
            else if(indexPath.row == 2) {
                selectLocation += 1 + 1;
            }
            else if(indexPath.row == 3) {
                selectLocation += 1 + 1 + 2;
            }
        }
            break;
        case IJTPacketReaderProtocolICMPTimexceed:
        case IJTPacketReaderProtocolICMPUnreach: {
            inverseLength = protocol == IJTPacketReaderProtocolICMPTimexceed ? LIBNET_ICMPV4_TIMXCEED_H : LIBNET_ICMPV4_UNREACH_H;
            if(indexPath.row == 1) {
                selectLocation += 1;
            }
            else if(indexPath.row == 2) {
                selectLocation += 1 + 1;
            }
        }
            break;
        default: break;
    }
    
    IJTPacketFieldTableViewCell *cell = (IJTPacketFieldTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    dataLength = cell.dataLength;
    [IJTFormatUITextView textView:self.hexDumpTextView
                      selectRange:NSMakeRange(selectLocation, dataLength)
                  selectTextColor:IJTWhiteColor
            selectBackgroundColor:[IJTColor lighter:IJTToolsColor times:2]
                     inverseRange:NSMakeRange(inverseLocation, inverseLength)
                 inverseTextColor:[IJTColor darker:IJTGrayColor times:4]
           inverseBackgroundColor:IJTGrayColor
                     oneDataWidth:2];
    
    [IJTFormatUITextView textView:self.asciiDumpTextView
                      selectRange:NSMakeRange(selectLocation, dataLength)
                  selectTextColor:IJTWhiteColor
            selectBackgroundColor:[IJTColor lighter:IJTToolsColor times:2]
                     inverseRange:NSMakeRange(inverseLocation, inverseLength)
                 inverseTextColor:[IJTColor darker:IJTGrayColor times:4]
           inverseBackgroundColor:IJTGrayColor
                     oneDataWidth:1];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return @"Packet Information";
    else if(section == self.section - 1)
        return @"Hex Dump";
    else if(section == self.section - 2)
        return @"ASCII Dump";
    else if(section == 1) {
        return [IJTPacketReader protocol2String:self.reader.layer1Type];
    }
    else if(section == 2) {
        return [IJTPacketReader protocol2String:self.reader.layer2Type];
    }
    else if(section == 3) {
        return [IJTPacketReader protocol2String:self.reader.layer3Type];
    }
    else if(section == 4) {
        if(self.reader.layer4Type != IJTPacketReaderProtocolUnknown)
            return [IJTPacketReader protocol2String:self.reader.layer4Type];
        else
            return [IJTPacketReader protocol2String:self.reader.icmpLayer1Type];
    }
    else if(section == 5) {
        return [IJTPacketReader protocol2String:self.reader.icmpLayer2Type];
    }
    
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    else if(indexPath.section == self.section - 1) {
        return CGRectGetHeight(self.hexDumpTextView.frame);
    }
    else if(indexPath.section == self.section - 2) {
        return CGRectGetHeight(self.asciiDumpTextView.frame);
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (NSString *)ether_ntoa:(const struct ether_addr *)addr {
    return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", addr->octet[0], addr->octet[1], addr->octet[2], addr->octet[3], addr->octet[4], addr->octet[5]];
}

@end
