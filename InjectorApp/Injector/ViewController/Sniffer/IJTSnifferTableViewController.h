//
//  IJTSnifferTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/2/27.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
#define IPHONE_ROW 4.
#define IPAD_ROW 5.
#define IPHONE_EXPAND 5.
#define IPAD_EXPAND 10.
#define COLLECTION_HEIGHT 1.1
@interface IJTSnifferTableViewController : IJTBaseViewController <UITableViewDataSource, UITableViewDelegate, PassValueDelegate, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource>

@property (nonatomic, weak) IBOutlet UILabel *pcapFilterLabel;
@property (nonatomic, weak) IBOutlet FUISwitch *promicsSwitch;
@property (weak, nonatomic) IBOutlet UIScrollView *flowGraphScrollView;
@property (weak, nonatomic) IBOutlet FUISegmentedControl *flowGraphTypeSegmentedCtl;
- (IBAction)flowGraphTypeSegmentedCtlValueChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UILabel *bytesLabel;
@property (weak, nonatomic) IBOutlet UILabel *byteFlowLabel;
@property (weak, nonatomic) IBOutlet UILabel *countFlowLabel;
@property (weak, nonatomic) IBOutlet UILabel *packetSizeLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *flowGraphUpperView;
@property (weak, nonatomic) IBOutlet UIView *packetQueueSizeView;
@property (weak, nonatomic) IBOutlet UIView *reloadIntervalView;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;

@end
