//
//  IJTSummaryTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/4/18.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTFlowTableViewController.h"
#import "IJTSnifferTableViewController.h"
#import "IJTDetectEventTableViewController.h"
#define TIME_OFFSET 3600*24

@interface IJTFlowTableViewController ()

@property (nonatomic, strong) NSString *serialNumber;
@property (nonatomic, strong) NSDictionary *wifipacketFlow;
@property (nonatomic, strong) NSDictionary *cellpacketFlow;
@property (nonatomic, strong) PNPieChart *pieChartView;
@property (nonatomic) time_t startTime;
@property (nonatomic) time_t endTime;
@property (nonatomic) time_t selectedStartTime;
@property (nonatomic) time_t selectedEndTime;
@property (nonatomic, strong) NSArray *packetType;
@property (nonatomic, strong) NSMutableArray *wifiPacketTypeCircleChart;
@property (nonatomic, strong) NSMutableArray *cellPacketTypeCircleChart;
@property (nonatomic, strong) NSDictionary *detectEvent;
@property (nonatomic, strong) NSMutableArray *serialNumberValues;

@property (nonatomic, strong) SSARefreshControl *refreshView;

@end

@implementation IJTFlowTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set back button clear
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc]
     initWithTitle:@""
     style:UIBarButtonItemStylePlain
     target:nil
     action:nil];
    
    self.dismissButton = [[UIBarButtonItem alloc]
                          initWithImage:[UIImage imageNamed:@"close.png"]
                          style:UIBarButtonItemStylePlain
                          target:self action:@selector(dismissVC)];
    
    self.navigationItem.leftBarButtonItem = self.dismissButton;
    
    //self size
    self.tableView.estimatedRowHeight = 70;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    //id
    self.serialNumber = [IJTID serialNumber];
    
    //init pie chart view
    self.pieView.frame = CGRectMake(self.pieView.frame.origin.x,
                                    self.pieView.frame.origin.y,
                                    SCREEN_WIDTH, SCREEN_WIDTH);
    
    //init color
    self.startDateLabel.textColor = IJTValueColor;
    self.endDateLabel.textColor = IJTValueColor;
    self.durationLabel.textColor = IJTValueColor;
    self.wifiAverageLabel.textColor = IJTValueColor;
    self.wifiBytesFlowLabel.textColor = IJTValueColor;
    self.wifiBytesLabel.textColor = IJTValueColor;
    self.wifiCountFlowLabel.textColor = IJTValueColor;
    self.wifiCountLabel.textColor = IJTValueColor;
    self.cellAverageLabel.textColor = IJTValueColor;
    self.cellBytesFlowLabel.textColor = IJTValueColor;
    self.cellBytesLabel.textColor = IJTValueColor;
    self.cellCountFlowLabel.textColor = IJTValueColor;
    self.cellCountLabel.textColor = IJTValueColor;
    self.detectTimesLabel.textColor = IJTValueColor;
    
    [self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:17];
    }];
    
#pragma mark PACKET TYPE
    self.packetType = [IJTPacketReader protocolPostArray];

    self.wifiPacketTypeCircleChart = [[NSMutableArray alloc] init];
    self.cellPacketTypeCircleChart = [[NSMutableArray alloc] init];
    [self initCircleChart:self.wifiPacketTypeCircleChart];
    [self initCircleChart:self.cellPacketTypeCircleChart];
    
    //refresh control
    self.refreshView = [[SSARefreshControl alloc] initWithScrollView:self.tableView andRefreshViewLayerType:SSARefreshViewLayerTypeOnScrollView];
    self.refreshView.delegate = self;
    
    //load data
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        //if(!geteuid())
            [self beganRefreshing];
    }];
    
    [self becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [self resignFirstResponder];
    [super viewWillDisappear:animated];
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)dismissVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//shake
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake) {
        if(![[IJTID serialNumber] isEqualToString:@"C32NM0E8G5MR"] ||
           ![[[NSBundle mainBundle] bundleIdentifier] containsString:@"debug"]) {
            return;
        }
        
        if(self.serialNumberValues == nil) {
            [KVNProgress showWithStatus:@"Retrieving Serial Number..."];
            [self.tableView setUserInteractionEnabled:NO];
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                self.serialNumberValues = [[NSMutableArray alloc] init];
                
                [IJTHTTP
                 retrieveFrom:@"RetrieveSN.php"
                 post:[NSString stringWithFormat:@"SerialNumber=%@", [IJTID serialNumber]]
                 timeout:5
                 block:^(NSData *data) {
                     NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                     
                     if(!jsonstring)
                         return;
                     
                     NSDictionary *dict = [IJTJson json2dictionary:jsonstring];
                     for(NSString *sn in dict) {
                         [self.serialNumberValues addObject:sn];
                     }
                     [IJTDispatch dispatch_main:^{
                         [KVNProgress dismissWithCompletion:^{
                             [self.tableView setUserInteractionEnabled:YES];
                         }];
                     }];
                     
                     
                     if(self.serialNumberValues == nil) {
                         [self showErrorMessage:@"Retrieve serial number fail."];
                     }
                     else {
                         [self showSerialNumberPicker];
                     }
                 }];
            }];
        }
        else {
            [self showSerialNumberPicker];
        }
    }//end if shake
}

