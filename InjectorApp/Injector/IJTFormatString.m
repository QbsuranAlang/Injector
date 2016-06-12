//
//  IJTFormatString.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/8.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTFormatString.h"
#import <math.h>
#import <net/bpf.h>
#import <netinet/ip.h>
#import <libnet.h>
#define COUNT_TOKEN @[@"",@"K",@"M",@"G",@"T", @"P", @"E"]
#define BYTES_TOKEN @[@"bytes",@"KB",@"MB",@"GB",@"TB", @"PB", @"EB"]
#define ONE024 [[JKBigInteger alloc] initWithString:@"1024"]
#define TWO_GB [[[ONE024 multiply:ONE024] multiply:ONE024] multiply:[[JKBigInteger alloc] initWithString:@"2"]]
#define ONE000 [[JKBigInteger alloc] initWithString:@"1000"]
#define TWO_G [[[ONE000 multiply:ONE000] multiply:ONE000] multiply:[[JKBigInteger alloc] initWithString:@"2"]]
@implementation IJTFormatString

+ (NSString *) formatDate: (NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"aa hh:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *) formatLANScanDate: (NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"MM/dd, HH:mm"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *) subtractStartDate: (NSDate *)start endDate: (NSDate *)end
{
    NSTimeInterval diff = [end timeIntervalSinceDate:start];
    NSInteger ti = (NSInteger)diff;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ldh %02ldm %02lds",
            (long)hours, (long)minutes, (long)seconds];
}

+ (NSString *) formatTime: (time_t)time
{
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:time];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"y/MM/dd HH:mm"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *) formatDuration: (time_t)start end: (time_t)end
{
    NSTimeInterval diff = labs(end - start);
    NSInteger ti = (NSInteger)diff;
    
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600) % 24;
    NSInteger days = (ti / 86400) % 30;
    NSInteger months = (ti / 2592000);
    
    if(months == 0 && days == 0 && hours == 0 && minutes == 0)
        return [NSString stringWithFormat:@"%0m"];
    if(months == 0 && days == 0 && hours == 0)
        return [NSString stringWithFormat:@"%02ldm", (long)minutes];
    if(months == 0 && days == 0)
        return [NSString stringWithFormat:@"%02ldh %02ldm", (long)hours, (long)minutes];
    if(months == 0)
        return [NSString stringWithFormat:@"%02ldd %02ldh %02ldm", (long)days, (long)hours, (long)minutes];
    return [NSString stringWithFormat:@"%2ldM %02ldd %02ldh %02ldm",
            (long)months, (long)days, (long)hours, (long)minutes];
}

+ (NSString *) formatCount: (u_int64_t) count
{
    double convertedValue = count;
    int multiplyFactor = 0;
    NSArray *tokens = COUNT_TOKEN;
    
    while (convertedValue/1000 > 1000) {
        convertedValue /= 1000;
        multiplyFactor++;
    }
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *numberAsString = [numberFormatter stringFromNumber:@(convertedValue)];
    return [NSString stringWithFormat:@"%@ %@", numberAsString, tokens[multiplyFactor]];
}

+ (NSString *) formatBigCount: (JKBigInteger *) count
{
    NSArray *tokens = COUNT_TOKEN;
    int multiplyFactor = 0;
    
    while([count compare:TWO_G] == NSOrderedDescending) {//equal byte > two_gb
        count = [count divide:ONE000];
        multiplyFactor++;
    }
    
    double convertedValue = [count unsignedIntValue];
    while (convertedValue/1000 > 1000) {
        convertedValue /= 1000;
        multiplyFactor++;
    }
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *numberAsString = [numberFormatter stringFromNumber:@(convertedValue)];
    return [NSString stringWithFormat:@"%@ %@", numberAsString, tokens[multiplyFactor]];
}

+ (NSString *) formatBytes: (u_int64_t) bytes carry: (BOOL)carry
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    if(carry) {
        
        return [NSByteCountFormatter stringFromByteCount:bytes countStyle:NSByteCountFormatterCountStyleDecimal];
    }
    else {
        return [NSString stringWithFormat:@"%@ %@", [numberFormatter stringFromNumber:@(bytes)],
                bytes == 0 ? @"Byte" : @"Bytes"];
    }
}

