//
//  IJTPacketReader.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTPacketReader.h"
#import <UIKit/UIKit.h>

@interface IJTPacketReader ()

@property (nonatomic) packet_t packet;

@end

@implementation IJTPacketReader

/*from wireshark aftypes.h*/
#define BSD_AF_INET		2
#define BSD_AF_INET6_BSD	24	/* OpenBSD (and probably NetBSD), BSD/OS */
#define BSD_AF_INET6_FREEBSD	28
#define BSD_AF_INET6_DARWIN	30

#define ETHERTYPE_WOL 0x0842
#define ETHERTYPE_EAPOL 0x888e
- (id)initWithPacket: (packet_t)packet
                type: (IJTPacketReaderType)type
               index: (NSUInteger)index {
    self = [super init];
    if(self) {
        
        memset(&_packet, 0, sizeof(_packet));
        memcpy(&_packet, &packet, sizeof(_packet));
        _dataLinkData = type;
        
        BOOL changePort = YES;
        u_int8_t *content = _packet.content;
        self.sourceIPAddress = @"N/A";
        self.destinationIPAddress = @"N/A";
        self.sourceMacAddress = @"N/A";
        self.destinationMacAddress = @"N/A";
        self.finalProtocolType = IJTPacketReaderProtocolUnknown;
        self.layer1StartPosition = 0;
        self.layer2StartPosition = 0;
        self.layer3StartPosition = 0;
        self.layer4StartPosition = 0;
        self.layer1Type = IJTPacketReaderProtocolUnknown;
        self.layer2Type = IJTPacketReaderProtocolUnknown;
        self.layer3Type = IJTPacketReaderProtocolUnknown;
        self.layer4Type = IJTPacketReaderProtocolUnknown;
        self.ip_ttl = 0;
        self.ip_portocol = 0;
        self.icmp_ID = 0;
        self.icmp_Seq = 0;
        self.sourcePort = 0;
        self.destinationPort = 0;
        _timestamp.tv_sec = packet.header.ts.tv_sec;
        _timestamp.tv_usec = packet.header.ts.tv_usec;
        self.captureLengh = packet.header.caplen;
        self.frameLengh = packet.header.len;
        self.index = index;
        self.ethernetHeader = NULL;
        self.bsdNullHeader = NULL;
        self.ipv4Header = NULL;
        self.icmpv4Header = NULL;
        self.arpHeader = NULL;
        self.tcpHeader = NULL;
        self.udpHeader = NULL;
        self.wolHeader = NULL;
        self.ipv6Header = NULL;
        self.icmpv6Header = NULL;
        self.igmpHeader = NULL;
        self.icmpLayer1StartPosition = 0;
        self.icmpLayer1Type = IJTPacketReaderProtocolUnknown;
        self.icmpLayer2StartPosition = 0;
        self.icmpLayer2Type = IJTPacketReaderProtocolUnknown;
        self.ipv4OverIcmpHeader = NULL;
        self.tcpOverIcmpHeader = NULL;
        self.udpOverIcmpHeader = NULL;
        
        int layer1lengh = 0;
        struct libnet_ethernet_hdr *ethernet;
        
        if(type == IJTPacketReaderTypeWiFi) {
            ethernet = (struct libnet_ethernet_hdr *)content;
            layer1lengh = LIBNET_ETH_H;
            
            _sourceMacAddress = [self ether_ntoa:((struct ether_addr *)&ethernet->ether_shost)];
            _destinationMacAddress = [self ether_ntoa:((struct ether_addr *)&ethernet->ether_dhost)];
            self.finalProtocolType = IJTPacketReaderProtocolEthernet;
            self.layer1Type = IJTPacketReaderProtocolEthernet;
            self.layer1StartPosition = 0;
            self.ethernetHeader = (struct libnet_ethernet_hdr *)content;
        }
        else {
            //from wireshark packet-null.c
            struct libnet_ethernet_hdr loopback;
            
            memset(&loopback, 0, sizeof(loopback));
            u_int32_t type = *content;
            switch (type) {
                case BSD_AF_INET:
                    loopback.ether_type = htons(ETHERTYPE_IP);
                    break;
                case BSD_AF_INET6_BSD:
                case BSD_AF_INET6_FREEBSD:
                case BSD_AF_INET6_DARWIN:
                    loopback.ether_type = htons(ETHERTYPE_IPV6);
                    break;
                default:
                    loopback.ether_type = 0;
                    self.finalProtocolType = IJTPacketReaderProtocolOtherNetwork;
                    self.layer1Type = IJTPacketReaderProtocolOtherNetwork;
            }//end switch
            
            layer1lengh = BSD_NULL_LEN;
            ethernet = &loopback;
            self.layer1Type = IJTPacketReaderProtocolNULL;
            self.layer1StartPosition = 0;
            self.bsdNullHeader = (struct bsd_null_hdr *)content;
        }//end else cell
        
        if(ethernet->ether_type == ntohs(ETHERTYPE_ARP) || ethernet->ether_type == ntohs(ETHERTYPE_REVARP)) {
            struct arp_header *arp = (struct arp_header *)(content + layer1lengh);
            
            char ntop_buf[256];
            memset(ntop_buf, 0, sizeof(ntop_buf));
            
            inet_ntop(AF_INET, &arp->ar_spa, ntop_buf, sizeof(ntop_buf));
            _sourceIPAddress = [NSString stringWithUTF8String:ntop_buf];
            
            inet_ntop(AF_INET, &arp->ar_tpa, ntop_buf, sizeof(ntop_buf));
            _destinationIPAddress = [NSString stringWithUTF8String:ntop_buf];
            
            if(arp->ar_op == ntohs(ARPOP_REPLY))
                self.finalProtocolType = IJTPacketReaderProtocolARPReply;
            else if(arp->ar_op == ntohs(ARPOP_REQUEST))
                self.finalProtocolType = IJTPacketReaderProtocolARPRequest;
            else
                self.finalProtocolType = IJTPacketReaderProtocolARPOther;
            self.layer2Type = self.finalProtocolType;
            self.layer2StartPosition = layer1lengh;
            self.arpHeader = arp;
        }
        else if(ethernet->ether_type == ntohs(ETHERTYPE_IP)) {
            self.finalProtocolType = IJTPacketReaderProtocolIPv4;
            self.layer2Type = IJTPacketReaderProtocolIPv4;
            self.layer2StartPosition = layer1lengh;
            
            struct libnet_ipv4_hdr *ipv4 = (struct libnet_ipv4_hdr *)(content + layer1lengh);
            char ntop_buf[256];
            memset(ntop_buf, 0, sizeof(ntop_buf));
            
            inet_ntop(AF_INET, &ipv4->ip_src, ntop_buf, sizeof(ntop_buf));
            _sourceIPAddress = [NSString stringWithUTF8String:ntop_buf];
            
            inet_ntop(AF_INET, &ipv4->ip_dst, ntop_buf, sizeof(ntop_buf));
            _destinationIPAddress = [NSString stringWithUTF8String:ntop_buf];
            
            u_int ip_hl = ipv4->ip_hl << 2;
            
            self.layer3StartPosition = layer1lengh + ip_hl;
            self.ip_ttl = ipv4->ip_ttl;
            self.ip_portocol = ipv4->ip_p;
            
            self.ipv4Header = ipv4;
            
            if(ipv4->ip_p == IPPROTO_ICMP) {
                struct libnet_icmpv4_hdr *icmp =
                (struct libnet_icmpv4_hdr *)(content + layer1lengh + ip_hl);
                if(((ntohs(ipv4->ip_off) & IP_MF) && (ntohs(ipv4->ip_off) & IP_OFFMASK) == 0) ||
                   ((ntohs(ipv4->ip_off) & IP_OFFMASK) == 0)) { //first fragment packet
                    
                    if(icmp->icmp_type == ICMP_ECHOREPLY || icmp->icmp_type == ICMP_ECHO) {
                        self.icmp_ID = icmp->icmp_id;
                        self.icmp_Seq = icmp->icmp_seq;
                    }//end if
                    
                    if(icmp->icmp_type == ICMP_ECHO)
                        self.layer3Type = IJTPacketReaderProtocolICMPEcho;
                    else if(icmp->icmp_type == ICMP_ECHOREPLY)
                        self.layer3Type = IJTPacketReaderProtocolICMPEchoReply;
                    else if(icmp->icmp_type == ICMP_TIMXCEED || icmp->icmp_type == ICMP_UNREACH) {
                        self.layer3Type = icmp->icmp_type == ICMP_TIMXCEED ? IJTPacketReaderProtocolICMPTimexceed : IJTPacketReaderProtocolICMPUnreach;
                        self.icmpLayer1Type = IJTPacketReaderProtocolIPv4OverIcmp;
                        self.icmpLayer1StartPosition = icmp->icmp_type == ICMP_TIMXCEED ?
                        layer1lengh + ip_hl + LIBNET_ICMPV4_TIMXCEED_H :
                        layer1lengh + ip_hl + LIBNET_ICMPV4_UNREACH_H;
                        
                        struct libnet_ipv4_hdr *ipv4_2 = (struct libnet_ipv4_hdr *)(content + self.icmpLayer1StartPosition);
                        self.ipv4OverIcmpHeader = ipv4_2;
                        u_int ip_hl2 = ipv4_2->ip_hl << 2;
                        
                        BOOL tcp = ipv4->ip_p == IPPROTO_TCP ? YES : NO;
                        //BOOL udp = ipv4->ip_p == IPPROTO_UDP ? YES : NO;
                        
                        self.icmpLayer2Type = tcp ? IJTPacketReaderProtocolTCPOverICMP : IJTPacketReaderProtocolUDPOverICMP;
                        self.icmpLayer2StartPosition = self.icmpLayer1StartPosition + ip_hl2;
                        if(tcp) {
                            struct libnet_tcp_hdr *tcphdr =
                            (struct libnet_tcp_hdr *)(content + self.icmpLayer1StartPosition + ip_hl2);
                            self.tcpOverIcmpHeader = tcphdr;
                        }//end if tcp
                        else {
                            struct libnet_udp_hdr *udphdr =
                            (struct libnet_udp_hdr *)(content + self.icmpLayer1StartPosition + ip_hl2);
                            self.udpOverIcmpHeader = udphdr;
                        }//end udp
                    }
                    else if(icmp->icmp_type == ICMP_REDIRECT) {
                        self.layer3Type = IJTPacketReaderProtocolICMPRedirect;
                        self.icmpLayer1Type = IJTPacketReaderProtocolIPv4OverIcmp;
                        self.icmpLayer1StartPosition = layer1lengh + ip_hl + LIBNET_ICMPV4_REDIRECT_H;
                        struct libnet_ipv4_hdr *ipv4_2 = (struct libnet_ipv4_hdr *)(content + self.icmpLayer1StartPosition);
                        self.ipv4OverIcmpHeader = ipv4_2;
                        //self.icmpLayer2StartPosition = self.icmpLayer1StartPosition + (ipv4_2->ip_hl << 2);
                    }
                    else
                        self.layer3Type = IJTPacketReaderProtocolICMPOther;
                    self.finalProtocolType = self.layer3Type;
                }//first or first fragment packet
                else { //other framgent packet and last one
                    self.layer3Type = IJTPacketReaderProtocolICMPFragment;
                    self.finalProtocolType = IJTPacketReaderProtocolICMPFragment;
                }
                self.icmpv4Header = icmp;
            }//end if icmp
            else if(ipv4->ip_p == IPPROTO_TCP || ipv4->ip_p == IPPROTO_UDP) {
                if(((ntohs(ipv4->ip_off) & IP_MF) && (ntohs(ipv4->ip_off) & IP_OFFMASK) == 0) ||
                   ((ntohs(ipv4->ip_off) & IP_OFFMASK) == 0)) { //first fragment packet
                    
                    BOOL tcp = ipv4->ip_p == IPPROTO_TCP ? YES : NO;
                    //BOOL udp = ipv4->ip_p == IPPROTO_UDP ? YES : NO;
                    
                    self.layer3Type = tcp ? IJTPacketReaderProtocolTCP : IJTPacketReaderProtocolUDP;
                    
                    u_short sport = 0;
                    u_short dport = 0;
                    
                    if(tcp) {
                        struct libnet_tcp_hdr *tcphdr =
                        (struct libnet_tcp_hdr *)(content + layer1lengh + ip_hl);
                        u_int tcp_hl = tcphdr->th_off << 2;
                        if(ntohs(ipv4->ip_len) - ip_hl - tcp_hl == 0) {
                            self.finalProtocolType = IJTPacketReaderProtocolTCP;
                            changePort = NO;
                        }
                        
                        sport = ntohs(tcphdr->th_sport);
                        dport = ntohs(tcphdr->th_dport);
                        self.layer4StartPosition = layer1lengh + ip_hl + tcp_hl;
                        self.tcpHeader = tcphdr;
                    }//end if tcp
                    else {
                        struct libnet_udp_hdr *udphdr =
                        (struct libnet_udp_hdr *)(content + layer1lengh + ip_hl);
                        if(ntohs(ipv4->ip_len) - ip_hl - LIBNET_UDP_H == 0) {
                            self.finalProtocolType = IJTPacketReaderProtocolUDP;
                            changePort = NO;
                        }
                        
                        sport = ntohs(udphdr->uh_sport);
                        dport = ntohs(udphdr->uh_dport);
                        self.layer4StartPosition = layer1lengh + ip_hl + LIBNET_UDP_H;
                        self.udpHeader = udphdr;
                    }//end udp
                    
                    self.sourcePort = sport;
                    self.destinationPort = dport;

                    if(changePort) {
                        if(sport == 80 || dport == 80)
                            self.finalProtocolType = IJTPacketReaderProtocolHTTP;
                        else if(sport == 443 || dport == 443)
                            self.finalProtocolType = IJTPacketReaderProtocolHTTPS;
                        else if(sport == 53 || dport == 53)
                            self.finalProtocolType = IJTPacketReaderProtocolDNS;
                        else if(sport == 5353 || dport == 5353)
                            self.finalProtocolType = IJTPacketReaderProtocolMDNS;
                        else if(sport == 1900 || dport == 1900)
                            self.finalProtocolType = IJTPacketReaderProtocolSSDP;
                        else if(sport == 22 || dport == 22)
                            self.finalProtocolType = IJTPacketReaderProtocolSSH;
                        else if(sport == 143 || dport == 143)
                            self.finalProtocolType = IJTPacketReaderProtocolIMAP;
                        else if(sport == 993 || dport == 993)
                            self.finalProtocolType = IJTPacketReaderProtocolIMAPS;
                        else if(sport == 25 || dport == 25)
                            self.finalProtocolType = IJTPacketReaderProtocolSMTP;
                        else if(sport == 67 || dport == 67 || sport == 68 || dport == 68)
                            self.finalProtocolType = IJTPacketReaderProtocolDHCP;
                        else if(sport == 43 || dport == 43)
                            self.finalProtocolType = IJTPacketReaderProtocolWhois;
                        else if((sport == 7 || dport == 7 || sport == 9 || dport == 9) && _packet.header.caplen == 144) {
                            self.finalProtocolType = IJTPacketReaderProtocolWOL;
                            self.wolHeader = (struct wol_header *)(content + self.layer4StartPosition);
                        }
                        else if(sport == 123 || dport == 123)
                            self.finalProtocolType = IJTPacketReaderProtocolNTPv4;
                        else
                            self.finalProtocolType = IJTPacketReaderProtocolOtherApplication;
                    }//end change port
                    
                    if(sport == 80 || dport == 80)
                        self.layer4Type = IJTPacketReaderProtocolHTTP;
                    else if(sport == 443 || dport == 443)
                        self.layer4Type = IJTPacketReaderProtocolHTTPS;
                    else if(sport == 53 || dport == 53)
                        self.layer4Type = IJTPacketReaderProtocolDNS;
                    else if(sport == 5353 || dport == 5353)
                        self.layer4Type = IJTPacketReaderProtocolMDNS;
                    else if(sport == 1900 || dport == 1900)
                        self.layer4Type = IJTPacketReaderProtocolSSDP;
                    else if(sport == 22 || dport == 22)
                        self.layer4Type = IJTPacketReaderProtocolSSH;
                    else if(sport == 143 || dport == 143)
                        self.layer4Type = IJTPacketReaderProtocolIMAP;
                    else if(sport == 993 || dport == 993)
                        self.layer4Type = IJTPacketReaderProtocolIMAPS;
                    else if(sport == 25 || dport == 25)
                        self.layer4Type = IJTPacketReaderProtocolSMTP;
                    else if(sport == 67 || dport == 67 || sport == 68 || dport == 68)
                        self.layer4Type = IJTPacketReaderProtocolDHCP;
                    else if(sport == 43 || dport == 43)
                        self.layer4Type = IJTPacketReaderProtocolWhois;
                    else if((sport == 7 || dport == 7 || sport == 9 || dport == 9) && _packet.header.caplen == 144)
                        self.layer4Type = IJTPacketReaderProtocolWOL;
                    else if(sport == 123 || dport == 123)
                        self.layer4Type = IJTPacketReaderProtocolNTPv4;
                    else
                        self.layer4Type = IJTPacketReaderProtocolOtherApplication;
                    
                }//first or first fragment packet
                else {
                    BOOL tcp = ipv4->ip_p == IPPROTO_TCP ? YES : NO;
                    if(tcp) {
                        self.layer3Type = IJTPacketReaderProtocolTCPFragment;
                        self.finalProtocolType = IJTPacketReaderProtocolTCPFragment;
                    }
                    else {
                        self.layer3Type = IJTPacketReaderProtocolUDPFragment;
                        self.finalProtocolType = IJTPacketReaderProtocolUDPFragment;
                    }
                } //other framgent packet and last one
            }//end if tcp or udp
            else if(ipv4->ip_p == IPPROTO_IPV6) {
                self.layer3Type = IJTPacketReaderProtocolIPv6;
            }
            else if(ipv4->ip_p == IPPROTO_IGMP) {
                self.finalProtocolType = IJTPacketReaderProtocolIGMP;
                self.layer3Type = IJTPacketReaderProtocolIGMP;
                self.igmpHeader = (struct libnet_igmp_hdr *)(content + self.layer3StartPosition);
            }
            else if(ipv4->ip_p == IPPROTO_IP || ipv4->ip_p == IPPROTO_IPV4) {
                self.finalProtocolType = IJTPacketReaderProtocolIPv4;
                self.layer3Type = IJTPacketReaderProtocolIPv4;
            }
            else {
                self.finalProtocolType = IJTPacketReaderProtocolOtherTransport;
                self.layer3Type = IJTPacketReaderProtocolOtherTransport;
            }
        }//end if ipv4
        else if(ethernet->ether_type == ntohs(ETHERTYPE_IPV6)) {
            self.finalProtocolType = IJTPacketReaderProtocolIPv6;
            self.layer2Type = IJTPacketReaderProtocolIPv6;
            self.layer2StartPosition = layer1lengh;
            
            struct libnet_ipv6_hdr *ipv6 = (struct libnet_ipv6_hdr *)(content + layer1lengh);
            
            self.ip_ttl = ipv6->ip_hl;
            self.ip_portocol = ipv6->ip_nh;
            self.layer3StartPosition = layer1lengh + LIBNET_IPV6_H;
            self.ipv6Header = ipv6;
            
            char ntop_buf[256];
            memset(ntop_buf, 0, sizeof(ntop_buf));
            
            inet_ntop(AF_INET6, &ipv6->ip_src, ntop_buf, sizeof(ntop_buf));
            _sourceIPAddress = [NSString stringWithUTF8String:ntop_buf];
            
            inet_ntop(AF_INET6, &ipv6->ip_dst, ntop_buf, sizeof(ntop_buf));
            _destinationIPAddress = [NSString stringWithUTF8String:ntop_buf];
            
            if(ipv6->ip_nh == IPPROTO_ICMPV6) {
                self.finalProtocolType = IJTPacketReaderProtocolICMPv6;
                self.layer3Type = IJTPacketReaderProtocolICMPv6;
                self.icmpv6Header = (struct libnet_icmpv6_hdr *)(content + self.layer3StartPosition);
            }
            else if(ipv6->ip_nh == IPPROTO_TCP || ipv6->ip_nh == IPPROTO_UDP) {
                BOOL tcp = ipv6->ip_nh == IPPROTO_TCP ? YES : NO;
                //BOOL udp = ipv6->ip_nh == IPPROTO_UDP ? YES : NO;
                u_short sport = 0;
                u_short dport = 0;
                
                self.layer3Type = tcp ? IJTPacketReaderProtocolTCP : IJTPacketReaderProtocolUDP;
                
                if(tcp) {
                    struct libnet_tcp_hdr *tcphdr =
                    (struct libnet_tcp_hdr *)(content + layer1lengh + LIBNET_IPV6_H);
                    u_int tcp_hl = tcphdr->th_off << 2;
                    if(ntohs(ipv6->ip_len) == tcp_hl) {
                        self.finalProtocolType = IJTPacketReaderProtocolTCP;
                        changePort = NO;
                    }
                    
                    sport = ntohs(tcphdr->th_sport);
                    dport = ntohs(tcphdr->th_dport);
                    self.layer4StartPosition = layer1lengh + LIBNET_IPV6_H + tcp_hl;
                    self.tcpHeader = tcphdr;
                }//end if tcp
                else {
                    struct libnet_udp_hdr *udphdr =
                    (struct libnet_udp_hdr *)(content + layer1lengh + LIBNET_IPV6_H);
                    if(ntohs(ipv6->ip_len) == LIBNET_UDP_H) {
                        self.finalProtocolType = IJTPacketReaderProtocolUDP;
                        changePort = NO;
                    }
                    
                    sport = ntohs(udphdr->uh_sport);
                    dport = ntohs(udphdr->uh_dport);
                    self.layer4StartPosition = layer1lengh + LIBNET_IPV6_H + LIBNET_UDP_H;
                    self.udpHeader = udphdr;
                }//end udp
                
                self.sourcePort = sport;
                self.destinationPort = dport;
                
                if(changePort) {
                    if(sport == 80 || dport == 80)
                        self.finalProtocolType = IJTPacketReaderProtocolHTTP;
                    else if(sport == 443 || dport == 443)
                        self.finalProtocolType = IJTPacketReaderProtocolHTTPS;
                    else if(sport == 53 || dport == 53)
                        self.finalProtocolType = IJTPacketReaderProtocolDNS;
                    else if(sport == 5353 || dport == 5353)
                        self.finalProtocolType = IJTPacketReaderProtocolMDNS;
                    else if(sport == 1900 || dport == 1900)
                        self.finalProtocolType = IJTPacketReaderProtocolSSDP;
                    else if(sport == 22 || dport == 22)
                        self.finalProtocolType = IJTPacketReaderProtocolSSH;
                    else if(sport == 143 || dport == 143)
                        self.finalProtocolType = IJTPacketReaderProtocolIMAP;
                    else if(sport == 993 || dport == 993)
                        self.finalProtocolType = IJTPacketReaderProtocolIMAPS;
                    else if(sport == 25 || dport == 25)
                        self.finalProtocolType = IJTPacketReaderProtocolSMTP;
                    else if(sport == 67 || dport == 67 || sport == 68 || dport == 68)
                        self.finalProtocolType = IJTPacketReaderProtocolDHCP;
                    else if(sport == 43 || dport == 43)
                        self.finalProtocolType = IJTPacketReaderProtocolWhois;
                    else if((sport == 7 || dport == 7 || sport == 9 || dport == 9) && _packet.header.caplen == 144)
                        self.finalProtocolType = IJTPacketReaderProtocolWOL;
                    else if(sport == 123 || dport == 123)
                        self.finalProtocolType = IJTPacketReaderProtocolNTPv4;
                    else
                        self.finalProtocolType = IJTPacketReaderProtocolOtherApplication;
                }//end change port
                if(sport == 80 || dport == 80)
                    self.layer4Type = IJTPacketReaderProtocolHTTP;
                else if(sport == 443 || dport == 443)
                    self.layer4Type = IJTPacketReaderProtocolHTTPS;
                else if(sport == 53 || dport == 53)
                    self.layer4Type = IJTPacketReaderProtocolDNS;
                else if(sport == 5353 || dport == 5353)
                    self.layer4Type = IJTPacketReaderProtocolMDNS;
                else if(sport == 1900 || dport == 1900)
                    self.layer4Type = IJTPacketReaderProtocolSSDP;
                else if(sport == 22 || dport == 22)
                    self.layer4Type = IJTPacketReaderProtocolSSH;
                else if(sport == 143 || dport == 143)
                    self.layer4Type = IJTPacketReaderProtocolIMAP;
                else if(sport == 993 || dport == 993)
                    self.layer4Type = IJTPacketReaderProtocolIMAPS;
                else if(sport == 25 || dport == 25)
                    self.layer4Type = IJTPacketReaderProtocolSMTP;
                else if(sport == 67 || dport == 67 || sport == 68 || dport == 68)
                    self.layer4Type = IJTPacketReaderProtocolDHCP;
                else if(sport == 43 || dport == 43)
                    self.layer4Type = IJTPacketReaderProtocolWhois;
                else if((sport == 7 || dport == 7 || sport == 9 || dport == 9) && _packet.header.caplen == 144)
                    self.layer4Type = IJTPacketReaderProtocolWOL;
                else if(sport == 123 || dport == 123)
                    self.layer4Type = IJTPacketReaderProtocolNTPv4;
                else
                    self.layer4Type = IJTPacketReaderProtocolOtherApplication;
            }//end if tcp or udp
            else if(ipv6->ip_nh == IPPROTO_HOPOPTS) {
                self.finalProtocolType = IJTPacketReaderProtocolIPv6;
                self.layer3Type = IJTPacketReaderProtocolIPv6;
            }//end ipv6 extened header
            else {
                self.finalProtocolType = IJTPacketReaderProtocolOtherTransport;
                self.layer3Type = IJTPacketReaderProtocolOtherTransport;
            }
        }//end if ipv6
        else if(ethernet->ether_type == ntohs(ETHERTYPE_WOL)) {
            self.finalProtocolType = IJTPacketReaderProtocolWOL;
            self.layer2Type = IJTPacketReaderProtocolWOL;
            self.layer2StartPosition = layer1lengh;
            self.wolHeader = (struct wol_header *)(content + self.layer2StartPosition);
        }
        else if(ethernet->ether_type == ntohs(ETHERTYPE_EAPOL)) {
            self.finalProtocolType = IJTPacketReaderProtocolEAPOL;
            self.layer2Type = IJTPacketReaderProtocolEAPOL;
            self.layer2StartPosition = layer1lengh;
        }
        else {
            u_char *temp = (u_char *)(content + layer1lengh);
            if(*temp == 0xAA && *(temp + 1) == 0xAA) {
                self.finalProtocolType = IJTPacketReaderProtocolSNAP;
                self.layer2Type = IJTPacketReaderProtocolSNAP;
                self.layer2StartPosition = layer1lengh;
            }
            else {
                self.finalProtocolType = IJTPacketReaderProtocolOtherNetwork;
                self.layer2Type = IJTPacketReaderProtocolOtherNetwork;
                self.layer2StartPosition = layer1lengh;
            }
        }
    }
    return self;
}

