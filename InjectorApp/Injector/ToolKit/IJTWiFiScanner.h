//
//  IJTWiFiScanner.h
//  IJTWiFiScanner
//
//  Created by 聲華 陳 on 2015/11/5.
//
//

#import <Foundation/Foundation.h>

@interface IJTWiFiScanner : NSObject


- (id)init;
- (void)dealloc;

/**
 * Scan nearby network
 * @return nearby network list, wifi is disable then return nil
 */
- (NSArray *)scan;

/**
 * Get now networks
 * @param scan result
 */
- (NSArray *)networks;

/**
 * WiFi open or close
 * @return open or close
 */
- (BOOL)isWiFiEnabled;

/**
 * Open or close Wi-Fi
 * @param enabled enable or disable
 */
- (void)setWiFiEnabled:(BOOL)enabled;

/**
 * Get known network status
 * @return known network list
 */
- (NSArray *)getKnownNetworks;

/**
 * disassociate
 */
- (void)disassociate;

/**
 * Get Wi-Fi interface name
 * @return interface
 */
- (NSString *)interfaceName;

/**
 * Get current Wi-Fi
 * @param currentSSID SSID
 * @param BSSID BSSID
 */
- (void)currentSSID: (NSString **)SSID BSSID: (NSString **)BSSID;


/**
 * Remove known network list
 * @param SSID SSID
 * @param BSSID BSSID
 * @return success return YES, failure return NO
 */
- (BOOL)removeKnownNetworkSSID: (NSString *)SSID
                         BSSID: (NSString *)BSSID;


/**
 * Connect to network
 * @param associateWithSSID SSID
 * @param BSSID BSSID
 * @param username Username if needed
 * @param password Password if needed
 */
- (void)associateWithSSID: (NSString *)SSID
                    BSSID: (NSString *)BSSID
                 username: (NSString *)username
                 password: (NSString *)password;

@end
