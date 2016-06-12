//
//  IJTPacketReader.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pcap.h>
#import "IJTPacketQueue.h"
#import <libnet.h>
#import <net/ethernet.h>
typedef NS_ENUM(NSInteger, IJTPacketReaderType) {
    IJTPacketReaderTypeWiFi = 0,
    IJTPacketReaderTypeCellular
};

typedef NS_ENUM(NSInteger, IJTPacketReaderProtocol) {
    IJTPacketReaderProtocolUnknown = 0,
    IJTPacketReaderProtocolARPReply,
    IJTPacketReaderProtocolARPRequest,
    IJTPacketReaderProtocolARPOther,
    IJTPacketReaderProtocolSNAP,
    IJTPacketReaderProtocolEAPOL,
    IJTPacketReaderProtocolIPv4,
    IJTPacketReaderProtocolIPv4OverIcmp,
    IJTPacketReaderProtocolIPv6,
    IJTPacketReaderProtocolOtherNetwork,
    IJTPacketReaderProtocolTCP,
    IJTPacketReaderProtocolTCPFragment, /**/
    IJTPacketReaderProtocolTCPOverICMP,
    IJTPacketReaderProtocolUDP,
    IJTPacketReaderProtocolUDPFragment, /**/
    IJTPacketReaderProtocolUDPOverICMP,
    IJTPacketReaderProtocolICMPEcho,
    IJTPacketReaderProtocolICMPEchoReply,
    IJTPacketReaderProtocolICMPTimexceed,
    IJTPacketReaderProtocolICMPRedirect,
    IJTPacketReaderProtocolICMPUnreach,
    IJTPacketReaderProtocolICMPOther,
    IJTPacketReaderProtocolICMPFragment, /**/
    IJTPacketReaderProtocolIGMP,
    IJTPacketReaderProtocolICMPv6,
    IJTPacketReaderProtocolOtherTransport,
    IJTPacketReaderProtocolHTTP,
    IJTPacketReaderProtocolHTTPS,
    IJTPacketReaderProtocolDNS,
    IJTPacketReaderProtocolMDNS,
    IJTPacketReaderProtocolSSDP,
    IJTPacketReaderProtocolSSH,
    IJTPacketReaderProtocolIMAP,
    IJTPacketReaderProtocolIMAPS,
    IJTPacketReaderProtocolSMTP,
    //IJTPacketReaderProtocolPOP3,
    IJTPacketReaderProtocolDHCP,
    IJTPacketReaderProtocolWhois,
    IJTPacketReaderProtocolWOL,
    IJTPacketReaderProtocolNTPv4,
    IJTPacketReaderProtocolOtherApplication,
    //IJTPacketReaderProtocolLoopback,
    IJTPacketReaderProtocolEthernet,
    IJTPacketReaderProtocolNULL
};

struct bsd_null_hdr {
    u_int32_t null_type;
};

#define BSD_NULL_LEN 4

#define PACK( __Declaration__ ) __Declaration__ __attribute__((__packed__))
PACK(
     struct arp_header
{
    uint16_t ar_hrd; /* format of hardware address */
    uint16_t ar_pro;         /* format of protocol address */
    uint8_t  ar_hln;         /* length of hardware address */
    uint8_t  ar_pln;         /* length of protocol addres */
    uint16_t ar_op;          /* operation type */
    struct ether_addr ar_sha; //source mac address
    struct in_addr ar_spa; //source IP
    struct ether_addr ar_tha; //destination mac address
    struct in_addr ar_tpa; //destination IP
    });

PACK(
     struct wol_header {
         u_int8_t wol_sync_stream[6];
         struct ether_addr wol_ether_addr[16];
         u_int8_t wol_password[6]; //only in layer 2
     });
@interface IJTPacketReader : NSObject


@property (nonatomic) IJTPacketReaderType dataLinkData;
@property (nonatomic, strong) NSString *sourceIPAddress;
@property (nonatomic, strong) NSString *destinationIPAddress;
@property (nonatomic, strong) NSString *sourceMacAddress;
@property (nonatomic, strong) NSString *destinationMacAddress;
@property (nonatomic) IJTPacketReaderProtocol finalProtocolType;
@property (nonatomic) IJTPacketReaderProtocol layer1Type;
@property (nonatomic) NSInteger layer1StartPosition;
@property (nonatomic) IJTPacketReaderProtocol layer2Type;
@property (nonatomic) NSInteger layer2StartPosition;
@property (nonatomic) IJTPacketReaderProtocol layer3Type;
@property (nonatomic) NSInteger layer3StartPosition;
@property (nonatomic) IJTPacketReaderProtocol layer4Type;
@property (nonatomic) NSInteger layer4StartPosition;
@property (nonatomic) IJTPacketReaderProtocol icmpLayer1Type;
@property (nonatomic) NSInteger icmpLayer1StartPosition;
@property (nonatomic) IJTPacketReaderProtocol icmpLayer2Type;
@property (nonatomic) NSInteger icmpLayer2StartPosition;
//@property (nonatomic) IJTPacketReaderProtocol icmpLayer3Type;
//@property (nonatomic) NSInteger icmpLayer3StartPosition;
@property (nonatomic) u_int8_t ip_ttl;
@property (nonatomic) u_int8_t ip_portocol;
@property (nonatomic) u_int16_t icmp_ID;
@property (nonatomic) u_int16_t icmp_Seq;
@property (nonatomic) u_int16_t sourcePort;
@property (nonatomic) u_int16_t destinationPort;
@property (nonatomic) struct timeval timestamp;
@property (nonatomic) u_int32_t captureLengh;
@property (nonatomic) u_int32_t frameLengh;
@property (nonatomic) NSUInteger index;


//headers
@property (nonatomic) struct libnet_ethernet_hdr *ethernetHeader;
@property (nonatomic) struct bsd_null_hdr *bsdNullHeader;
@property (nonatomic) struct libnet_ipv4_hdr *ipv4Header;
@property (nonatomic) struct libnet_ipv4_hdr *ipv4OverIcmpHeader;
@property (nonatomic) struct libnet_icmpv4_hdr *icmpv4Header;
@property (nonatomic) struct arp_header *arpHeader;
@property (nonatomic) struct libnet_tcp_hdr *tcpHeader;
@property (nonatomic) struct libnet_udp_hdr *udpHeader;
@property (nonatomic) struct libnet_tcp_hdr *tcpOverIcmpHeader;
@property (nonatomic) struct libnet_udp_hdr *udpOverIcmpHeader;
@property (nonatomic) struct wol_header *wolHeader;
@property (nonatomic) struct libnet_ipv6_hdr *ipv6Header;
@property (nonatomic) struct libnet_icmpv6_hdr *icmpv6Header;
@property (nonatomic) struct libnet_igmp_hdr *igmpHeader;


- (id)initWithPacket: (packet_t)packet
                type: (IJTPacketReaderType)type
               index: (NSUInteger)index;
- (NSString *)getHexFormat;
- (NSString *)getASCIIFormat;
- (NSInteger)getIpOptionLength;
- (NSInteger)getTcpOptionLength;


+ (NSString *)protocol2DetailString: (IJTPacketReaderProtocol) proto;
+ (NSString *)protocol2String: (IJTPacketReaderProtocol) proto;
/**
 * protocol 2 post field
 */
+ (NSString *)protocol2PostString: (IJTPacketReaderProtocol) proto;
/**
 * all support protocol
 */
+ (NSArray *)protocolPostArray;



@end








