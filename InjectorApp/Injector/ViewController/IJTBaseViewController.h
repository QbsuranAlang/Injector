//
//  IJTBaseViewController.h
//  Injector
//
//  Created by 聲華 陳 on 2015/8/11.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IJTID.h"
#import "IJTWeb.h"
#import "IJTJson.h"
#import "IJTHTTP.h"
#import "IJTPcap.h"
#import "IJTColor.h"
#import "IJTStatus.h"
#import "IJTOpenSSL.h"
#import "IJTUIImage.h"
#import "IJTDispatch.h"
#import "IJTGradient.h"
#import "IJTDatabase.h"
#import "IJTTextField.h"
#import "IJTPickerView.h"
#import "IJTShowMessage.h"
#import "IJTPacketQueue.h"
#import "IJTMotionEffect.h"
#import "IJTFormatString.h"
#import "IJTValueChecker.h"
#import "IJTProgressView.h"
#import "IJTPacketReader.h"
#import "IJTNetowrkStatus.h"
#import "UIColor+Crayola.h"
#import "IJTAllowAndBlock.h"
#import "IJTFormatUILabel.h"
#import "UIDeviceHardware.h"
#import "SSARefreshControl.h"
#import "IJTFormatUITextView.h"
#import "UIImage+IJTImageText.h"
#import "IJTLocalNotification.h"
#import "IJTPassValueDelegate.h"
#import "JFMinimalNotification.h"
#import "IJTNotificationObserver.h"
#import "UIImage+IJTTintColorImage.h"
#import "UIImageView+IJTBlurImageView.h"


#import "IJTWOL.h"
#import "IJTDNS.h"
#import "IJTPing.h"
#import "IJTMDNS.h"
#import "IJTSSDP.h"
#import "IJTLLMNR.h"
#import "IJTWhois.h"
#import "IJTSysctl.h"
#import "IJTArping.h"
#import "IJTNetbios.h"
#import "IJTDNSpoof.h"
#import "IJTSSLScan.h"
#import "IJTUDP-Scan.h"
#import "IJTArp-scan.h"
#import "IJTIfconfig.h"
#import "IJTArptable.h"
#import "IJTFirewall.h"
#import "IJTACK-Scan.h"
#import "IJTSYN-Scan.h"
#import "IJTFIN-Scan.h"
#import "IJTArpoison.h"
#import "IJTNULL-Scan.h"
#import "IJTXmas-Scan.h"
#import "IJTTracepath.h"
#import "IJTHeartbleed.h"
#import "IJTShellshock.h"
#import "IJTRoutetable.h"
#import "IJTWANScanner.h"
#import "IJTHTTPSFisher.h"
#import "IJTWiFiScanner.h"
#import "IJTMaimon-Scan.h"
#import "IJTConnect-Scan.h"
#import "IJTTCP-Flooding.h"

#import <Canvas.h>
#import <PNChart.h>
#import <ALSystem.h>
#import <FlatUIKit.h>
#import <KVNProgress.h>
#import <CNPGridMenu.h>
#import <SCLAlertView.h>
#import <CZPickerView.h>
#import <JKBigInteger.h>
#import <Reachability.h>
#import <RNFrostedSidebar.h>
#import <AMWaveTransition.h>
#import <ASProgressPopUpView.h>
#import <SCLAlertViewStyleKit.h>
#import <BEMSimpleLineGraphView.h>
#import <HSDatePickerViewController.h>
#import <EBCardCollectionViewLayout.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>


#ifndef SCREEN_WIDTH
#define SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds)
#endif
#ifndef SCREEN_HEIGHT
#define SCREEN_HEIGHT CGRectGetHeight([UIScreen mainScreen].bounds)
#endif

#define GET_ARG_CELL \
IJTArgTableViewCell *cell = (IJTArgTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"ArgCell" forIndexPath:indexPath]; \
[[cell.controlView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)]; \
cell.controlView.backgroundColor = [UIColor clearColor] 

#define GET_EMPTY_CELL \
UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextFieldCell" forIndexPath:indexPath]; \
[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)]

@interface IJTBaseViewController : UITableViewController <UINavigationControllerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIBarButtonItem *multiToolButton;
@property (nonatomic, strong) UIBarButtonItem *dismissButton;
@property (nonatomic, strong) UIBarButtonItem *stopButton;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIBarButtonItem *popButton;
@property (nonatomic) BOOL fromLAN;
@property (nonatomic, strong) NSString *ipAddressFromLan;
@property (nonatomic, strong) NSString *macAddressFromLan;

+ (NSArray *)getSystemToolArray;
+ (NSArray *)getNetworkToolArray;
+ (NSArray *)getLANSupportToolArray;
+ (NSArray *)getAllToolSectionArray;


- (void)showInfoMessage: (NSString *)message;

- (void)showErrorMessage: (NSString *)message;

- (void)showWarningMessage: (NSString *)message;

- (void)showSuccessMessage: (NSString *)message;

- (void)showWiFiOnlyNoteWithToolName: (NSString *)toolName;

- (void)dismissShowMessage;



@end