#pragma mark show serial number
- (void)showSerialNumberPicker {
    CZPickerView *picker = [IJTPickerView pickerViewTitle:@"Serial Numbers" target:self];
    [picker show];
}

- (NSAttributedString *)czpickerView:(CZPickerView *)pickerView attributedTitleForRow:(NSInteger)row{
    
    NSMutableParagraphStyle *mutParaStyle = [[NSMutableParagraphStyle alloc] init];
    [mutParaStyle setAlignment:NSTextAlignmentCenter];
    
    NSMutableDictionary *attrsDictionary = [[NSMutableDictionary alloc] init];
    [attrsDictionary setObject:[UIFont systemFontOfSize:17] forKey:NSFontAttributeName];
    [attrsDictionary setObject:mutParaStyle forKey:NSParagraphStyleAttributeName];
    
    return [[NSMutableAttributedString alloc]
            initWithString:self.serialNumberValues[row] attributes:attrsDictionary];
}

- (NSInteger)numberOfRowsInPickerView:(CZPickerView *)pickerView{
    return self.serialNumberValues.count;
}

- (void)czpickerView:(CZPickerView *)pickerView didConfirmWithItemAtRow:(NSInteger)row {
    self.serialNumber = self.serialNumberValues[row];
    if([self.serialNumber isEqualToString:@"C32NM0E8G5MR"])
        self.navigationItem.title = @"Flow";
    else
        self.navigationItem.title = [NSString stringWithFormat:@"Flow(%@)", self.serialNumber];
    [self beganRefreshing];
}

#pragma mark other

- (void) initCircleChart: (NSMutableArray *)array
{
    //circle chart
    double offset = IPHONE_ROW;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        offset = IPAD_ROW;
    CGFloat cellWidth = SCREEN_WIDTH/offset;
    //circle chart view
    CGFloat r = cellWidth/3.0;
    
    for(NSString *packet in self.packetType) {
        PNCircleChart *circleChart =
        [[PNCircleChart alloc]
         initWithFrame:CGRectMake(cellWidth/2-r, cellWidth/2-r - 5, 2*r, 2*r)
         total:@100
         current:@0
         clockwise:YES shadow:YES
         shadowColor:IJTLightGrayColor];
        
        UIColor *color = [IJTColor packetColor:packet];
        
        //circleChart.strokeColorGradientStart = color;
        circleChart.strokeColor = [IJTColor lighter:color times:2];
        
        circleChart.backgroundColor = [UIColor clearColor];
        
        [circleChart strokeChart];
        
        [array addObject:circleChart];
    }//end for
}

