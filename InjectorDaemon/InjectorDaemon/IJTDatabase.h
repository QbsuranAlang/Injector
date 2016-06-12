//
//  IJTDatabase.h
//  InjectorDaemon
//
//  Created by 聲華 陳 on 2015/4/15.
//
//

#import <Foundation/Foundation.h>

#define UPDATE_INTERVAL 60*60*24 //1 day
@interface IJTDatabase : NSObject

@property (nonatomic, strong) NSTimer *updateTimer;
- (id) init;
- (void) retrieve;
+ (NSArray *) getdatabase;

@end