+ (NSString *)protocol2DetailString:(IJTPacketReaderProtocol)proto {
    
    switch (proto) {
        case IJTPacketReaderProtocolUnknown: return @"Unknown";
        case IJTPacketReaderProtocolOtherNetwork: return @"Other network";
        case IJTPacketReaderProtocolARPReply: return @"ARP reply";
        case IJTPacketReaderProtocolARPRequest: return @"ARP request";
        case IJTPacketReaderProtocolARPOther: return @"ARP other";
        case IJTPacketReaderProtocolIPv4: return @"IPv4";
        case IJTPacketReaderProtocolICMPEcho: return @"ICMP echo";
        case IJTPacketReaderProtocolICMPEchoReply: return @"ICMP echo reply";
        case IJTPacketReaderProtocolICMPTimexceed: return @"ICMP timexceed";
        case IJTPacketReaderProtocolICMPRedirect: return @"ICMP redirect";
        case IJTPacketReaderProtocolICMPUnreach: return @"ICMP unreachable";
        case IJTPacketReaderProtocolICMPOther: return @"ICMP other";
        case IJTPacketReaderProtocolICMPFragment: return @"ICMP fragmented";
        case IJTPacketReaderProtocolTCP: return @"TCP";
        case IJTPacketReaderProtocolTCPFragment: return @"TCP fragmented";
        case IJTPacketReaderProtocolUDP: return @"UDP";
        case IJTPacketReaderProtocolUDPFragment: return @"UDP fragmented";
        case IJTPacketReaderProtocolHTTP: return @"HTTP";
        case IJTPacketReaderProtocolHTTPS: return @"HTTPS";
        case IJTPacketReaderProtocolDNS: return @"DNS";
        case IJTPacketReaderProtocolMDNS: return @"MDNS";
        case IJTPacketReaderProtocolSSDP: return @"SSDP";
        case IJTPacketReaderProtocolSSH: return @"SSH";
        case IJTPacketReaderProtocolIMAP: return @"IMAP";
        case IJTPacketReaderProtocolIMAPS: return @"IMAPS";
        case IJTPacketReaderProtocolSMTP: return @"SMTP";
        case IJTPacketReaderProtocolWhois: return @"Whois";
        case IJTPacketReaderProtocolWOL: return @"WOL";
        case IJTPacketReaderProtocolDHCP: return @"DHCP";
        case IJTPacketReaderProtocolNTPv4: return @"NTPv4";
        case IJTPacketReaderProtocolIPv6: return @"IPv6";
        case IJTPacketReaderProtocolOtherApplication: return @"Other application";
        case IJTPacketReaderProtocolIGMP: return @"IGMP";
        case IJTPacketReaderProtocolOtherTransport: return @"Other transport";
        case IJTPacketReaderProtocolEAPOL: return @"EAPOL";
        case IJTPacketReaderProtocolSNAP: return @"SNAP";
        case IJTPacketReaderProtocolICMPv6: return @"ICMPv6";
        case IJTPacketReaderProtocolEthernet: return @"Ethernet";
        case IJTPacketReaderProtocolNULL: return @"BSD loopback";
        case IJTPacketReaderProtocolUDPOverICMP: return @"UDP over ICMP";
        case IJTPacketReaderProtocolTCPOverICMP: return @"TCP over ICMP";
        case IJTPacketReaderProtocolIPv4OverIcmp: return @"IP over ICMP";
    }
    return @"N/A";
}

