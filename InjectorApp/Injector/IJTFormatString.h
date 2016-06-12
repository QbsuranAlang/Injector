//
//  IJTFormatString.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/8.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JKBigInteger.h>
@interface IJTFormatString : NSObject

+ (NSString *) formatDate: (NSDate *)date;
+ (NSString *) formatLANScanDate: (NSDate *)date;
+ (NSString *) subtractStartDate: (NSDate *)start endDate: (NSDate *)end;
+ (NSString *) formatTime: (time_t)time;
+ (NSString *) formatDuration: (time_t)start end: (time_t)end;
+ (NSString *) formatCount: (u_int64_t) count;
+ (NSString *) formatBigCount: (JKBigInteger *) count;
+ (NSString *) formatBytes: (u_int64_t) bytes carry: (BOOL)carry;
+ (NSString *) formatBigBytes: (JKBigInteger *) bytes;
+ (NSString *) formatFlowBytes: (u_int64_t)bytes startDate: (NSDate *)start endDate: (NSDate *)end;
+ (NSString *) formatBigFlowBytes: (JKBigInteger *)bytes startDate: (NSDate *)start endDate: (NSDate *)end;
+ (NSString *) formatFlowCount: (u_int64_t)count startDate: (NSDate *)start endDate: (NSDate *)end;
+ (NSString *) formatBigFlowCount: (JKBigInteger *)count startDate: (NSDate *)start endDate: (NSDate *)end;
+ (NSString *) formatLabelOnXAxisForDate: (NSDate *)date;
+ (NSString *) formatPacketAverageBytes :(u_int64_t) bytes count: (u_int64_t)count;
+ (NSString *) formatBigPacketAverageBytes :(JKBigInteger *) bytes count: (JKBigInteger *)count;
+ (NSString *) formatExpire :(int32_t)expire;
+ (NSString *) formatDetectedDate: (NSString *)time;
+ (NSString *) formatTimestamp: (struct timeval)tv secondsPadding: (int)secondsPadding decimalPoint: (int)decimalPoint;
+ (NSString *) formatTimestampWithWholeInfo:(struct timeval)tv decimalPoint:(int)decimalPoint;
+ (NSString *) formatIntegerToBinary: (NSInteger)integer width: (int)width;
+ (NSNumber *) formatBinaryToInteger: (NSString *)binaryString;

//packet
+ (NSString *)formatEthernetType2String: (u_int16_t)ethertype;
+ (NSString *)formatNullType2String: (u_int32_t)nulltype;
+ (NSString *)formatIpTypeOfSerivce: (u_int8_t)tos;
+ (NSString *)formatIpFlags: (u_int16_t)flags;
+ (NSString *)formatIpProtocol: (u_int8_t)protocol;
+ (NSString *)formatIcmpType: (u_int8_t)type;
+ (NSString *)formatIcmpCode: (u_int8_t)code type: (u_int8_t)type;
+ (NSString *)formatArpOpcode: (u_int16_t)opcode;
+ (NSString *)formatChecksum: (u_int16_t)checksum;
+ (NSString *)formatIpAddress: (void *)in_addr family: (sa_family_t)family;
+ (NSString *)formatTcpFlags: (u_int8_t)flags;
+ (NSString *)formatByteStream: (u_int8_t *)stream length: (int)length;
+ (NSString *)formatTrafficClass: (u_int8_t *)flags length: (int)length;
+ (NSString *)formatFlowLabel: (u_int8_t *)flags length: (int)length;
+ (NSString *)portName: (u_int16_t)port protocol: (NSString *)protocol;

@end
