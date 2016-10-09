//
//  IJTSnifferTableViewController.m
//  Injector
//
//  Created by 聲華 陳 on 2015/2/27.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTSnifferTableViewController.h"
#import "IJTFilterTableViewController.h"
#import "IJTPacketTableViewController.h"
#define RELOADTIMER 1
#define SCROLLVIEWOFFSET 40
#define MAXDATALEN 20+1
#define ALERTREMAININGTIME 30
@interface IJTSnifferTableViewController ()

typedef enum
{
    stopRecord,
    recording,
} RecordStatus;

@property (nonatomic, strong) UIBarButtonItem *wifiButton;
@property (nonatomic, strong) UIBarButtonItem *cellButton;
@property (nonatomic, strong) UIBarButtonItem *startButton;
@property (nonatomic) RecordStatus nowStatus;
@property (nonatomic) IJTPacketReaderType nowType;
@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) Reachability *cellReachability;
@property (nonatomic, strong) NSMutableArray *flowGraphBytes;
@property (nonatomic, strong) NSMutableArray *flowGraphCount;
@property (nonatomic, strong) NSMutableArray *flowGraphTimestamp;
@property (nonatomic, strong) NSTimer *reloadFlowGraphAndDataTimer;
@property (nonatomic, strong) NSTimer *reloadPacketViewTimer;
@property (nonatomic, strong) BEMSimpleLineGraphView *flowGraphView;
@property (nonatomic, strong) IJTPcap *pcap;
@property (nonatomic) BOOL supportWifi;
@property (nonatomic) BOOL supportCellular;
@property (nonatomic, strong) IJTPacketQueue *packetQueue;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic) NSUInteger totalBytes;
@property (nonatomic) NSUInteger totalCount;
@property (nonatomic, strong) NSArray *packetType;
@property (nonatomic, strong) NSMutableDictionary *packetTypeCount;
@property (nonatomic, strong) NSMutableArray *packetTypeCircleChart;
@property (nonatomic, strong) UIImageView *gestureImage;
@property (nonatomic) BOOL alertRemaining;
@property (nonatomic, weak) IJTPacketTableViewController *packetVC;
@property (nonatomic, strong) FUITextField *packetQueueSizeTextField;
@property (nonatomic, strong) FUITextField *reloadIntervalTextField;
@property (nonatomic) NSInteger currentIndex;

@end