+ (NSString *) formatBigBytes: (JKBigInteger *) bytes
{
    if([[bytes stringValue] isEqualToString:@"0"])
        return @"Zero KB";
    
    NSArray *tokens = BYTES_TOKEN;
    int multiplyFactor = 0;
    
    while([bytes compare:TWO_GB] == NSOrderedDescending) {//equal byte > two_gb
        bytes = [bytes divide:ONE024];
        multiplyFactor++;
    }
    
    double convertedValue = [bytes unsignedIntValue];
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    return [NSString stringWithFormat:@"%.2f %@", convertedValue, tokens[multiplyFactor]];
}

+ (NSString *) formatFlowBytes: (u_int64_t) bytes startDate: (NSDate *)start endDate: (NSDate *)end
{
    NSTimeInterval timeinterval = [end timeIntervalSinceDate:start];
    if(timeinterval <= 0)
        return @"Zero KB/s";
    long double flow = bytes /timeinterval;
    
    return [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:flow countStyle:NSByteCountFormatterCountStyleDecimal]];
}

+ (NSString *) formatBigFlowBytes: (JKBigInteger *)bytes startDate: (NSDate *)start endDate: (NSDate *)end{
    NSTimeInterval timeinterval = [end timeIntervalSinceDate:start];
    if(timeinterval <= 0 || [[bytes stringValue] isEqualToString:@"0"])
        return @"Zero KB/s";

    JKBigInteger *bigtimeinterval = [[JKBigInteger alloc] initWithUnsignedLong:timeinterval];
    
    if([bytes compare:TWO_GB] == NSOrderedDescending) {//equal byte > two_gb
        bytes = [bytes divide:bigtimeinterval];
        return [NSString stringWithFormat:@"%@/s", [IJTFormatString formatBigBytes:bytes]];
    }
    else
        return [IJTFormatString formatFlowBytes:[bytes unsignedIntValue] startDate:start endDate:end];
}

