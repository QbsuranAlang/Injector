//
//  IJTPacketTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/7/20.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTPacketTableViewController : IJTBaseViewController <UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSMutableArray *packetQueueArray;
- (void)loadCell;
- (void)startRecordType: (IJTPacketReaderType)type;
- (void)stopRecord;
@property (nonatomic) IJTPacketReaderType type;
- (void)changeType: (IJTPacketReaderType)type;

@end