@implementation IJTSnifferTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self size
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    //set title text
    self.navigationItem.title = @"Sniffer(Wi-Fi)";
    
    //other
    self.nowStatus = stopRecord;
    self.nowType = IJTPacketReaderTypeWiFi;
    
    //check if support gprs
    self.supportCellular = [IJTNetowrkStatus supportCellular];
    self.supportWifi = [IJTNetowrkStatus supportWifi];

    if(self.multiToolButton == nil) {
        self.dismissButton = [[UIBarButtonItem alloc]
                              initWithImage:[UIImage imageNamed:@"close.png"]
                              style:UIBarButtonItemStylePlain
                              target:self action:@selector(dismissVC)];
    }
    else {
        self.dismissButton = self.multiToolButton;
    }
    
    self.navigationItem.leftBarButtonItem = self.dismissButton;
    
    //set start button
    self.startButton = [[UIBarButtonItem alloc]
                        initWithImage:[UIImage imageNamed:@"record.png"]
                        style:UIBarButtonItemStyleDone
                        target:self action:@selector(startRecord)];
    self.startButton.tintColor = IJTStartRecordColor;
    
    //set stop button
    [self.stopButton setTarget:self];
    [self.stopButton setAction:@selector(stopRecord)];
    
    //set wifi button
    self.wifiButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"wifi.png"]
                       style:UIBarButtonItemStyleDone target:self
                       action:@selector(changeRecordType)];
    self.wifiButton.tintColor = IJTWifiColor;
                                 
    self.cellButton = [[UIBarButtonItem alloc]
                       initWithImage:[UIImage imageNamed:@"sim_card.png"]
                       style:UIBarButtonItemStyleDone target:self
                       action:@selector(changeRecordType)];
    self.cellButton.tintColor = IJTCellColor;
    
    //put the buttons
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects:self.startButton, self.cellButton, nil];
    
    //network reachability
    //set notification
    [IJTNotificationObserver reachabilityAddObserver:self selector:@selector(reachabilityChanged:)];
    
    //wifi
    if(self.supportWifi) {
        self.wifiReachability = [IJTNetowrkStatus wifiReachability];
        [self.wifiReachability startNotifier];
        [self updateInterfaceWithReachability:self.wifiReachability];
    }
    //cell
    if(self.supportCellular) {
        self.cellReachability = [IJTNetowrkStatus cellReachability];
        [self.cellReachability startNotifier];
        [self updateInterfaceWithReachability:self.cellReachability];
    }
    
    //value lable color
    self.pcapFilterLabel.textColor = IJTValueColor;
    self.startTimeLabel.textColor = IJTValueColor;
    self.endTimeLabel.textColor = IJTValueColor;
    self.durationTimeLabel.textColor = IJTValueColor;
    self.countLabel.textColor = IJTValueColor;
    self.bytesLabel.textColor = IJTValueColor;
    self.byteFlowLabel.textColor = IJTValueColor;
    self.countFlowLabel.textColor = IJTValueColor;
    self.packetSizeLabel.textColor = IJTValueColor;
    
    [self.labels enumerateObjectsUsingBlock:^(UILabel *label, NSUInteger idx, BOOL *stop) {
        label.font = [UIFont systemFontOfSize:17];
    }];
    
    self.promicsSwitch.on = NO;
    
    //self size
    //self.tableView.estimatedRowHeight = 70;
    //self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    //default label value
    self.pcapFilterLabel.text = @"all";
    self.pcapFilterLabel.adjustsFontSizeToFitWidth = YES;
    
    //set change type icon enable
    [self.cellButton setEnabled:self.supportCellular];
    [self.wifiButton setEnabled:self.supportWifi];
    
    self.gestureImage = [[UIImageView alloc]
                         initWithImage:[UIImage imageNamed:@"swipe-left.png"]];
    
    self.flowGraphView = nil;
    
    //scroll view style
    self.flowGraphScrollView.bounces = NO;
    self.flowGraphScrollView.alwaysBounceHorizontal = NO;
    self.flowGraphScrollView.alwaysBounceVertical = NO;
    self.flowGraphScrollView.directionalLockEnabled = YES;
    self.flowGraphScrollView.showsHorizontalScrollIndicator = YES;
    self.flowGraphScrollView.showsVerticalScrollIndicator = NO;
    self.flowGraphScrollView.backgroundColor = [UIColor clearColor];
    self.flowGraphUpperView.backgroundColor = [UIColor clearColor];
    
    self.promicsSwitch.onLabel.text = @"YES";
    self.promicsSwitch.offLabel.text = @"NO";
    self.promicsSwitch.onLabel.font = [UIFont boldFlatFontOfSize:14];
    self.promicsSwitch.offLabel.font = [UIFont boldFlatFontOfSize:14];
    
    self.packetQueueSizeTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.packetQueueSizeTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    self.packetQueueSizeTextField.text = @"1000";
    self.packetQueueSizeTextField.placeholder = @"Packet view maximum size";
    [self.packetQueueSizeTextField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    
    [self.packetQueueSizeView addSubview:self.packetQueueSizeTextField];
    
    self.reloadIntervalTextField = [IJTTextField baseTextFieldWithTarget:self];
    self.reloadIntervalTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    self.reloadIntervalTextField.returnKeyType = UIReturnKeyDone;
    self.reloadIntervalTextField.text = @"1";
    self.reloadIntervalTextField.placeholder = @"Packet view reload interval(secs)";
    [self.reloadIntervalTextField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.reloadIntervalTextField addTarget:self action:@selector(textFieldEditingDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
    
    [self.reloadIntervalView addSubview:self.reloadIntervalTextField];
    
#pragma mark PACKET TYPE
    self.packetType = [IJTPacketReader protocolPostArray];
    
    [self initVC];
    
    NSInteger currentIndex = self.tabBarController.selectedIndex;
    self.packetVC =
    [[(UINavigationController *)
      [self.tabBarController.viewControllers objectAtIndex:currentIndex + 1]
      viewControllers] objectAtIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initVC
{
    //set time label
    self.startTimeLabel.text = @"";
    self.endTimeLabel.text = @"";
    self.durationTimeLabel.text = @"";
    self.countLabel.text = @"";
    self.bytesLabel.text = @"";
    self.byteFlowLabel.text = @"";
    self.countFlowLabel.text = @"";
    self.packetSizeLabel.text = @"";
    self.currentIndex = 0;
    
    //circle chart
    double offset = IPHONE_ROW;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        offset = IPAD_ROW;
    CGFloat cellWidth = SCREEN_WIDTH/offset;
    //circle chart view
    CGFloat r = cellWidth/3.0;
    
    self.packetTypeCount = [[NSMutableDictionary alloc] init];
    self.packetTypeCircleChart = [[NSMutableArray alloc] init];
    for(NSString *packet in self.packetType) {
        [self.packetTypeCount setValue:@0 forKey:packet];
        
        PNCircleChart *circleChart =
        [[PNCircleChart alloc]
         initWithFrame:CGRectMake(cellWidth/2-r, cellWidth/2-r - 5, 2*r, 2*r)
         total:@100
         current:@0
         clockwise:YES shadow:YES
         shadowColor:IJTLightGrayColor];
        
        UIColor *color = [IJTColor packetColor:packet];
        
        circleChart.strokeColorGradientStart = color;
        circleChart.strokeColor = [IJTColor lighter:color times:4];
        
        circleChart.backgroundColor = [UIColor clearColor];
        
        [circleChart strokeChart];
        
        [self.packetTypeCircleChart addObject:circleChart];
    }//end for
    
    //init flow graph
    NSUInteger viewHeight = CGRectGetHeight(self.flowGraphScrollView.frame);
    NSUInteger viewWidth = SCREEN_WIDTH - 16;
    
    //init data source
    self.flowGraphBytes = [[NSMutableArray alloc] initWithCapacity:MAXDATALEN + 10];
    self.flowGraphCount = [[NSMutableArray alloc] initWithCapacity:MAXDATALEN + 10];
    self.flowGraphTimestamp = [[NSMutableArray alloc] initWithCapacity:MAXDATALEN + 10];
    
    //init flow graph
    if(self.flowGraphView == nil) {
        self.flowGraphScrollView.contentSize = CGSizeMake(viewWidth, viewHeight);
        self.flowGraphView = [[BEMSimpleLineGraphView alloc]
                              initWithFrame:CGRectMake(0, 0, viewWidth, viewHeight - SCROLLVIEWOFFSET)];
        //delegate
        self.flowGraphView.dataSource = self;
        self.flowGraphView.delegate = self;
        
        //background color
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        size_t num_locations = 2;
        CGFloat locations[2] = { 0.0, 1.0 };
        CGFloat components[8] = {
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 0.0
        };
        
        CGGradientRef gradientRef = CGGradientCreateWithColorComponents(colorspace, components, locations, num_locations);
        [self.flowGraphView setGradientBottom:gradientRef];
        CGColorSpaceRelease(colorspace);
        //CGGradientRelease(gradientRef);
        
        //other style
        self.flowGraphView.enableBezierCurve = YES;
        self.flowGraphView.enableTouchReport = YES;
        self.flowGraphView.enablePopUpReport = YES;
        self.flowGraphView.enableXAxisLabel = YES;
        self.flowGraphView.enableYAxisLabel = YES;
        self.flowGraphView.autoScaleYAxis = YES;
        self.flowGraphView.enableReferenceXAxisLines = YES;
        self.flowGraphView.enableReferenceYAxisLines = YES;
        self.flowGraphView.enableReferenceAxisFrame = YES;
        self.flowGraphView.widthLine = 3;
        self.flowGraphView.colorXaxisLabel = IJTWhiteColor;
        self.flowGraphView.colorYaxisLabel = IJTWhiteColor;
        self.flowGraphView.animationGraphEntranceTime = 1;
        self.flowGraphView.colorLine = IJTWhiteColor;
        
        //add flow graph
        [self.flowGraphScrollView addSubview:self.flowGraphView];
        
        //gesture image
        self.gestureImage.frame =
        CGRectMake(viewWidth - SCROLLVIEWOFFSET, viewHeight - SCROLLVIEWOFFSET, SCROLLVIEWOFFSET, SCROLLVIEWOFFSET);
        
        [self.flowGraphScrollView addSubview:self.gestureImage];
    }
    else {
        self.flowGraphScrollView.contentSize = CGSizeMake(viewWidth, viewHeight);
        self.flowGraphView.frame = CGRectMake(0, 0, viewWidth, viewHeight - SCROLLVIEWOFFSET);
        [[self.flowGraphScrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.flowGraphScrollView addSubview:self.flowGraphView];
        [self.flowGraphScrollView addSubview:self.gestureImage];
        [self.flowGraphView reloadGraph];
    }
    
    self.gestureImage.hidden = YES;
    [self.flowGraphUpperView setHidden:NO];
    
    if(self.nowType == IJTPacketReaderTypeWiFi) {
        self.flowGraphView.colorTop = IJTWifiFlowGraphColor;
        self.flowGraphView.colorBottom = IJTWifiFlowGraphColor;
        self.flowGraphView.backgroundColor = IJTWifiFlowGraphColor;
    }
    else if(self.nowType == IJTPacketReaderTypeCellular) {
        self.flowGraphView.colorTop = IJTCellGraphFlowColor;
        self.flowGraphView.colorBottom = IJTCellGraphFlowColor;
        self.flowGraphView.backgroundColor = IJTCellGraphFlowColor;
    }
    
    //init packet type
    [self.collectionView reloadData];
}

- (void)dismissVC {
    [self dismissKeyboard];
    [IJTNotificationObserver reachabilityRemoveObserver:self];
    if([IJTNetowrkStatus supportWifi]) {
        [self.wifiReachability stopNotifier];
    }
    if([IJTNetowrkStatus supportCellular]) {
        [self.cellReachability stopNotifier];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)startRecord {
    [self dismissKeyboard];
    if(self.packetQueueSizeTextField.text.length <= 0) {
        [self showErrorMessage:@"Queue size is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:_packetQueueSizeTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid size.", _packetQueueSizeTextField.text]];
        return;
    }
    if(self.reloadIntervalTextField.text.length <= 0) {
        [self showErrorMessage:@"Reload interval is empty."];
        return;
    }
    else if(![IJTValueChecker checkAllDigit:_reloadIntervalTextField.text]) {
        [self showErrorMessage:[NSString stringWithFormat:@"\"%@\" is not a valid time.", _reloadIntervalTextField.text]];
        return;
    }
    
    if(self.packetVC && self.reloadPacketViewTimer == nil && [_reloadIntervalTextField.text longLongValue] > 0) {
        self.reloadPacketViewTimer =
        [NSTimer scheduledTimerWithTimeInterval:[_reloadIntervalTextField.text longLongValue]
                                         target:self
                                       selector:@selector(reloadPacketVC)
                                       userInfo:nil
                                        repeats:YES];
    }
    
    if(self.nowType == IJTPacketReaderTypeWiFi) {
        self.pcap = [[IJTPcap alloc] initInterface:@"en0" bpfFilter:self.pcapFilterLabel.text promisc:self.promicsSwitch.isOn toms:1];
    }
    else if(self.nowType == IJTPacketReaderTypeCellular)
        self.pcap = [[IJTPcap alloc] initInterface:@"pdp_ip0" bpfFilter:self.pcapFilterLabel.text promisc:self.promicsSwitch.isOn toms:1];
    
    if(self.pcap.occurError) {
        [self showErrorMessage:self.pcap.errorMessage];
        return;
    }//end if error
    
    if(self.nowType == IJTPacketReaderTypeWiFi && self.wifiReachability.currentReachabilityStatus == NotReachable) {
        [self showWarningMessage:@"No Wi-Fi connection. But it's still recording."];
    }
    else if(self.nowType == IJTPacketReaderTypeCellular && self.cellReachability.currentReachabilityStatus == NotReachable) {
        [self showWarningMessage:@"No Cellular connection. But it's still recording."];
    }
    
    self.nowStatus = recording;
    if(self.supportWifi)
        [self.wifiButton setEnabled:NO];
    if(self.supportCellular)
        [self.cellButton setEnabled:NO];
    [self.promicsSwitch setEnabled:NO];
    if(self.dismissButton.tag != MULTIBUTTONTAG)
        [self.dismissButton setEnabled:NO];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects:self.stopButton, [self nowTypeButtonItem], nil];
    self.packetQueue = [[IJTPacketQueue alloc] initQueue];
    
#pragma mark pass packet array to packet VC
    if(self.packetVC) {
        self.packetVC.packetQueueArray = [[NSMutableArray alloc] init];
        [self.packetVC startRecordType:self.nowType];
    }
    //set back
    [self initVC];
    //set start data
    self.totalBytes = self.totalCount = 0;
    self.startTime = [NSDate dateWithTimeIntervalSinceNow:0];
    self.startTimeLabel.text = [IJTFormatString formatDate:self.startTime];
    self.endTime = [NSDate dateWithTimeIntervalSinceNow:0];
    self.endTimeLabel.text = [IJTFormatString formatDate:self.endTime];
    self.durationTimeLabel.text =
    [IJTFormatString subtractStartDate:self.startTime endDate:self.endTime];
    self.countLabel.text = [IJTFormatString formatCount:0];
    self.bytesLabel.text = [IJTFormatString formatBytes:0 carry:YES];
    self.byteFlowLabel.text = [IJTFormatString formatFlowBytes:0 startDate:self.startTime endDate:self.endTime];
    self.countFlowLabel.text = [IJTFormatString formatFlowCount:0 startDate:self.startTime endDate:self.endTime];
    self.packetSizeLabel.text = [IJTFormatString formatPacketAverageBytes:0 count:0];
    self.flowGraphView.enableReferenceXAxisLines = NO;
    self.flowGraphView.enableReferenceYAxisLines = NO;
    
    [UIImageView animateWithDuration:1.0f
                               delay:0.0f
                             options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                          animations:^{
                              self.gestureImage.alpha = 0.0;
                          }
                          completion:^(BOOL finished){
                              self.gestureImage.alpha = 1.0;
                          }];
    
    //NSLog(@"Start record");
    
    //running in background
    UIApplication *application = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier task = [application beginBackgroundTaskWithExpirationHandler:^{
        [self stopRecord];
        self.startButton.enabled = YES;
        self.stopButton.enabled = YES;
    }];
    
    //grap packet
    [IJTDispatch dispatch_global:IJTDispatchPriorityHigh block:^{
        int status = pcap_loop(_pcap.handle, -1, pcaploop,
                               (__bridge void *)_packetQueue);
        if(-1 == status) {
            [IJTDispatch dispatch_main_after:DISPATCH_DELAY_TIME block:^{
                NSString *message = self.pcap.errorMessage;
                if(message.length > 0)
                    [self showErrorMessage:message];
            }];
            if(self.nowStatus == recording)
                [self stopAll];
            [self.packetQueue freeQueue];
        }
        else if(status == -2) {//set break loop
            //NSLog(@"set break loop");
            [self.packetQueue freeQueue];
        }
        
        [IJTDispatch dispatch_main_after:1.0f block:^{
            [self.pcap closeHandle];
            self.pcap = nil;
            self.startButton.enabled = YES;
            self.stopButton.enabled = YES;
        }];
        
        [application endBackgroundTask:task];
    }];
    
    //analyser packet
    [IJTDispatch dispatch_global:IJTDispatchPriorityDefault block:^{
        [self analyserPacket];
    }];
    
    //start reload thread
    self.reloadFlowGraphAndDataTimer =
    [NSTimer scheduledTimerWithTimeInterval:RELOADTIMER
                                     target:self
                                   selector:@selector(reloadFlowGraphAndData)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)reloadPacketVC {
    if(self.packetVC &&
       _packetQueueSizeTextField.text.length > 0 &&
       [IJTValueChecker checkAllDigit:_packetQueueSizeTextField.text] &&
       [self.packetQueueSizeTextField.text integerValue] > 0) {
        [self.packetVC loadCell];
    }
}

- (void)reloadFlowGraphAndData
{
    NSUInteger viewHeight = CGRectGetHeight(self.flowGraphScrollView.frame);
    NSUInteger viewWidth = self.flowGraphScrollView.contentSize.width;

    //no data, do no to expand
    if(self.reloadFlowGraphAndDataTimer &&
       !((self.flowGraphTypeSegmentedCtl.selectedSegmentIndex == 0 && self.flowGraphBytes.count <= 2) || (self.flowGraphTypeSegmentedCtl.selectedSegmentIndex == 1 && self.flowGraphCount.count <= 2)) &&
       (self.flowGraphBytes.count < MAXDATALEN || self.flowGraphCount.count < MAXDATALEN)) {
        double offset = IPHONE_EXPAND;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            offset = IPAD_EXPAND;
        viewWidth += SCREEN_WIDTH/offset;
        self.gestureImage.hidden = NO;
        [self.flowGraphUpperView setHidden:YES];
    }
    
    //new size
    self.flowGraphScrollView.contentSize = CGSizeMake(viewWidth, viewHeight);
    self.flowGraphView.frame = CGRectMake(0, 0, viewWidth, viewHeight - SCROLLVIEWOFFSET);
    
    //reload other data
    //time
    self.endTime = [NSDate dateWithTimeIntervalSinceNow:0];
    self.endTimeLabel.text = [IJTFormatString formatDate:self.endTime];
    self.durationTimeLabel.text =
    [IJTFormatString subtractStartDate:self.startTime endDate:self.endTime];
    //summary data
    self.countLabel.text = [IJTFormatString formatCount:self.totalCount];
    self.bytesLabel.text = [IJTFormatString formatBytes:self.totalBytes carry:YES];
    self.byteFlowLabel.text = [IJTFormatString formatFlowBytes:self.totalBytes
                                                     startDate:self.startTime
                                                       endDate:self.endTime];
    self.countFlowLabel.text = [IJTFormatString formatFlowCount:self.totalCount
                                                      startDate:self.startTime
                                                        endDate:self.endTime];
    self.packetSizeLabel.text = [IJTFormatString formatPacketAverageBytes:self.totalBytes count:self.totalCount];
    
    //[self.tableView reloadData];
    [self.flowGraphView reloadGraph];
    
    for(NSString *packet in self.packetType) {
        NSUInteger index = [self.packetType indexOfObject:packet];
        PNCircleChart *circleChart = [self.packetTypeCircleChart objectAtIndex:index];
        NSNumber *current = [self.packetTypeCount valueForKey:packet];
        if(self.totalCount != 0)
            [circleChart updateChartByCurrent:
             @(([current doubleValue]/self.totalCount)*100.)];
    }//end for
    
    double remainingTime =
    [[UIApplication sharedApplication] backgroundTimeRemaining];
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if(state == UIApplicationStateActive)
        self.alertRemaining = NO;
    else if((state == UIApplicationStateBackground ||
             state == UIApplicationStateInactive) &&
            !self.alertRemaining &&
            remainingTime < ALERTREMAININGTIME) {
        self.alertRemaining = YES;
        [IJTLocalNotification
         pushLocalNotificationMessage:
         [NSString stringWithFormat:@"Please back to injector, otherwise sniffing will be stopped in %d seconds", ALERTREMAININGTIME]
         title:@"Warning"
         info:nil];
    }
}

- (void) analyserPacket
{
    while(YES) {
        //keep data in a range
        if(self.flowGraphBytes.count > MAXDATALEN)
            [self.flowGraphBytes removeObjectAtIndex:0];
        
        if(self.flowGraphCount.count > MAXDATALEN)
            [self.flowGraphCount removeObjectAtIndex:0];
        
        if(self.flowGraphTimestamp.count > MAXDATALEN)
           [self.flowGraphTimestamp removeObjectAtIndex:0];
        
        NSUInteger bytes = 0;
        NSUInteger count = 0;
        time_t start = time(NULL);
        
        while(YES) {
            if(self.nowStatus == stopRecord) {
                //NSLog(@"stop analyser");
                return;
            }
            
            packet_t packet;
            if([self.packetQueue dequeuePacketHeader:&packet]) {//packet in
                count++;
                bytes += packet.header.caplen;
                self.totalBytes += packet.header.caplen;
                self.totalCount += 1;
                
                [self countPacket:packet];
            }
            else {//no packet
                [NSThread sleepForTimeInterval:0.01];
            }
            
            //time to flush
            if(difftime(time(NULL), start) > RELOADTIMER) {//wait secs
                [self.flowGraphBytes addObject:@(bytes)];
                [self.flowGraphCount addObject:@(count)];
                [self.flowGraphTimestamp addObject:[NSDate dateWithTimeIntervalSinceNow:0]];
                
                break;
            }
        }//end while sec
    }//end while analyser
}

/*from wireshark aftypes.h*/
#define BSD_AF_INET		2
#define BSD_AF_INET6_BSD	24	/* OpenBSD (and probably NetBSD), BSD/OS */
#define BSD_AF_INET6_FREEBSD	28
#define BSD_AF_INET6_DARWIN	30

#define ETHERTYPE_WOL 0x0842
#define ETHERTYPE_EAPOL 0x888e
- (void) countPacket: (packet_t)packet
{
    IJTPacketReader *reader = [[IJTPacketReader alloc] initWithPacket:packet type:self.nowType index:++_currentIndex];
    if(reader.layer2Type != IJTPacketReaderProtocolUnknown) {
        [self count:[IJTPacketReader protocol2PostString:reader.layer2Type]];
    }
    if(reader.layer3Type != IJTPacketReaderProtocolUnknown) {
        [self count:[IJTPacketReader protocol2PostString:reader.layer3Type]];
    }
    if(reader.layer4Type != IJTPacketReaderProtocolUnknown) {
        [self count:[IJTPacketReader protocol2PostString:reader.layer4Type]];
    }
    
#pragma mark store packet to packet VC queue
    if(self.packetVC &&
       _packetQueueSizeTextField.text.length > 0 &&
       [IJTValueChecker checkAllDigit:_packetQueueSizeTextField.text] &&
       [self.packetQueueSizeTextField.text integerValue] > 0) {
        NSMutableArray *array = self.packetVC.packetQueueArray;
        NSInteger queueSize = [self.packetQueueSizeTextField.text integerValue];
        while(array.count >= queueSize) {
            [array removeObjectAtIndex:0];
        }
        [array addObject:reader];
    }
}

- (void)count: (NSString *)key
{
    NSNumber *count = [self.packetTypeCount objectForKey:key];
    if(!count)
        count = @(0);
    count = @([count unsignedLongLongValue] + 1);
    [self.packetTypeCount setObject:count forKey:key];
}

void pcaploop(u_char *arg, const struct pcap_pkthdr *header, const u_char *content)
{
    IJTPacketQueue *packetQueue = (__bridge IJTPacketQueue *)(void *)arg;
    [packetQueue enqueuePacketHeader:header packetContent:content];
}

- (void)stopAll
{
    self.startButton.enabled = NO;
    self.stopButton.enabled = NO;
    [self.reloadFlowGraphAndDataTimer invalidate];
    self.reloadFlowGraphAndDataTimer = nil;
    [self.reloadPacketViewTimer invalidate];
    self.reloadPacketViewTimer = nil;
    
    if(self.packetVC) {
        [self reloadPacketVC];
        [self.packetVC stopRecord];
        [self.reloadPacketViewTimer invalidate];
        self.reloadPacketViewTimer = nil;
    }
    
    [NSThread sleepForTimeInterval:0.1];
    self.nowStatus = stopRecord;
    
    //flush data
    [self reloadFlowGraphAndData];
    
    if(self.supportWifi)
        [self.wifiButton setEnabled:YES];
    if(self.supportCellular)
        [self.cellButton setEnabled:YES];
    [self.promicsSwitch setEnabled:YES];
    [self.dismissButton setEnabled:YES];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView cellForRowAtIndexPath:indexPath].selectionStyle = UITableViewCellSelectionStyleDefault;
    
    if(((self.flowGraphTypeSegmentedCtl.selectedSegmentIndex == 0 && self.flowGraphBytes.count <= 2) || (self.flowGraphTypeSegmentedCtl.selectedSegmentIndex == 1 && self.flowGraphCount.count <= 2)) &&
    (self.flowGraphBytes.count < MAXDATALEN || self.flowGraphCount.count < MAXDATALEN))
        [self.flowGraphUpperView setHidden:NO];
    else
        [self.flowGraphUpperView setHidden:YES];
    
    [self.gestureImage removeFromSuperview];
    
    self.navigationItem.rightBarButtonItems =
    [NSArray arrayWithObjects:self.startButton, [self nowTypeButtonItem], nil];
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if(state != UIApplicationStateActive) {
        [IJTLocalNotification
         pushLocalNotificationMessage:
         [NSString stringWithFormat:@"Your sniffing is be terminated at %@", [IJTFormatString formatDate:[NSDate dateWithTimeIntervalSinceNow:0]]]
         title:@"Warning"
         info:nil];
    }
    //NSLog(@"Stop record");
    
    self.flowGraphView.enableReferenceXAxisLines = YES;
    self.flowGraphView.enableReferenceYAxisLines = YES;
}

- (void)stopRecord
{
    [self.pcap breakLoop];
    [self stopAll];
}

- (void)changeRecordType
{
    [self dismissKeyboard];
    if(self.nowType == IJTPacketReaderTypeCellular) {
        self.nowType = IJTPacketReaderTypeWiFi;
        self.navigationItem.rightBarButtonItems =
        [NSArray arrayWithObjects:self.startButton, self.cellButton, nil];
        self.navigationItem.title = @"Sniffer(Wi-Fi)";
        self.flowGraphView.colorTop = IJTWifiColor;
        self.flowGraphView.colorBottom = IJTWifiColor;
        self.flowGraphView.backgroundColor = IJTWifiColor;
    }
    else if(self.nowType == IJTPacketReaderTypeWiFi) {
        self.nowType = IJTPacketReaderTypeCellular;
        self.navigationItem.rightBarButtonItems =
        [NSArray arrayWithObjects:self.startButton, self.wifiButton, nil];
        self.navigationItem.title = @"Sniffer(Cellular)";
        self.flowGraphView.colorTop = IJTCellColor;
        self.flowGraphView.colorBottom = IJTCellColor;
        self.flowGraphView.backgroundColor = IJTCellColor;
    }
    
    if(self.packetVC) {
        [self.packetVC changeType:self.nowType];
    }
    
    if(self.nowType == IJTPacketReaderTypeWiFi) {
        if([self.wifiReachability currentReachabilityStatus] == NotReachable) {
            [self showWarningMessage:@"No Wi-Fi connection."];
        }
        else {
            if(![IJTPcap testPcapFilter:self.pcapFilterLabel.text interface:@"en0"]) {
                [self showWarningMessage:
                 [NSString stringWithFormat:@"Filter : %@",
                  [IJTPcap errorMessageFromErrorFilter:self.pcapFilterLabel.text
                                             interface:@"en0"]]];
            }
        }
    }
    else if(self.nowType == IJTPacketReaderTypeCellular) {
        if([self.cellReachability currentReachabilityStatus] == NotReachable) {
            [self showWarningMessage:@"No Cellular connection."];
        }
        else {
            if(![IJTPcap testPcapFilter:self.pcapFilterLabel.text interface:@"pdp_ip0"]) {
                [self showWarningMessage:
                 [NSString stringWithFormat:@"Filter : %@",
                  [IJTPcap errorMessageFromErrorFilter:self.pcapFilterLabel.text
                                             interface:@"pdp_ip0"]]];
            }
        }
    }
    
    [self initVC];
    
    if(self.supportWifi)
        [self updateInterfaceWithReachability:self.wifiReachability];
    if(self.supportCellular)
        [self updateInterfaceWithReachability:self.cellReachability];
}

- (UIBarButtonItem *)nowTypeButtonItem
{
    return [self.navigationItem.rightBarButtonItems count] > 1 ?
    [self.navigationItem.rightBarButtonItems objectAtIndex:1] : nil;
}

#pragma mark text field delegate

- (void)textFieldEditingChanged: (id)sender {
    FUITextField *textfield = sender;
    
    if(textfield == self.packetQueueSizeTextField &&
       [self.packetQueueSizeTextField.text intValue] > 5000) {
        [self showWarningMessage:[NSString stringWithFormat:@"%d may too large. It may cause Injector crash.", self.packetQueueSizeTextField.text.intValue]];
    }
    else if(textfield == self.reloadIntervalTextField) {
        if(self.reloadPacketViewTimer) {
            [self.reloadPacketViewTimer invalidate];
            self.reloadPacketViewTimer = nil;
        }
    }
}

- (void)textFieldEditingDidEnd: (id)sender {
    FUITextField *textfield = sender;
    if(textfield == self.reloadIntervalTextField &&
       [self.reloadIntervalTextField.text intValue] <= 0) {
        [self showWarningMessage:[NSString stringWithFormat:@"Packet view won\'t reload until you give it a number greater than 0."]];
        
        if(self.reloadPacketViewTimer) {
            [self.reloadPacketViewTimer invalidate];
            self.reloadPacketViewTimer = nil;
        }
        return;
    }
    
    if(self.packetVC && self.reloadPacketViewTimer == nil && [_reloadIntervalTextField.text longLongValue] > 0) {
        self.reloadPacketViewTimer =
        [NSTimer scheduledTimerWithTimeInterval:[_reloadIntervalTextField.text longLongValue] + 0.001
                                         target:self
                                       selector:@selector(reloadPacketVC)
                                       userInfo:nil
                                        repeats:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(self.packetQueueSizeTextField.isFirstResponder) {
        [self.reloadIntervalTextField becomeFirstResponder];
    }
    else if(self.reloadIntervalTextField.isFirstResponder) {
        [self.reloadIntervalTextField resignFirstResponder];
    }
    return NO;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *allowString = @"\b";
    
    if(textField == self.packetQueueSizeTextField || textField == self.reloadIntervalTextField) {
        allowString = @"1234567890\b";
    }
    else
        return YES;
    
    NSCharacterSet *allowCharSet =
    [[NSCharacterSet characterSetWithCharactersInString:allowString] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:allowCharSet] componentsJoinedByString:@""];
    return [string isEqualToString:filtered];
}

- (void)dismissKeyboard {
    if(self.packetQueueSizeTextField.isFirstResponder) {
        [self.packetQueueSizeTextField resignFirstResponder];
    }
    else if(self.reloadIntervalTextField.isFirstResponder) {
        [self.reloadIntervalTextField resignFirstResponder];
    }
}

#pragma mark Flow Graph

- (NSInteger)numberOfYAxisLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph {
    return 5;
}

- (NSInteger)numberOfGapsBetweenLabelsOnLineGraph:(BEMSimpleLineGraphView *)graph {
    return 0;
}

- (NSString *)lineGraph:(BEMSimpleLineGraphView *)graph labelOnXAxisForIndex:(NSInteger)index {
    NSMutableArray *data = nil;
    if(self.flowGraphTypeSegmentedCtl.selectedSegmentIndex == 0)
        data = self.flowGraphBytes;
    else
        data = self.flowGraphCount;
    NSInteger count = (NSInteger)data.count - 1 > 0 ? (NSInteger)data.count - 1 : 0;

    if(index == 0 || index == count - 1)
        return @"";
    return [IJTFormatString formatLabelOnXAxisForDate:self.flowGraphTimestamp[index]];
}

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph {
    NSMutableArray *data = nil;
    if(self.flowGraphTypeSegmentedCtl.selectedSegmentIndex == 0)
        data = self.flowGraphBytes;
    else
        data = self.flowGraphCount;
    
    return (NSInteger)data.count - 1 > 0 ? (NSInteger)data.count - 1 : 0;
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index {
    if(index == 0)
        index = 1;
    if(self.flowGraphTypeSegmentedCtl.selectedSegmentIndex == 0)
        return [[self.flowGraphBytes objectAtIndex:index] unsignedIntegerValue];
    else
        return [[self.flowGraphCount objectAtIndex:index] unsignedIntegerValue];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSUInteger viewHeight = CGRectGetHeight(self.flowGraphScrollView.frame);
    NSUInteger viewWidth = SCREEN_WIDTH - 16;

    self.gestureImage.frame =
    CGRectMake(self.flowGraphScrollView.contentOffset.x + viewWidth - SCROLLVIEWOFFSET, viewHeight - SCROLLVIEWOFFSET, SCROLLVIEWOFFSET, SCROLLVIEWOFFSET);
}

#pragma mark PassValue delegate
- (void)passValue:(id)value {
    self.pcapFilterLabel.text = value;
    [self.tableView reloadData];
}

#pragma mark Reachability
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    Reachability* curReach = [note object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    
    [self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    NSString *message =  [NSString stringWithFormat:@"No %@ connection. But it's still recording.", self.nowType == IJTPacketReaderTypeWiFi ? @"Wi-Fi" : @"Cellular"];
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    
    if(reachability == self.cellReachability && self.nowType == IJTPacketReaderTypeCellular) {
        switch ([reachability currentReachabilityStatus]) {
            case NotReachable:
                //[self.startButton setEnabled:NO];
                if(self.nowStatus == recording) {
                    //[self stopRecord];
                    if(state == UIApplicationStateBackground) {
                        [IJTLocalNotification pushLocalNotificationMessage:message title:@"Warning" info:nil];
                    }
                    else {
                        [self showWarningMessage:message];
                    }
                }
                break;
                
            case ReachableViaWiFi:
            case ReachableViaWWAN:
                //[self.startButton setEnabled:YES];
                break;
        }//end switch
    }//end if is cell
    else if(reachability == self.wifiReachability && self.nowType == IJTPacketReaderTypeWiFi) {
        switch ([reachability currentReachabilityStatus]) {
            case NotReachable:
                //[self.startButton setEnabled:NO];
                if(self.nowStatus == recording) {
                    //[self stopRecord];
                    if(state == UIApplicationStateBackground) {
                        [IJTLocalNotification pushLocalNotificationMessage:message title:@"Warning" info:nil];
                    }
                    else {
                        [self showWarningMessage:message];
                    }
                }
                break;
                
            case ReachableViaWiFi:
            case ReachableViaWWAN:
                //[self.startButton setEnabled:YES];
                break;
        }//end switch
    }//end if is wifi
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2;
        case 1: return 1;
        case 2: return 1;
        case 3: return 2;
        case 4: return 8;
        case 5: return 1;
        default: return 0;
    }
}

#pragma mark table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self dismissKeyboard];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 0 && indexPath.row == 0 && self.nowStatus == stopRecord) {
        IJTFilterTableViewController *filterVC = [self.storyboard instantiateViewControllerWithIdentifier:@"FilterVC"];
        filterVC.delegate = self;
        filterVC.pcapFilter = self.pcapFilterLabel.text;
        filterVC.nowType = self.nowType;
        [self.navigationController pushViewController:filterVC animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //packet type
    if(indexPath.section == 5 && indexPath.row == 0) {
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

#pragma mark Collection View
static NSString * const reuseIdentifier = @"PacketTypeCell";

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.packetType.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    
    //name label
    UILabel *name = (UILabel *)[cell viewWithTag:101];
    name.text = self.packetType[indexPath.row];
    name.textColor = IJTValueColor;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        name.font = [UIFont systemFontOfSize:9.5];
    else
        name.font = [UIFont systemFontOfSize:17];
    name.adjustsFontSizeToFitWidth = YES;
    
    //circle chart view
    UIView *chartview = (UIView *)[cell viewWithTag:100];
    //clear
    [[chartview subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [chartview addSubview:self.packetTypeCircleChart[indexPath.row]];
    
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma segmeted ctl
- (IBAction)flowGraphTypeSegmentedCtlValueChanged:(id)sender {
    [self.flowGraphView reloadGraph];
}

@end