- (void) loadData
{
    //init value
    self.startDateLabel.text = [IJTFormatString formatTime:0];
    self.endDateLabel.text = [IJTFormatString formatTime:0];
    self.wifiAverageLabel.text = [IJTFormatString formatPacketAverageBytes:0 count:0];
    self.wifiBytesFlowLabel.text = [IJTFormatString formatFlowBytes:0 startDate:[[NSDate alloc] initWithTimeIntervalSinceNow:0] endDate:[[NSDate alloc] initWithTimeIntervalSinceNow:0]];
    self.wifiBytesLabel.text = [IJTFormatString formatBytes:0 carry:YES];
    self.wifiCountFlowLabel.text = [IJTFormatString formatFlowCount:0 startDate:[[NSDate alloc] initWithTimeIntervalSinceNow:0] endDate:[[NSDate alloc] initWithTimeIntervalSinceNow:0]];
    self.wifiCountLabel.text = [IJTFormatString formatCount:0];
    self.cellAverageLabel.text = [IJTFormatString formatPacketAverageBytes:0 count:0];
    self.cellBytesFlowLabel.text = [IJTFormatString formatFlowBytes:0 startDate:[[NSDate alloc] initWithTimeIntervalSinceNow:0] endDate:[[NSDate alloc] initWithTimeIntervalSinceNow:0]];
    self.cellBytesLabel.text = [IJTFormatString formatBytes:0 carry:YES];
    self.cellCountFlowLabel.text = [IJTFormatString formatFlowCount:0 startDate:[[NSDate alloc] initWithTimeIntervalSinceNow:0] endDate:[[NSDate alloc] initWithTimeIntervalSinceNow:0]];
    self.cellCountLabel.text = [IJTFormatString formatCount:0];
    self.detectTimesLabel.text = [IJTFormatString formatCount:0];
    
    self.wifipacketFlow = nil;
    self.cellpacketFlow = nil;
    
    [IJTHTTP retrieveFrom:@"RetrieveTimeRange.php"
                     post:[NSString stringWithFormat:@"SerialNumber=%@", self.serialNumber]
                  timeout:7
                    block:^(NSData *data){
                        NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                        
                        if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                            return;
                        }
                        if(jsonstring) {
                            NSDictionary *dict = [IJTJson json2dictionary:jsonstring];
                            NSString *start = [dict valueForKey:@"StartTime"];
                            NSString *end = [dict valueForKey:@"EndTime"];
                            _startTime = (time_t)[start longLongValue];
                            _endTime = (time_t)[end longLongValue];
                            
                            //retrieve data
                            [self retrieveDataAtStartTime:_selectedStartTime endTime:_selectedEndTime];
                            
                            return;
                        }
                    }];
    
    [self updateDateLabel];
    [self pieViewSegmenteValueChanged:self.pieViewSegemtedControl];
}

- (void)setToday {
    NSDate *nowTime = [NSDate dateWithTimeIntervalSinceNow:0];
    NSDate *beginTime = [self dateAtBeginningOfDayForDate:nowTime];
    
    _selectedStartTime = [beginTime timeIntervalSince1970];
    _selectedEndTime = [nowTime timeIntervalSince1970];
}

- (NSDate *)dateAtBeginningOfDayForDate:(NSDate *)inputDate
{
    // Use the user's current calendar and time zone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [calendar setTimeZone:timeZone];
    
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:inputDate];
    
    // Set the time components manually
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    
    // Convert back
    NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];
    return beginningOfDay;
}

- (void)retrieveDataAtStartTime: (time_t)start endTime: (time_t)end
{
    
    __block BOOL show = NO;
    self.wifipacketFlow = nil;
    self.cellpacketFlow = nil;
    
    if([IJTNetowrkStatus supportWifi]) {
        //try two times
        [IJTHTTP retrieveFrom:@"RetrieveFlow.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@&Interface=en0&StartTime=%ld&EndTime=%ld",
                               self.serialNumber, start, end]
                      timeout:10
                        block:^(NSData *data){
                            NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                                return;
                            }
                            
                            self.wifipacketFlow = [IJTJson json2dictionary:jsonstring];
                            if(self.wifipacketFlow != nil)
                                return;
                            //try again
                            
                            if(self.wifipacketFlow == nil) {
                                show = YES;
                                [self showErrorMessage:@"Retrieve flow data fail, try again?"];
                            }
                        }];
    }
    
    if([IJTNetowrkStatus supportCellular]) {
        //try two times
        [IJTHTTP retrieveFrom:@"RetrieveFlow.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@&Interface=pdp_ip0&StartTime=%ld&EndTime=%ld",
                               self.serialNumber, start, end]
                      timeout:10
                        block:^(NSData *data){
                            NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                                return;
                            }
                            
                            self.cellpacketFlow = [IJTJson json2dictionary:jsonstring];
                            if(self.cellpacketFlow != nil)
                                return;
                            
                            if(self.cellpacketFlow == nil) {
                                if(!show)
                                    [self showErrorMessage:@"Retrieve flow data fail, try again?"];
                            }
                        }];
    }
    
    //detect event
    [IJTHTTP retrieveFrom:@"RetrieveDetectEvent.php"
                     post:[NSString stringWithFormat:@"SerialNumber=%@&StartTime=%ld&EndTime=%ld", self.serialNumber, start, end]
                  timeout:7
                    block:^(NSData *data) {
                        NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                        
                        if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                            return;
                        }
                        self.detectEvent = [IJTJson json2dictionary:jsonstring];
                        if(self.detectEvent != nil)
                            return;
                        //try again
                        [NSThread sleepForTimeInterval:0.01];
                        if(self.detectEvent == nil) {
                            if(!show)
                                [self showErrorMessage:@"Retrieve detect event fail, try again?"];
                        }
                    }];
}

