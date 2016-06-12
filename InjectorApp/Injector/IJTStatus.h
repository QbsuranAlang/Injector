//
//  IJTStatus.h
//  Injector
//
//  Created by 聲華 陳 on 2015/5/4.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, IJTStatusServer) {
    IJTStatusServerUndefined = 0,
    IJTStatusServerConnectFailR = 1,
    IJTStatusServerConnectFailRW = 2,
    IJTStatusServerQueryError = 3,
    IJTStatusServerEmptyTable = 4,
    IJTStatusServerDataExsit = 5,
    IJTStatusServerDataNotExsit = 6,
    IJTStatusServerDataEmpty = 7,
    IJTStatusServerIsLink = 8,
    IJTStatusServerNotLink = 9,
    IJTStatusServerFBSessionInvalid = 10,
    IJTStatusServerIsFacebookLogin = 11,
    IJTStatusServerIsGoogleLogin = 12,
    IJTStatusServerDataInvalid = 13,
    IJTStatusServerIsNotLogin = 14,
    IJTStatusServerProblemIPaddress = 15,
    IJTStatusServerNoProblemIPaddress = 16,
    IJTStatusServerNotSure = 17,
    IJTStatusServerCreateMaliceDatabaseFail = 18,
    IJTStatusServerUserTypeValid = 19,
    IJTStatusServerIP2CountryError = 20,
    IJTStatusServerWaiting = 21,
    IJTStatusServerSuccess = 99,
};

typedef NS_ENUM(NSInteger, IJTStatusUserType) {
    IJTStatusUserTypeFacebook = 1,
    IJTStatusUserTypeGoogle = 2,
    IJTStatusUserTypeBoth = 3
};

@interface IJTStatus : NSObject

@end
