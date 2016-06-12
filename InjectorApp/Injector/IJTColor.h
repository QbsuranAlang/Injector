//
//  IJTColor.h
//  Injector
//
//  Created by 聲華 陳 on 2015/3/2.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PNColor.h>
#import <UIColor+BFPaperColors.h>
#import <FlatUIKit.h>
#import <UIColor+Crayola.h>
@interface IJTColor : UIView

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 \
alpha:1.0]

/**
 * @param level 0-255
 */
+(UIColor *) darker: (UIColor *)color times:(double)times level:(NSUInteger)level;
+(UIColor *) darker: (UIColor *)color times:(double)times;
/**
 * @param level 0-255
 */
+(UIColor *) lighter: (UIColor *)color times:(double)times level:(NSUInteger)level;
+(UIColor *) lighter: (UIColor *)color times:(double)times;

+ (UIColor *)packetColor: (NSString *)packet;
#define IJTNavigationBarBackgroundColor [UIColor midnightBlueColor]

#define IJTWhiteColor [UIColor colorWithRed:.98 green:.98 blue:.98 alpha:1]

#define IJTIconWhiteColor [UIColor colorWithRed:235/255. green:235/255. blue:235/255. alpha:1]

#define IJTBlackColor [UIColor colorWithRed:51/255. green:51/255. blue:51/255. alpha:1]

#define IJTStartRecordColor [UIColor colorWithRed:237/255. green:31/255. blue:36/255. alpha:1]

#define IJTStopRecordColor IJTStartRecordColor

#define IJTCellColor [UIColor colorWithRed:243/255. green:229/255. blue:154/255. alpha:1]

#define IJTCellGraphFlowColor [UIColor paperColorOrange500]

#define IJTWifiColor [UIColor colorWithRed:159/255. green:224/255. blue:246/255. alpha:1]

#define IJTWifiFlowGraphColor [UIColor paperColorLightBlue500]

#define IJTTabBarBackgroundColor [UIColor paperColorGray900]

#define IJTTabBarTextColor [UIColor paperColorLime200]

#define IJTValueColor [IJTColor darker:[UIColor belizeHoleColor] times:2]

#define IJTDetectedDateColor [UIColor colorWithRed:0/255. green:171/255. blue:210/255. alpha:1]

#define IJTLightBlueColor [UIColor colorWithRed:219/255. green:234/255. blue:254/255. alpha:1]

#define IJTLoadColor [UIColor colorWithRed:218/255. green:67/255. blue:113/255. alpha:1]

#define IJTTableViewBackgroundColor [UIColor colorWithRed:239/255. green:239/255. blue:244/255. alpha:1]

#define IJTGrayColor [UIColor colorWithRed:.8 green:.8 blue:.8 alpha:1]

#define IJTLightGrayColor [UIColor colorWithRed:245/255. green:245/255. blue:245/255. alpha:1]

#define IJTOkColor [UIColor colorWithRed:205/255. green:235/255. blue:142/255. alpha:1]//[UIColor colorWithRed:178/255. green:252/255. blue:178/255. alpha:1]

#define IJTErrorColor [UIColor colorWithRed:304/255. green:179/255. blue:179/255. alpha:1]

#define IJTCollectionViewBackgroundColor [UIColor whiteColor]

#define IJTCollectionViewCellBackgroundColor [UIColor colorWithRed:240/255. green:240/255. blue:240/255. alpha:1]

//#define IJTLoopbackColor [UIColor colorWithRed:162/255. green:49/255. blue:105/255. alpha:1]

#define IJTTcpUdpColor [UIColor crayolaOrangeYellowColor]

#define IJTIcmpIgmpColor [UIColor crayolaEmeraldColor]

#define IJTOtherColor [UIColor crayolaGraniteGrayColor]

#define IJTDarkGreyColor [UIColor paperColorBlueGray900]

#define IJTArpColor [UIColor crayolaCherryColor]

#define IJTIpColor PNBlue

#define IJTOtherelseColor [UIColor crayolaBlueGreenColor]

#define IJTFlowColor [UIColor crayolaCherryColor]

#define IJTSnifferColor [UIColor crayolaBrightYellowColor]

#define IJTLANColor [UIColor crayolaSlimyGreenColor]

#define IJTToolsColor [UIColor crayolaCeruleanColor]

#define IJTFirewallColor [UIColor crayolaEggplantColor]

#define IJTSupportColor [UIColor crayolaOnyxColor]

#define IJTInjectorIconBackgroundColor [UIColor colorWithRed:48/255. green:162/255. blue:181/255. alpha:1]

#define IJTErrorMessageColor IJTFlowColor

@end