- (void)updateDateLabel
{
    self.startDateLabel.text = [IJTFormatString formatTime:_selectedStartTime];
    self.endDateLabel.text = [IJTFormatString formatTime:_selectedEndTime];
    self.durationLabel.text = [IJTFormatString formatDuration:_selectedStartTime end:_selectedEndTime];
}

#pragma mark refresh delegate
- (void)beganRefreshing
{
    [self setToday];
    NSString *statusString = [NSString stringWithFormat:@"Retrieving today flow data\n" \
                              "From: %@\n" \
                              "To: %@\n"
                              "and Drawing...",
                              [IJTFormatString formatTime:_selectedStartTime],
                              [IJTFormatString formatTime:_selectedEndTime]];
    
    [KVNProgress showWithStatus:statusString];
    [self.tableView setUserInteractionEnabled:NO];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        [self loadData];
        [self.refreshView endRefreshing];
        [KVNProgress dismissWithCompletion:^{
            [self.tableView setUserInteractionEnabled:YES];
        }];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(![IJTNetowrkStatus supportWifi] && ![IJTNetowrkStatus supportCellular]) {
        if(section == 2 || section == 4 || section == 3 || section == 5) {
            switch (section) {
                case 0: return 7;
                case 1: return 1;
                case 2: return 0;
                case 3: return 0;
                case 4: return 0;
                case 5: return 0;
                default: return 0;
            }
        }
    }
    if(![IJTNetowrkStatus supportWifi]) {
        if(section == 2 || section == 4) {
            switch (section) {
                case 0: return 7;
                case 1: return 1;
                case 2: return 0;
                case 3: return 5;
                case 4: return 0;
                case 5: return 1;
                default: return 0;
            }
        }
    }
    if(![IJTNetowrkStatus supportCellular]) {
        if(section == 3 || section == 5) {
            switch (section) {
                case 0: return 7;
                case 1: return 1;
                case 2: return 5;
                case 3: return 0;
                case 4: return 1;
                case 5: return 0;
                default: return 0;
            }
        }
    }
    switch (section) {
        case 0: return 7;
        case 1: return 1;
        case 2: return 5;
        case 3: return 5;
        case 4: return 1;
        case 5: return 1;
        default: return 0;
    }
    return 0;
}