+ (NSString *)protocol2String: (IJTPacketReaderProtocol) proto {
    if(proto == IJTPacketReaderProtocolARPReply ||
       proto == IJTPacketReaderProtocolARPRequest ||
       proto == IJTPacketReaderProtocolARPOther)
        return @"ARP";
    else if(proto == IJTPacketReaderProtocolICMPEcho ||
            proto == IJTPacketReaderProtocolICMPEchoReply ||
            proto == IJTPacketReaderProtocolICMPOther ||
            proto == IJTPacketReaderProtocolICMPRedirect ||
            proto == IJTPacketReaderProtocolICMPTimexceed ||
            proto == IJTPacketReaderProtocolICMPUnreach)
        return @"ICMP";
    else
        return [IJTPacketReader protocol2DetailString:proto];
}

- (NSString *)getHexFormat {
    u_int8_t *content = self.packet.content;
    NSMutableString *dump = [[NSMutableString alloc] init];
    BOOL isipad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    
    int newline = 8;
    if (isipad)
        newline = 16;
    
    for(u_int16_t i = 0 ; i < _packet.header.caplen ; i++) {
        
        if(i > 0 && i % newline == 0)
            [dump appendString:@"\n"];
        else if(i > 0) {
            if(isipad && i % (newline/2) == 0)
                [dump appendString:@"|"];
            else
                [dump appendString:@" "];
        }
        
        [dump appendFormat:@"%02x", content[i]];
    }
    
    return dump;
}


