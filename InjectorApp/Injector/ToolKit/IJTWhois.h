//
//  IJTWhois.h
//  IJTWhois
//
//  Created by 聲華 陳 on 2015/6/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IJTWhois : NSObject

@property (nonatomic) BOOL errorHappened;
@property (nonatomic) int errorCode;

- (id)init;
- (void)dealloc;
- (void)open;
- (void)close;

/**
 * whois callback function define
 * id self
 * SEL method
 * NSString * respone
 * NSString * server
 * id object
 */
typedef void (*WhoisCallback)(id, SEL, NSString *, NSString *, id);

#define WHOIS_CALLBACK_SEL @selector(whoisRespone:whoisServer:object:)

#define WHOIS_CALLBACK_METHOD \
    - (void)whoisRespone: (NSString *)respone \
    whoisServer: (NSString *)server \
    object: (id)object

typedef NS_ENUM(NSInteger, IJTWhoisServerList) {
    IJTWhoisServerListAbuse = 0, //"whois.abuse.net"
    IJTWhoisServerListNic, //"whois.crsnic.net"
    IJTWhoisServerListInic, //"whois.networksolutions.com"
    IJTWhoisServerListDnic, //"whois.nic.mil"
    IJTWhoisServerListGnic, //"whois.nic.gov"
    IJTWhoisServerListAnic, //"whois.arin.net"
    IJTWhoisServerListLnic, //"whois.lacnic.net"
    IJTWhoisServerListRnic, //"whois.ripe.net"
    IJTWhoisServerListPnic, //"whois.apnic.net"
    IJTWhoisServerListMnic, //"whois.ra.net"
    IJTWhoisServerListQnicTail, //".whois-servers.net"
    IJTWhoisServerListSnic, //"whois.6bone.net"
    IJTWhoisServerListBnic, //"whois.registro.br"
    IJTWhoisServerListNorid, //"whois.norid.no"
    IJTWhoisServerListIana, //"whois.iana.org"
    IJTWhoisServerListGermnic, //"de.whois-servers.net"
};

/**
 * 向whois server要資訊
 * @param whois 查詢目標
 * @param whoisServer whois server
 * @param timeout timeout
 * @return 成功傳回0, 發生error錯誤傳回-1, 發生h_error錯誤傳回-2, timeout傳回1
 */
- (int)whois: (NSString *)whoistarget
 whoisServer: (NSString *)server
     timeout: (u_int32_t)timeout
      target: (id)target
    selector: (SEL)selector
      object: (id)object;

/**
 * whois default list to hostname
 * @param listnumber IJTWhoisServerList only
 * @return hostname, 失敗傳回nil
 */
+ (NSString *)whoisServerList2String: (IJTWhoisServerList)listnumber;

/**
 * 取得whois server列表
 * @return server list array
 */
+ (NSArray *)whoisServerList;
@end