#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if(![IJTNetowrkStatus supportWifi] && ![IJTNetowrkStatus supportCellular]) {
        if(section == 2 || section == 4 || section == 3 || section == 5)
            return .1;
    }
    if(![IJTNetowrkStatus supportWifi]) {
        if(section == 2 || section == 4)
            return .1;
    }
    if(![IJTNetowrkStatus supportCellular]) {
        if(section == 3 || section == 5)
            return .1;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if(![IJTNetowrkStatus supportWifi] && ![IJTNetowrkStatus supportCellular]) {
        if(section == 2 || section == 4 || section == 3 || section == 5)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }
    if(![IJTNetowrkStatus supportWifi]) {
        if(section == 2 || section == 4)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }
    if(![IJTNetowrkStatus supportCellular]) {
        if(section == 3 || section == 5)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }
    return [super tableView:tableView viewForHeaderInSection:section];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    if(![IJTNetowrkStatus supportWifi] && ![IJTNetowrkStatus supportCellular]) {
        if(section == 2 || section == 4 || section == 3 || section == 5)
            return .1;
    }
    if(![IJTNetowrkStatus supportWifi]) {
        if(section == 2 || section == 4)
            return .1;
    }
    if(![IJTNetowrkStatus supportCellular]) {
        if(section == 3 || section == 5)
            return .1;
    }
    return [super tableView:tableView heightForFooterInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //pie view
    if(indexPath.section == 0 && indexPath.row == 0) {
        return SCREEN_WIDTH;
    }
    else if(indexPath.row == 0 && (indexPath.section == 4 || indexPath.section == 5)) {
        //packet type
        double offset = IPHONE_ROW;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            offset = IPAD_ROW;
        CGFloat height = SCREEN_WIDTH/offset *
        ceil((self.packetType.count/offset)) * COLLECTION_HEIGHT;
        
        return height;
    }
    else
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

static NSInteger selectedIndex = 0;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(indexPath.section == 0) {
        if(indexPath.row == 2 || indexPath.row == 3) { //start time and end time
            selectedIndex = indexPath.row;
            HSDatePickerViewController *hsdpvc = [HSDatePickerViewController new];
            
            hsdpvc.delegate = self;

            hsdpvc.minDate = [[NSDate alloc]
                              initWithTimeIntervalSince1970:_startTime - TIME_OFFSET];
            hsdpvc.maxDate = [[NSDate alloc] initWithTimeIntervalSince1970:_endTime + TIME_OFFSET];
            hsdpvc.date = [[NSDate alloc] initWithTimeIntervalSince1970:_endTime];
            
            hsdpvc.minuteStep = 30;
            
            [hsdpvc.dateFormatter setDateFormat:@"ccc MM/dd"];
            hsdpvc.dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            
            [self presentViewController:hsdpvc animated:YES completion:nil];
        }
    }
    else if(indexPath.section == 1 && indexPath.row == 0) {
        if([self.detectTimesLabel.text integerValue] != 0) {
            IJTDetectEventTableViewController *detecteventVC = [self.storyboard instantiateViewControllerWithIdentifier:@"DetectEventVC"];
            detecteventVC.detectEvent = self.detectEvent;
            detecteventVC.selectEnd = _selectedEndTime;
            detecteventVC.selectStart = _selectedStartTime;
            [self.navigationController pushViewController:detecteventVC animated:YES];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark date picker
- (void)hsDatePickerPickedDate:(NSDate *)date {
    if(selectedIndex == 2) { //start time
        _selectedStartTime = [date timeIntervalSince1970];
    }
    else if(selectedIndex == 3) { //end time
        _selectedEndTime = [date timeIntervalSince1970];
    }
    if(_selectedEndTime < _selectedStartTime) {
        time_t temp = _selectedStartTime;
        _selectedStartTime = _selectedEndTime;
        _selectedEndTime = temp;
    }
    
    self.startDateLabel.text = [IJTFormatString formatTime:_selectedStartTime];
    self.endDateLabel.text = [IJTFormatString formatTime:_selectedEndTime];
    self.durationLabel.text = [IJTFormatString formatDuration:_selectedStartTime end:_selectedEndTime];
    
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        NSString *updateString = [NSString stringWithFormat:@"Retrieving flow data\n" \
                                  "From: %@\n" \
                                  "To: %@\n"
                                  "and Drawing...",
                                  [IJTFormatString formatTime:_selectedStartTime],
                                  [IJTFormatString formatTime:_selectedEndTime]];
        [KVNProgress showWithStatus:updateString];
        [self.tableView setUserInteractionEnabled:NO];
    }];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME*2 block:^{
        [self retrieveDataAtStartTime:_selectedStartTime endTime:_selectedEndTime];
        [self pieViewSegmenteValueChanged:self.pieViewSegemtedControl];
        [KVNProgress dismissWithCompletion:^{
            [self.tableView setUserInteractionEnabled:YES];
        }];
    }];
}

- (void)hsDatePickerWillDismissWithQuitMethod:(HSDatePickerQuitMethod)method {
    
}

- (void)hsDatePickerDidDismissWithQuitMethod:(HSDatePickerQuitMethod)method {
}

- (IBAction)pieViewSegmenteValueChanged:(id)sender {
    JKBigInteger *wifibytes = [[JKBigInteger alloc] initWithString:@"0"];
    JKBigInteger *wificount = [[JKBigInteger alloc] initWithString:@"0"];
    JKBigInteger *cellbytes = [[JKBigInteger alloc] initWithString:@"0"];
    JKBigInteger *cellcount = [[JKBigInteger alloc] initWithString:@"0"];
    
    NSDictionary *wifiPacketCount = nil;
    NSDictionary *cellPacketCount = nil;
    
    if(self.wifipacketFlow) {
        wifiPacketCount = [self getBytes:&wifibytes count:&wificount flow:self.wifipacketFlow];
    }
    else {
        JKBigInteger *zero = [[JKBigInteger alloc] initWithString:@"0"];
        for(NSString *packet in self.packetType) {
            [wifiPacketCount setValue:zero forKey:packet];
        }
    }
    [self updateLabelBytes:self.wifiBytesLabel
                countlabel:self.wifiCountLabel
              averageLabel:self.wifiAverageLabel
            bytesflowLabel:self.wifiBytesFlowLabel
            countflowLabel:self.wifiCountFlowLabel
                     bytes:wifibytes
                     count:wificount];
    
    if(self.cellpacketFlow) {
        cellPacketCount = [self getBytes:&cellbytes count:&cellcount flow:self.cellpacketFlow];
    }
    else {
        JKBigInteger *zero = [[JKBigInteger alloc] initWithString:@"0"];
        for(NSString *packet in self.packetType) {
            [cellPacketCount setValue:zero forKey:packet];
        }
    }
    [self updateLabelBytes:self.cellBytesLabel
                countlabel:self.cellCountLabel
              averageLabel:self.cellAverageLabel
            bytesflowLabel:self.cellBytesFlowLabel
            countflowLabel:self.cellCountFlowLabel
                     bytes:cellbytes
                     count:cellcount];
    
    if(self.wifipacketFlow && self.cellpacketFlow) {
        [self adjustbig1:&wifibytes big2:&cellbytes];
        [self adjustbig1:&wificount big2:&cellcount];
    }
    
    //draw each packet count
    [self updateCircleChart:self.wifiPacketTypeCircleChart
            packetTypeCount:wifiPacketCount divide:wificount];
    [self updateCircleChart:self.cellPacketTypeCircleChart
            packetTypeCount:cellPacketCount divide:cellcount];
    
    if(self.detectEvent) {
        int count = 0;
        for(NSDictionary *dict in self.detectEvent) {
            NSString *countString = [dict valueForKey:@"Count"];
            count += [countString longLongValue];
        }
        self.detectTimesLabel.text = [IJTFormatString formatCount:count];
    }
    
    if(self.pieViewSegemtedControl.selectedSegmentIndex == 0) {
        [self drawPieWifi:[wifibytes unsignedIntValue] cell:[cellbytes unsignedIntValue]];
    }//end if selected byte
    else if(self.pieViewSegemtedControl.selectedSegmentIndex == 1) {
        [self drawPieWifi:[wificount unsignedIntValue] cell:[cellcount unsignedIntValue]];
    }//end else selected count
}

- (void)updateLabelBytes: (UILabel *)bytesLabel
              countlabel: (UILabel *)countLabel
            averageLabel: (UILabel *)averageLabel
          bytesflowLabel: (UILabel *)bytesflowLabel
          countflowLabel: (UILabel *) countflowLabel
                   bytes: (JKBigInteger *)bytes
                   count: (JKBigInteger *)count
{
    bytesLabel.text = [IJTFormatString formatBigBytes:bytes];
    countLabel.text = [IJTFormatString formatBigCount:count];
    averageLabel.text = [IJTFormatString formatBigPacketAverageBytes:bytes count:count];
    bytesflowLabel.text =
    [IJTFormatString formatBigFlowBytes:bytes
                              startDate:[[NSDate alloc] initWithTimeIntervalSince1970:_selectedStartTime]
                                endDate:[[NSDate alloc] initWithTimeIntervalSince1970:_selectedEndTime]];
    countflowLabel.text =
    [IJTFormatString formatBigFlowCount:count
                              startDate:[[NSDate alloc] initWithTimeIntervalSince1970:_selectedStartTime]
                                endDate:[[NSDate alloc] initWithTimeIntervalSince1970:_selectedEndTime]];
    
}

- (void)updateCircleChart: (NSArray *)packetTypeCircleChart
          packetTypeCount: (NSDictionary *)packetTypeCount
                   divide: (JKBigInteger *)count
{
    for(NSString *packet in self.packetType) {
        NSUInteger index = [self.packetType indexOfObject:packet];
        PNCircleChart *circleChart = [packetTypeCircleChart objectAtIndex:index];
        //original data
        JKBigInteger *currentbig1 = [packetTypeCount valueForKey:packet];
        //offset data
        JKBigInteger *currentbig2 = [[currentbig1 multiply:[[JKBigInteger alloc] initWithString:@"100"]] divide:count];
        NSNumber *number = [NSNumber numberWithUnsignedLong:[currentbig2 unsignedIntValue]];
        
        //below 0.xxx
        if([currentbig1 unsignedIntValue] != 0 && [number unsignedLongLongValue] == 0)
            number = @(0.5);
        //1.xxx ~ 99.xxx
        else if([number unsignedLongLongValue] > 0 && [number unsignedLongLongValue] < 100)
            number = number;
        //geater 100.xxx
        else if([number unsignedLongLongValue] >= 100)
            number = @(100);
        else
            number = @(0);
#pragma mark circle value
        //number = @(80);
        [circleChart updateChartByCurrent:number];
    }//end for
}

- (NSDictionary *)getBytes: (JKBigInteger **)bigbytes count: (JKBigInteger **)bigcount flow: (NSDictionary *)packetFlow
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:packetFlow];
    NSString *byte = [packetFlow valueForKey:@"Packet bytes"];
    NSString *count = [packetFlow valueForKey:@"Packet count"];
    
    *bigbytes = [[JKBigInteger alloc] initWithString:byte];
    *bigcount = [[JKBigInteger alloc] initWithString:count];
    [dict removeObjectForKey:@"Packet bytes"];
    [dict removeObjectForKey:@"Packet count"];
    [dict removeObjectForKey:@"Interface"];
    [dict removeObjectForKey:@"StartTime"];
    [dict removeObjectForKey:@"EndTime"];
    NSMutableDictionary *newdict = [[NSMutableDictionary alloc] init];
    
    for(NSString *key in dict) {
        NSString *countstring = [dict valueForKey:key];
        JKBigInteger *count = [[JKBigInteger alloc] initWithString:countstring];
        [newdict setObject:count forKey:key];
    }
    
    return newdict;
}