- (NSString *)getASCIIFormat {
    u_int8_t *content = self.packet.content;
    NSMutableString *dump = [[NSMutableString alloc] init];
    BOOL isipad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? YES : NO;
    
    int newline = 16;
    if (isipad)
        newline = 32;
    
    for(u_int16_t i = 0 ; i < _packet.header.caplen ; i++) {
        
        if(i > 0 && i % newline == 0)
            [dump appendString:@"\n"];
        else if(i > 0) {
            if(isipad && i % (newline/2) == 0)
                [dump appendString:@"|"];
            else
                [dump appendString:@" "];
        }
        
        if(isgraph(content[i])) {
            [dump appendFormat:@"%c", content[i]];
        }
        else {
            [dump appendString:@"."];
        }
    }
    
    return dump;
}

- (NSInteger)getIpOptionLength {
    
    if(self.ipv4Header == NULL)
        return 0;
    
    int ip_hl = _ipv4Header->ip_hl << 2;
    
    return ip_hl - LIBNET_IPV4_H;
}

- (NSInteger)getTcpOptionLength {
    if(self.tcpHeader == NULL)
        return -1;
    
    int tcp_hl = _tcpHeader->th_off << 2;
    
    return tcp_hl - LIBNET_TCP_H;
}

+ (NSString *)protocol2PostString: (IJTPacketReaderProtocol) proto {
    switch (proto) {
        case IJTPacketReaderProtocolOtherNetwork: return @"Other network";
        case IJTPacketReaderProtocolARPReply: return @"ARP reply";
        case IJTPacketReaderProtocolARPRequest: return @"ARP request";
        case IJTPacketReaderProtocolARPOther: return @"ARP other";
        case IJTPacketReaderProtocolIPv4: return @"IPv4";
        case IJTPacketReaderProtocolICMPEcho: return @"ICMP echo";
        case IJTPacketReaderProtocolICMPEchoReply: return @"ICMP echo reply";
        case IJTPacketReaderProtocolICMPTimexceed: return @"ICMP timexceed";
        case IJTPacketReaderProtocolICMPRedirect: return @"ICMP redirect";
        case IJTPacketReaderProtocolICMPUnreach: return @"ICMP unreach";
        case IJTPacketReaderProtocolICMPOther: return @"ICMP other";
        case IJTPacketReaderProtocolICMPFragment: return @"ICMP fragmented";
        case IJTPacketReaderProtocolTCP: return @"TCP";
        case IJTPacketReaderProtocolTCPFragment: return @"TCP fragmented";
        case IJTPacketReaderProtocolUDP: return @"UDP";
        case IJTPacketReaderProtocolUDPFragment: return @"UDP fragmented";
        case IJTPacketReaderProtocolHTTP: return @"HTTP";
        case IJTPacketReaderProtocolHTTPS: return @"HTTPS";
        case IJTPacketReaderProtocolDNS: return @"DNS";
        case IJTPacketReaderProtocolMDNS: return @"MDNS";
        case IJTPacketReaderProtocolSSDP: return @"SSDP";
        case IJTPacketReaderProtocolSSH: return @"SSH";
        case IJTPacketReaderProtocolIMAP: return @"IMAP";
        case IJTPacketReaderProtocolIMAPS: return @"IMAPS";
        case IJTPacketReaderProtocolSMTP: return @"SMTP";
        case IJTPacketReaderProtocolWhois: return @"Whois";
        case IJTPacketReaderProtocolWOL: return @"WOL";
        case IJTPacketReaderProtocolDHCP: return @"DHCP";
        case IJTPacketReaderProtocolNTPv4: return @"NTPv4";
        case IJTPacketReaderProtocolIPv6: return @"IPv6";
        case IJTPacketReaderProtocolOtherApplication: return @"Other application";
        case IJTPacketReaderProtocolIGMP: return @"IGMP";
        case IJTPacketReaderProtocolOtherTransport: return @"Other transport";
        case IJTPacketReaderProtocolEAPOL: return @"EAPOL";
        case IJTPacketReaderProtocolSNAP: return @"SNAP";
        case IJTPacketReaderProtocolICMPv6: return @"ICMPv6";
        default: return @"";
    }
}

+ (NSArray *)protocolPostArray {
    NSMutableArray *reslut = [[NSMutableArray alloc] init];
    for(IJTPacketReaderProtocol protocol = IJTPacketReaderProtocolUnknown ; protocol < IJTPacketReaderProtocolNULL ; protocol++) {
        NSString *name = [IJTPacketReader protocol2PostString:protocol];
        if(name.length > 0)
           [reslut addObject:name];
    }
    return [NSArray arrayWithArray:reslut];
}

- (NSString *)ether_ntoa:(const struct ether_addr *)addr {
    return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", addr->octet[0], addr->octet[1], addr->octet[2], addr->octet[3], addr->octet[4], addr->octet[5]];
}

@end
