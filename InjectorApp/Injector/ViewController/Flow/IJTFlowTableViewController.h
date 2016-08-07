//
//  IJTSummaryTableViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/4/18.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJTBaseViewController.h"
@interface IJTFlowTableViewController : IJTBaseViewController <HSDatePickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, CZPickerViewDataSource, CZPickerViewDelegate, SSARefreshControlDelegate>

@property (weak, nonatomic) IBOutlet UIView *pieView;
@property (weak, nonatomic) IBOutlet FUISegmentedControl *pieViewSegemtedControl;
- (IBAction)pieViewSegmenteValueChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *startDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *endDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet FUIButton *resetDateButton;
@property (weak, nonatomic) IBOutlet FUIButton *allTheTimeButton;

@property (weak, nonatomic) IBOutlet UILabel *wifiBytesLabel;
@property (weak, nonatomic) IBOutlet UILabel *wifiCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *wifiAverageLabel;
@property (weak, nonatomic) IBOutlet UILabel *wifiBytesFlowLabel;
@property (weak, nonatomic) IBOutlet UILabel *wifiCountFlowLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellBytesLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellAverageLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellBytesFlowLabel;
@property (weak, nonatomic) IBOutlet UILabel *cellCountFlowLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *wifiPacketCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *cellPacketCollectionView;
@property (weak, nonatomic) IBOutlet UILabel *detectTimesLabel;

- (IBAction)resetDate:(id)sender;
- (IBAction)setAllTheDate:(id)sender;
- (IBAction)flushFlowData:(id)sender;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;


@end