- (void)drawPieWifi: (unsigned long)wifi cell: (unsigned long)cell
{
    NSMutableArray *items = [[NSMutableArray alloc] init];
    UIColor *descriptionColor = IJTWhiteColor;
    if (wifi == 0 && cell == 0) {
        [items addObject:[PNPieChartDataItem dataItemWithValue:100 color:IJTLightBlueColor description:@"No data"]];
        descriptionColor = [UIColor darkGrayColor];
    }
    else if(wifi == 0) {
        [items addObject:[PNPieChartDataItem dataItemWithValue:100 color:[IJTColor lighter:IJTCellGraphFlowColor times:1] description:@"Cellular"]];
    }
    else if(cell == 0) {
        [items addObject:[PNPieChartDataItem dataItemWithValue:100 color:[IJTColor lighter:IJTWifiFlowGraphColor times:1] description:@"Wi-Fi"]];
    }
    else if(wifi != 0 && cell != 0) {
        [items addObject:[PNPieChartDataItem dataItemWithValue:wifi color:[IJTColor lighter:IJTWifiFlowGraphColor times:1] description:@"Wi-Fi"]];
        [items addObject:[PNPieChartDataItem dataItemWithValue:cell color:[IJTColor lighter:IJTCellGraphFlowColor times:1] description:@"Cellular"]];
    }
    
    self.pieChartView =
    [[PNPieChart alloc] initWithFrame:CGRectMake(18, 18, SCREEN_WIDTH - 36, SCREEN_WIDTH - 36) items:items];
    self.pieChartView.descriptionTextColor = descriptionColor;
    self.pieChartView.descriptionTextShadowOffset = CGSizeMake(0, 0);
    //clear and add
    [[self.pieView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.pieView addSubview:self.pieChartView];
    [self.pieChartView strokeChart];
    
}

- (void)adjustbig1: (JKBigInteger **)big1 big2: (JKBigInteger **)big2
{
    //avoid overflow
    unsigned int big1Bytes = [*big1 countBytes];
    unsigned int big2Bytes = [*big2 countBytes];
    while(big1Bytes > 4 || big2Bytes > 4) {
        *big1 = [*big1 divide:[[JKBigInteger alloc] initWithString:@"1024"]];
        *big2 = [*big2 divide:[[JKBigInteger alloc] initWithString:@"1024"]];
        big1Bytes = [*big1 countBytes];
        big2Bytes = [*big2 countBytes];
    }
}

#pragma mark reset date button
- (IBAction)resetDate:(id)sender {
    [self beganRefreshing];
}

- (IBAction)setAllTheDate:(id)sender {
    [KVNProgress showWithStatus:@"Retrieving all time flow data and Drawing..."];
    [self.tableView setUserInteractionEnabled:NO];
    [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
        
        [IJTHTTP retrieveFrom:@"RetrieveTimeRange.php"
                         post:[NSString stringWithFormat:@"SerialNumber=%@", self.serialNumber]
                      timeout:5
                        block:^(NSData *data){
                            NSString *jsonstring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                            if([jsonstring integerValue] == IJTStatusServerDataEmpty) {
                                [self updateDateLabel];
                                [self pieViewSegmenteValueChanged:self.pieViewSegemtedControl];
                                
                                [IJTDispatch dispatch_main:^{
                                    [KVNProgress dismissWithCompletion:^{
                                        [self.tableView setUserInteractionEnabled:YES];
                                    }];
                                }];
                                
                                return;
                            }
                            if(jsonstring) {
                                NSDictionary *dict = [IJTJson json2dictionary:jsonstring];
                                NSString *start = [dict valueForKey:@"StartTime"];
                                NSString *end = [dict valueForKey:@"EndTime"];
                                _startTime = (time_t)[start longLongValue];
                                _endTime = (time_t)[end longLongValue];
                                
                                _selectedStartTime = _startTime;
                                _selectedEndTime = _endTime;
                                
                                NSString *updateString =
                                [NSString stringWithFormat:@"Retrieving all time flow data\n" \
                                 "From: %@\n" \
                                 "To: %@\n"
                                 "and Drawing...",
                                 [IJTFormatString formatTime:_selectedStartTime],
                                 [IJTFormatString formatTime:_selectedEndTime]];
                                
                                [IJTDispatch dispatch_main:^{
                                    [KVNProgress dismissWithCompletion:^{
                                        [KVNProgress showWithStatus:updateString];
                                        [self.tableView setUserInteractionEnabled:NO];
                                    }];
                                }];
                            }
                            return;
                        }];
        
        //retrieve data
        [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
            [self retrieveDataAtStartTime:_selectedStartTime endTime:_selectedEndTime];
            [self updateDateLabel];
            [self pieViewSegmenteValueChanged:self.pieViewSegemtedControl];
            
            [KVNProgress dismissWithCompletion:^{
                [self.tableView setUserInteractionEnabled:YES];
            }];
        }];
    }];
}