+ (NSString *) formatFlowCount: (u_int64_t) count startDate: (NSDate *)start endDate: (NSDate *)end
{
    NSTimeInterval timeinterval = [end timeIntervalSinceDate:start];
    if(timeinterval <= 0)
        return @"Zero";
    long double flow = count /timeinterval;
    if(isnan(flow))
        flow = 0;
    double convertedValue = flow;
    int multiplyFactor = 0;
    NSArray *tokens = @[@"",@"K",@"M",@"G",@"T"];
    
    while (convertedValue/1000 > 1000) {
        convertedValue /= 1000;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%.2f %@/s",convertedValue, tokens[multiplyFactor]];
}

+ (NSString *) formatBigFlowCount: (JKBigInteger *)count startDate: (NSDate *)start endDate: (NSDate *)end
{
    NSTimeInterval timeinterval = [end timeIntervalSinceDate:start];
    if(timeinterval <= 0 || [[count stringValue] isEqualToString:@"0"])
        return @"0.00 /s";
    
    JKBigInteger *bigtimeinterval = [[JKBigInteger alloc] initWithUnsignedLong:timeinterval];
    
    if([count compare:TWO_G] == NSOrderedDescending) {//equal byte > two_gb
        count = [count divide:bigtimeinterval];
        return [NSString stringWithFormat:@"%@/s", [IJTFormatString formatBigCount:count]];
    }
    else
        return [IJTFormatString formatFlowCount:[count unsignedIntValue] startDate:start endDate:end];
}

+ (NSString *) formatLabelOnXAxisForDate: (NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *) formatPacketAverageBytes :(u_int64_t) bytes count: (u_int64_t)count
{
    if(count == 0)
        return @"Zero KB";
    
    long double flow = bytes /(long double)count;

    double convertedValue = flow;
    int multiplyFactor = 0;
    NSArray *tokens = @[@"bytes",@"KB",@"MB",@"GB",@"TB"];
    
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%.2f %@",convertedValue, tokens[multiplyFactor]];
}

+ (NSString *) formatBigPacketAverageBytes :(JKBigInteger *)bytes count: (JKBigInteger *)count
{
    if([[count stringValue] isEqualToString:@"0"])
        return @"Zero KB";
    
    NSArray *tokens = BYTES_TOKEN;
    int multiplyFactor = 0;
    JKBigInteger *ten = [[JKBigInteger alloc] initWithString:@"10"];
    
    //scale
    while([bytes compare:TWO_GB] == NSOrderedDescending || [count compare:TWO_G] == NSOrderedDescending) {//equal byte > two_gb
        bytes = [bytes divide:ten];
        count = [count divide:ten];
    }
    
    double convertedValue = [bytes unsignedIntValue]/(double)[count unsignedIntValue];
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    return [NSString stringWithFormat:@"%.2f %@", convertedValue, tokens[multiplyFactor]];
}

+ (NSString *) formatExpire :(int32_t)expire {
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:expire];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"aa hh:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *) formatDetectedDate: (NSString *)time
{
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:[time longLongValue]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"y/MM/dd aa hh:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *) formatTimestamp: (struct timeval)tv secondsPadding: (int)secondsPadding decimalPoint: (int)decimalPoint {
    time_t time = tv.tv_sec;
    struct tm *tm = localtime(&time);
    char tmbuf[64];
    
    strftime(tmbuf, sizeof tmbuf, "%H:%M:", tm);
    return [NSString stringWithFormat:@"%s%0*.*f",
            tmbuf, decimalPoint + secondsPadding, decimalPoint,
            tv.tv_usec/1000./1000. + tm->tm_sec];
}


+ (NSString *)formatTimestampWithWholeInfo:(struct timeval)tv decimalPoint:(int)decimalPoint {
    NSString *date = [IJTFormatString formatTime:tv.tv_sec];
    NSString *time = [IJTFormatString formatTimestamp:tv secondsPadding:3 decimalPoint:decimalPoint];
    
    return [NSString stringWithFormat:@"%@ %@", date, time];
}

+ (NSString *) formatIntegerToBinary: (NSInteger)integer width: (int)width {
    NSMutableString * string = [[NSMutableString alloc] init];
    
    int spacing = pow( 2, 3 );
    int binaryDigit = 0;
    
    while( binaryDigit < width )
    {
        binaryDigit++;
        
        [string insertString:( (integer & 1) ? @"1" : @"0" )atIndex:0];
        
        if( binaryDigit % spacing == 0 && binaryDigit != width )
        {
            [string insertString:@" " atIndex:0];
        }
        
        integer = integer >> 1;
    }
    
    return string;
}

+ (NSNumber *) formatBinaryToInteger: (NSString *)binaryString {
    NSUInteger totalValue = 0;
    for (int i = 0; i < binaryString.length; i++) {
        totalValue += (int)([binaryString characterAtIndex:(binaryString.length - 1 - i)] - 48) * pow(2, i);
    }
    return @(totalValue);
}

/*from wireshark aftypes.h*/
#define BSD_AF_INET		2
#define BSD_AF_INET6_BSD	24	/* OpenBSD (and probably NetBSD), BSD/OS */
#define BSD_AF_INET6_FREEBSD	28
#define BSD_AF_INET6_DARWIN	30

#define ETHERTYPE_WOL 0x0842
#define ETHERTYPE_EAPOL 0x888e
+ (NSString *)formatEthernetType2String: (u_int16_t)ethertype {
    NSString *result = @"";
    switch (ntohs(ethertype)) {
        case ETHERTYPE_ARP: result = @"ARP"; break;
        case ETHERTYPE_IP: result = @"IPv4"; break;
        case ETHERTYPE_IPV6: result = @"IPv6"; break;
        case ETHERTYPE_REVARP: result = @"RARP"; break;
        case ETHERTYPE_WOL: result = @"Wake on Lan"; break;
        case ETHERTYPE_EAPOL: result = @"EAPOL"; break;
        case ETHERTYPE_LOOPBACK: result = @"Loopback"; break;
        default: result = @"Unknown"; break;
    }
    return [NSString stringWithFormat:@"%@(%#06x)", result, ntohs(ethertype)];
}

+ (NSString *)formatNullType2String: (u_int32_t)nulltype {
    NSString *result = @"";
    switch (nulltype) {
        case BSD_AF_INET:
            result = @"IPv4";
            break;
        case BSD_AF_INET6_BSD:
        case BSD_AF_INET6_FREEBSD:
        case BSD_AF_INET6_DARWIN:
            result = @"IPv6";
            break;
        default:
            result = @"Unknown";
            break;
    }
    return [NSString stringWithFormat:@"%@(%u)", result, nulltype];
}

+ (NSString *)formatIpTypeOfSerivce: (u_int8_t)tos {
    int f[] = {'1', '1', '1', 'D', 'T', 'R', 'C', 'X'};
#define TOS_MAX (sizeof(f)/sizeof(f[0]))
    char str[TOS_MAX + 1]; //return buffer
    u_int32_t mask = 0x80; //mask
    int i;
    
    for(i = 0 ; i < TOS_MAX ; i++) {
        if((tos << i) & mask)
            str[i] = f[i];
        else
            str[i] = '-';
    }//end for
    str[i] = 0;
    
    if(tos == 0)
        return @"0x00";
    
    return [NSString stringWithFormat:@"%#04x(%s)", tos, str];
}

+ (NSString *)formatIpFlags: (u_int16_t)flags {
    u_int16_t f[] = {IP_RF, IP_DF, IP_MF}; //flag
#define IP_FLG_MAX (sizeof(f)/sizeof(f[0]))
    int i;
    NSString *flagsString = @"";
    NSArray *flagsArray = @[@"R", @"D", @"M"];
    u_int16_t flag = 0;
    flags = ntohs(flags);
    
    for(i = 0 ; i < IP_FLG_MAX ; i++)
    {
        if(f[i] & flags) {
            flag |= f[i];
            flagsString = [flagsString stringByAppendingString:[NSString stringWithFormat:@"%@", flagsArray[i]]];
        }
        else {
            flagsString = [flagsString stringByAppendingString:@"-"];
        }
    }//end for
    
    if(flag == 0)
        return @"0x00";
    else {
        return [NSString stringWithFormat:@"%#04x(%@)", flag, flagsString];
    }
}


+ (NSString *)formatIpProtocol: (u_int8_t)protocol {
    NSString *result = @"";
    switch (protocol) {
        case IPPROTO_IP: result = @"IP"; break;
        case IPPROTO_ICMP: result = @"ICMP"; break;
        case IPPROTO_UDP: result = @"UDP"; break;
        case IPPROTO_TCP: result = @"TCP"; break;
        case IPPROTO_IGMP: result = @"IGMP"; break;
        case IPPROTO_OSPFIGP: result = @"OSPF"; break;
        case IPPROTO_RAW: result = @"IP Raw"; break;
        case IPPROTO_ICMPV6: result = @"ICMPv6"; break;
        case IPPROTO_IPV4: result = @"IPv4 Encapsulation"; break;
        case IPPROTO_IPV6: result = @"IPv6"; break;
            
        default: result = @"Unknown"; break;
    }
    return [NSString stringWithFormat:@"%@(%d)", result, protocol];
}

+ (NSString *)formatChecksum: (u_int16_t)checksum {
    if(checksum == 0)
        return @"0x0000";
    return [NSString stringWithFormat:@"%#06x", ntohs(checksum)];
}

+ (NSString *)formatIcmpType: (u_int8_t)type {
    switch (type) {
        case ICMP_ECHO: return @"Echo Request";
        case ICMP_ECHOREPLY: return @"Echo Reply";
        case ICMP_UNREACH: return @"Destination Unreachable";
        case ICMP_SOURCEQUENCH: return @"Source Quench";
        case ICMP_REDIRECT: return @"Redirect";
        case ICMP_TIMXCEED: return @"Time to live exceeded";
        case ICMP_PARAMPROB: return @"Parameter Problem";
        case ICMP_TSTAMP: return @"Timestamp";
        case ICMP_TSTAMPREPLY: return @"Timestamp Reply";
        case ICMP_IREQ: return @"Information Request";
        case ICMP_IREQREPLY: return @"Information Reply";
        case ICMP_MASKREQ: return @"Address Mask Request";
        case ICMP_MASKREPLY: return @"Address Mask Reply";
        case ICMP_ROUTERADVERT: return @"Router Advertisement";
        case ICMP_ROUTERSOLICIT: return @"Router Solicitation";
        default: return @"Bad ICMP Type";
    }
}

+ (NSString *)formatIcmpCode: (u_int8_t)code type: (u_int8_t)type {
    switch (type) {
        case ICMP_UNREACH:
            switch(code) {
                case ICMP_UNREACH_NET: return @"Destination Net Unreachable";
                case ICMP_UNREACH_HOST: return @"Destination Host Unreachable";
                case ICMP_UNREACH_PROTOCOL: return @"Destination Protocol Unreachable";
                case ICMP_UNREACH_PORT: return @"Destination Port Unreachable";
                case ICMP_UNREACH_NEEDFRAG: return @"frag needed and DF set (MTU %d)";
                case ICMP_UNREACH_SRCFAIL: return @"Source Route Failed";
                case ICMP_UNREACH_FILTER_PROHIB: return @"Communication prohibited by filter";
                default: return @"Dest Unreachable, Bad Code";
            }
            break;
        case ICMP_REDIRECT:
            switch(code) {
                case ICMP_REDIRECT_NET: return @"Redirect Network";
                case ICMP_REDIRECT_HOST: return @"Redirect Host";
                case ICMP_REDIRECT_TOSNET: return @"Redirect Type of Service and Network";
                case ICMP_REDIRECT_TOSHOST: return @"Redirect Type of Service and Host";
                default: return @"Redirect, Bad Code";
            }
            break;
        case ICMP_TIMXCEED:
            switch(code) {
                case ICMP_TIMXCEED_INTRANS: return @"Time to live exceeded";
                case ICMP_TIMXCEED_REASS: return @"Frag reassembly time exceeded";
                default: return @"Time exceeded, Bad Code";
            }
            break;
            
        default: return [IJTFormatString formatIcmpType:type];
    }
}

+ (NSString *)formatIpAddress: (void *)in_addr family: (sa_family_t)family {
    char ntop_buf[256];
    inet_ntop(family, in_addr, ntop_buf, sizeof(ntop_buf));
    return [NSString stringWithUTF8String:ntop_buf];
}

+ (NSString *)formatArpOpcode: (u_int16_t)opcode {
    NSString *result = @"";
    switch (ntohs(opcode)) {
        case ARPOP_REPLY: result = @"Reply"; break;
        case ARPOP_REQUEST: result = @"Request"; break;
        case ARPOP_REVREPLY: result = @"Reverse Reply"; break;
        case ARPOP_REVREQUEST: result = @"Reverse Request"; break;
        default: result = @"Unknown"; break;
    }
    return [NSString stringWithFormat:@"%@(%d)", result, ntohs(opcode)];
}

+ (NSString *)formatTcpFlags: (u_int8_t)flags {
    int  f[] = {'W', 'E', 'U', 'A', 'P', 'R', 'S', 'F'};
#define TCP_FLG_MAX (sizeof f / sizeof f[0])
    char str[TCP_FLG_MAX + 1];
    unsigned int mask = 1 << (TCP_FLG_MAX - 1);
    int i;
    
    for (i = 0; i < TCP_FLG_MAX; i++) {
        if (((flags << i) & mask) != 0)
            str[i] = f[i];
        else
            str[i] = '-';
    }
    str[i] = '\0';
    
    if(flags == 0)
        return @"0x00";
    else
        return [NSString stringWithFormat:@"%#04x(%s)", flags, str];
}

+ (NSString *)formatByteStream: (u_int8_t *)stream length: (int)length {
    NSString *reslut = @"";
    for(int i = 0 ; i < length ; i++) {
        reslut = [reslut stringByAppendingString:[NSString stringWithFormat:@"%x", stream[i]]];
    }
    return reslut;
}

+ (NSString *)formatTrafficClass: (u_int8_t *)flags length: (int)length {
    if(length < 2)
        return @"N/A";
    u_int8_t flag = ((flags[0] & 0x0f) << 4) | ((flags[1] & 0xf0) >> 4);
    
    if(flag == 0)
        return @"0x00";
    else
        return [NSString stringWithFormat:@"%#04x", flag];
}

+ (NSString *)formatFlowLabel: (u_int8_t *)flags length: (int)length {
    if(length < 4)
        return @"N/A";
    u_int32_t flag = ((flags[1] & 0x0f) << 16) | (flags[2] << 8) | flags[3];
    
    if(flag == 0)
        return @"0x00000000";
    else
        return [NSString stringWithFormat:@"%#010x", flag];
}

+ (NSString *)portName: (u_int16_t)port protocol: (NSString *)protocol {
    struct servent *se; //server information
    se = getservbyport(htons(port), [protocol UTF8String]);
    NSString *name = [NSString stringWithUTF8String:se ? se->s_name : "unknown"];
    return name;
}
@end
