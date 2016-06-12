//
//  IJTValueChecker.m
//  Injector
//
//  Created by 聲華 陳 on 2015/7/1.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTValueChecker.h"
#import <arpa/inet.h>
#import <net/ethernet.h>
@implementation IJTValueChecker

+ (BOOL)checkIpv4Address: (NSString *)ipAddress {
    NSArray *array = [ipAddress componentsSeparatedByString:@"."];
    struct in_addr inaddr;
    if(array.count != 4)
        return NO;
    
    for(int i = 0 ; i < array.count ; i++) {
        NSString *string = array[i];
        if(string.length <= 0)
            return NO;
        NSScanner *scanner = [[NSScanner alloc] initWithString:string];
        int byte;
        [scanner scanInt:&byte];
        if(byte < 0 || byte > 256)
            return NO;
    }
    
    if(inet_pton(AF_INET, [ipAddress UTF8String], &inaddr) == -1)
        return NO;
    
    return YES;
}

+ (BOOL)checkIpv6Address: (NSString *)ipAddress {
    struct in6_addr inaddr;
    
    if(inet_pton(AF_INET6, [ipAddress UTF8String], &inaddr) == -1)
        return NO;
    return YES;
}

+ (BOOL)checkNetmask: (NSString *)netmask {
    NSArray *array = [netmask componentsSeparatedByString:@"."];
    struct in_addr inaddr;
    
    if(array.count != 4)
        return NO;
    
    //check mask
    int bytes[4] = {};
    for(int i = 0; i < array.count ; i++) {
        NSScanner *scanner = [[NSScanner alloc] initWithString:array[i]];
        [scanner scanInt:&bytes[i]];
        
        BOOL ok = NO;
        for(int j = 255, mask = 1 ; j >= 0 ;) {
            if(bytes[i] == j) {
                ok = YES;
                break;
            }
            j -= mask;
            mask *= 2;
        }
        if(ok == NO)
            return NO;
    }
    
    if(!(bytes[0] >= bytes[1] && bytes[1] >= bytes[2] && bytes[2] >= bytes[3]))
        return NO;
    
    if(inet_aton([netmask UTF8String], &inaddr) == 0)
        return NO;
    
    return YES;
}

+ (BOOL)checkPort: (NSString *)port {
    int portInt = [port intValue];
    
    if(portInt >= 0 && portInt <= 65535)
        return YES;
    else
        return NO;
}

+ (BOOL)checkPortWithRange: (NSString *)port {
    NSArray *array = [port componentsSeparatedByString:@"-"];
    if(array.count != 2)
        return NO;
    
    return [IJTValueChecker checkPort:array[0]] &&
    [IJTValueChecker checkPort:array[1]] ? YES : NO;
}

+ (BOOL)checkUint8: (NSString *)string {
    int number = [string intValue];
    
    if(number >= 0 && number <= UINT8_MAX)
        return YES;
    else
        return NO;
}

+ (BOOL)checkUint16: (NSString *)string {
    int number = [string intValue];
    
    if(number >= 0 && number <= UINT16_MAX)
        return YES;
    else
        return NO;
}

+ (BOOL)checkAllDigit: (NSString *)string {
    NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange r = [string rangeOfCharacterFromSet: nonNumbers];
    return r.location == NSNotFound;
}

+ (BOOL)checkMacAddress: (NSString *)macAddress {
    NSArray *array = [macAddress componentsSeparatedByString:@":"];
    struct ether_addr *addr = NULL;
    if(array.count != 6)
        return NO;
    
    NSScanner *scanner = nil;
    for(int i = 0; i < array.count ; i++) {
        scanner = [[NSScanner alloc] initWithString:array[i]];
        unsigned int byte;
        [scanner scanHexInt:&byte];
        if(byte > 256)
            return NO;
    }
    if(![scanner isAtEnd])
        return NO;
    
    addr = ether_aton([macAddress UTF8String]);
    
    return addr != NULL ? YES : NO;
}

+ (BOOL)checkSlash: (NSString *)slash {
    int slashInt = [slash intValue];
    
    if(slashInt >= 1 && slashInt <= 32)
        return YES;
    else
        return NO;
}

+ (BOOL)check2ByteHexString: (NSString *)type {
    if(type.length != 6)
        return NO;
    if(![type hasPrefix:@"0x"] && ![type hasPrefix:@"0X"])
        return NO;
    type = [type substringWithRange:NSMakeRange(2, 4)];
    
    NSString *allowString = @"1234567890abcdefABCDEF";
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[type componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [type isEqualToString:filtered];
}

+ (BOOL)check4ByteHexString: (NSString *)type {
    if(type.length != 10)
        return NO;
    if(![type hasPrefix:@"0x"] && ![type hasPrefix:@"0X"])
        return NO;
    type = [type substringWithRange:NSMakeRange(2, 8)];
    
    NSString *allowString = @"1234567890abcdefABCDEF";
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[type componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [type isEqualToString:filtered];
}

+ (BOOL)checkBit: (NSString *)bitString width: (int)width {
    if(bitString.length != width)
        return NO;
    NSString *allowString = @"01";
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[bitString componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [bitString isEqualToString:filtered];
}

+ (BOOL)checkURL: (NSString *)urlString {
    NSURL *candidateURL = [NSURL URLWithString:urlString];
    return candidateURL && candidateURL.scheme && candidateURL.host ? YES : NO;
}
@end