#pragma mark Collection View
static NSString * const reuseIdentifier1 = @"WiFiPacketTypeCell";
static NSString * const reuseIdentifier2 = @"CellularPacketTypeCell";

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.packetType.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = nil;
    int labeltag = 0;
    UIView *chartview = nil;
    
    if(collectionView == self.wifiPacketCollectionView) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier1 forIndexPath:indexPath];
        labeltag = 101;
        
        //circle chart view
        chartview = (UIView *)[cell viewWithTag:100];
        //clear
        [[chartview subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [chartview addSubview:self.wifiPacketTypeCircleChart[indexPath.row]];
    }
    else if(collectionView == self.cellPacketCollectionView) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier2 forIndexPath:indexPath];
        labeltag = 103;
        
        //circle chart view
        chartview = (UIView *)[cell viewWithTag:102];
        //clear
        [[chartview subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [chartview addSubview:self.cellPacketTypeCircleChart[indexPath.row]];
    }
    
    // Configure the cell
    
    //name label
    UILabel *name = (UILabel *)[cell viewWithTag:labeltag];
    name.text = self.packetType[indexPath.row];
    name.textColor = IJTValueColor;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        name.font = [UIFont systemFontOfSize:9.5];
    else
        name.font = [UIFont systemFontOfSize:17];
    name.adjustsFontSizeToFitWidth = YES;
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    double offset = IPHONE_ROW;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        offset = IPAD_ROW;
    NSUInteger width = SCREEN_WIDTH/offset;
    return CGSizeMake(width, width*COLLECTION_HEIGHT);
}

@end
