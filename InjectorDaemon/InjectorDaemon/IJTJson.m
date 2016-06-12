//
//  IJTJson.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/12.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTJson.h"

@implementation IJTJson

+ (NSDictionary *)file2dictionary :(NSString *)filename
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filename];
    NSData *data = [fileHandle readDataToEndOfFile];
    return [self json2dictionary:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
}

+ (NSDictionary *)json2dictionary: (NSString *)json
{
    NSDictionary *dict = nil;
    
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    dict = [NSJSONSerialization JSONObjectWithData:data
                                           options:kNilOptions
                                             error:&error];
    if(error)
        return nil;
    return dict;
}

+ (NSString *)dictionary2sting: (NSDictionary *)dictionary prettyPrint: (BOOL)prettyPrint
{
    NSError *error = nil;
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:(NSJSONWritingOptions)    (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    
    if(jsondata)
        return [[NSString alloc] initWithData:jsondata encoding:NSUTF8StringEncoding];
    else
        return nil;
}

+ (NSString *)array2string: (NSArray *)array {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
    
    if(error)
        return nil;
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (NSArray *)json2array: (NSString *)json {
    NSError *error = nil;
    NSArray *jsonObject =
    [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:0 error:&error];
    
    if(error)
        return nil;
    return jsonObject;
}
@end
