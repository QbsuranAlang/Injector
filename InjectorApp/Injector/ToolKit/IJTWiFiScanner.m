//
//  IJTWiFiScanner.m
//  IJTWiFiScanner
//
//  Created by 聲華 陳 on 2015/11/5.
//
//

#import "IJTWiFiScanner.h"
#import <MobileWiFi.h>
#import <net/ethernet.h>
@interface IJTWiFiScanner ()

@property (nonatomic) WiFiManagerRef manager;
@property (nonatomic) WiFiDeviceClientRef client;
@property (nonatomic) WiFiNetworkRef currentNetwork;
@property (nonatomic, strong) NSMutableArray *networksObject;
@property (nonatomic, strong) NSMutableArray *scanNetworks;

@end

@implementation IJTWiFiScanner

- (id)init {
    self = [super init];
    if(self) {
#if !(TARGET_IPHONE_SIMULATOR)
        if(!getegid()) {
            _manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
            if(_manager) {
                CFArrayRef devices = WiFiManagerClientCopyDevices(_manager);
                if(devices) {
                    _client = (WiFiDeviceClientRef)CFArrayGetValueAtIndex(devices, 0);
                    CFRetain(_client);
                    CFRelease(devices);
                }
            }
        }//end if is root
#endif
    }
    
    return self;
}

- (void)dealloc {
#if !(TARGET_IPHONE_SIMULATOR)
    if(!getegid()) {
        if(_client) {
            CFRelease(_client);
        }
        if(_manager) {
            CFRelease(_manager);
        }
        if(_currentNetwork) {
            CFRelease(_currentNetwork);
        }
    }//end if is root
#endif
}

- (BOOL)isWiFiEnabled {
#if !(TARGET_IPHONE_SIMULATOR)
    if(getegid())
        return NO;
    
    CFPropertyListRef ref = WiFiManagerClientCopyProperty(_manager, CFSTR("AllowEnable"));
    NSNumber *enabled = (__bridge NSNumber *)ref;
    BOOL value = [enabled boolValue];
    
    CFRelease(ref);
    return value;
#endif
    return NO;
}

- (void)setWiFiEnabled:(BOOL)enabled {
#if !(TARGET_IPHONE_SIMULATOR)
    CFBooleanRef value = (enabled ? kCFBooleanTrue : kCFBooleanFalse);
    
    WiFiManagerClientSetProperty(_manager, CFSTR("AllowEnable"), value);
#endif
}

- (NSArray *)getKnownNetworks {
#if !(TARGET_IPHONE_SIMULATOR)
    if(getegid())
        return nil;
    
    CFArrayRef arr = WiFiManagerClientCopyNetworks(_manager);
    NSArray *list = (__bridge NSArray *)arr;
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    unsigned x;
    for (x = 0; x < [list count]; x++) {
        WiFiNetworkRef network = (__bridge WiFiNetworkRef)[list objectAtIndex:x];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        // SSID
        NSString *SSID = (__bridge NSString *)WiFiNetworkGetSSID(network);
        
        [dict setValue:SSID forKey:@"SSID"];
        
        // BSSID
        NSString *BSSID = (__bridge NSString *)WiFiNetworkGetProperty(network, CFSTR("BSSID"));
        BSSID = [IJTWiFiScanner formatBSSID:BSSID];
        
        [dict setValue:BSSID forKey:@"BSSID"];
        
        //password
        CFStringRef passwordRef = WiFiNetworkCopyPassword(network);
        NSString *password = (__bridge NSString *)passwordRef;
        if(password != nil && ![password isEqualToString:@""]) {
            [dict setValue:password forKey:@"Password"];
        }
        else {
            [dict setValue:@"" forKey:@"Password"];
        }
        if(passwordRef) {
            CFRelease(passwordRef);
        }
        
        [array addObject:dict];
    }
    
    CFRelease(arr);
    return array;
#endif
    return nil;
}

- (void)disassociate {
#if !(TARGET_IPHONE_SIMULATOR)
    WiFiDeviceClientDisassociate(_client);
#endif
}

- (NSString *)interfaceName {
#if !(TARGET_IPHONE_SIMULATOR)
    return (__bridge NSString *)WiFiDeviceClientGetInterfaceName(_client);
#endif
    return @"en0";
}

- (NSArray *)networks {
#if !(TARGET_IPHONE_SIMULATOR)
    for(NSMutableDictionary *dict in _scanNetworks) {
        [dict setValue:@(NO) forKey:@"IsCurrentNetwork"];
        
        if (_currentNetwork) {
            NSString *BSSID = [dict valueForKey:@"BSSID"];
            NSString *networkBSSID = (__bridge NSString *)WiFiNetworkGetProperty(_currentNetwork, CFSTR("BSSID"));
            networkBSSID = [IJTWiFiScanner formatBSSID:networkBSSID];
            if([BSSID isEqualToString:networkBSSID]) {
                [dict setValue:@(YES) forKey:@"IsCurrentNetwork"];
            }
        }
    }
    
    for(int i = 0 ; i < [_scanNetworks count] ; i++) {
        NSDictionary *dict = [_scanNetworks objectAtIndex:i];
        if([[dict valueForKey:@"IsCurrentNetwork"] boolValue]) {
            [_scanNetworks exchangeObjectAtIndex:i withObjectAtIndex:0];
            break;
        }
    }
    
    [self reloadCurrentNetwork];
    return _scanNetworks;
#endif
    return nil;
}

- (void)associateWithSSID: (NSString *)SSID
                    BSSID: (NSString *)BSSID
                 username: (NSString *)username
                 password: (NSString *)password {
#if !(TARGET_IPHONE_SIMULATOR)
    NSString *currentSSID = @"";
    NSString *currentBSSID = @"";
    BSSID = [IJTWiFiScanner formatBSSID:BSSID];
    
    [self currentSSID:&currentSSID BSSID: &currentBSSID];
    
    if([currentBSSID isEqualToString:BSSID]) {
        return;
    }
    if(_networksObject.count == 0)
        return;
    
    unsigned x;
    WiFiNetworkRef network = NULL;
    int found = 0;
    for (x = 0; x < [_networksObject count]; x++) {
        
        network = (__bridge WiFiNetworkRef)[_networksObject objectAtIndex:x];
        
        // BSSID
        NSString *networkBSSID = (__bridge NSString *)WiFiNetworkGetProperty(network, CFSTR("BSSID"));
        networkBSSID = [IJTWiFiScanner formatBSSID:networkBSSID];

        if([networkBSSID isEqualToString:BSSID]) {
            found = 1;
            break;
        }
    }//end if
    
    if(!found)
        return;
    WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    
    if(password.length > 0) {
        WiFiNetworkSetPassword(network, (__bridge CFStringRef)password);
    }
    
    WiFiDeviceClientAssociateAsync(_client, network, associationCallback, (__bridge void *)_scanNetworks);
    CFRunLoopRun();
#endif
}

- (void)currentSSID: (NSString **)SSID BSSID: (NSString **)BSSID {
#if !(TARGET_IPHONE_SIMULATOR)
    *SSID = @"";
    *BSSID = @"";
    
    if(![self isWiFiEnabled])
        return;
    
    [self reloadCurrentNetwork];
    if(_currentNetwork) {
        // SSID
        *SSID = (__bridge NSString *)WiFiNetworkGetSSID(_currentNetwork);
        
        // BSSID
        *BSSID = (__bridge NSString *)WiFiNetworkGetProperty(_currentNetwork, CFSTR("BSSID"));
        *BSSID = [IJTWiFiScanner formatBSSID: *BSSID];
    }
#endif
}

- (BOOL)removeKnownNetworkSSID: (NSString *)SSID
                         BSSID: (NSString *)BSSID {
#if !(TARGET_IPHONE_SIMULATOR)
    CFArrayRef arr = WiFiManagerClientCopyNetworks(_manager);
    NSArray *knownList = (__bridge NSArray *)arr;
    
    BSSID = [IJTWiFiScanner formatBSSID:BSSID];
    
    unsigned x;
    int found = 0;
    for (x = 0; x < [knownList count]; x++) {
        WiFiNetworkRef network = (__bridge WiFiNetworkRef)[knownList objectAtIndex:x];
        
        NSString *networkSSID = (__bridge NSString *)WiFiNetworkGetSSID(network);
        
        // BSSID
        NSString *networkBSSID = (__bridge NSString *)WiFiNetworkGetProperty(network, CFSTR("BSSID"));
        networkBSSID = [IJTWiFiScanner formatBSSID:networkBSSID];
        
        if([SSID isEqualToString:networkSSID] && [BSSID isEqualToString:networkBSSID]) {
            WiFiManagerClientRemoveNetwork(_manager, network);
            found = 1;
            break;
        }
    }//end for
    CFRelease(arr);
    return found;
#endif
    return NO;
}

- (NSArray *)scan {
#if !(TARGET_IPHONE_SIMULATOR)
    if(![self isWiFiEnabled])
        return nil;
    
    self.networksObject = [[NSMutableArray alloc] init];
    self.scanNetworks = [[NSMutableArray alloc] init];
    
    [self reloadCurrentNetwork];
    WiFiManagerClientScheduleWithRunLoop(_manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    WiFiDeviceClientScanAsync(_client,
                              (__bridge CFDictionaryRef)[NSDictionary dictionary],
                              scan_callback,
                              (__bridge void *)_networksObject);
    CFRunLoopRun();
    
    for(id networkObject in _networksObject) {
        WiFiNetworkRef network = (__bridge WiFiNetworkRef)networkObject;
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        // SSID
        NSString *SSID = (__bridge NSString *)WiFiNetworkGetSSID(network);
        
        [dict setValue:SSID forKey:@"SSID"];
        
        
        // RSSI & bars.
        CFNumberRef RSSI = (CFNumberRef)WiFiNetworkGetProperty(network, CFSTR("RSSI"));
        float strength;
        CFNumberGetValue(RSSI, kCFNumberFloatType, &strength);
        
        [dict setValue:@(strength) forKey:@"RSSI"];
        
        CFNumberRef gradedRSSI = (CFNumberRef)WiFiNetworkGetProperty(network, kWiFiScaledRSSIKey);
        float graded;
        CFNumberGetValue(gradedRSSI, kCFNumberFloatType, &graded);
        
        int bars = (int)ceilf((graded * -1.0f) * -3.0f);
        bars = MAX(1, MIN(bars, 3));
        
        [dict setValue:@(bars) forKey:@"Bars"];
        
        
        // Encryption model
        if (WiFiNetworkIsWEP(network))
            [dict setValue:@"WEP" forKey:@"Encryption Model"];
        else if (WiFiNetworkIsWPA(network))
            [dict setValue:@"WPA" forKey:@"Encryption Model"];
        else if (WiFiNetworkIsEAP(network))
            [dict setValue:@"EAP" forKey:@"Encryption Model"];
        else
            [dict setValue:@"None" forKey:@"Encryption Model"];
        
        
        // Channel
        CFNumberRef networkChannel = (CFNumberRef)WiFiNetworkGetProperty(network, CFSTR("CHANNEL"));
        
        int channel;
        CFNumberGetValue(networkChannel, kCFNumberIntType, &channel);
        
        [dict setValue:@(channel) forKey:@"Channel"];
        
        
        // Apple Hotspot
        BOOL isAppleHotspot = WiFiNetworkIsApplePersonalHotspot(network);
        [dict setValue:@(isAppleHotspot) forKey:@"Apple Hotspot"];
        
        
        // BSSID
        NSString *BSSID = (__bridge NSString *)WiFiNetworkGetProperty(network, CFSTR("BSSID"));
        BSSID = [IJTWiFiScanner formatBSSID:BSSID];
        
        [dict setValue:BSSID forKey:@"BSSID"];
        
        
        // AdHoc
        BOOL isAdHoc = WiFiNetworkIsAdHoc(network);
        [dict setValue:@(isAdHoc) forKey:@"Ad Hoc"];
        
        
        // Hidden
        BOOL isHidden = WiFiNetworkIsHidden(network);
        [dict setValue:@(isHidden) forKey:@"Hidden"];
        
        
        // AP Mode
        int APMode = [(__bridge NSNumber *)WiFiNetworkGetProperty(network, CFSTR("AP_MODE")) intValue];
        [dict setValue:@(APMode) forKey:@"AP Mode"];
        
        
        // Record
        CFDictionaryRef recordRef = WiFiNetworkCopyRecord(network);
        NSDictionary *record = (__bridge NSDictionary *)recordRef;
        NSMutableDictionary *recordDict = [[NSMutableDictionary alloc] initWithDictionary:record];
        BSSID = [IJTWiFiScanner formatBSSID:BSSID];
        [recordDict setValue:BSSID forKey:@"BSSID"];
        /*
        NSArray *keys = [recordDict allKeys];
        for(int i = 0 ; i < [keys count] ; i++) {
            NSString *key = [keys objectAtIndex:i];
            id object = [recordDict valueForKey:key];
            NSLog(@"%@ %@", key, [object class]);
            NSString *value = [IJTWiFiScanner formattedSmallData:object];
            if(value != nil) {
                //[recordDict setObject:value forKey:key];
            }
        }*/
        
        [dict setValue:recordDict forKey:@"Record"];
        
        CFRelease(recordRef);
        //[record release];
        
        
        // Requires username
        BOOL requiresUsername = WiFiNetworkRequiresUsername(network);
        [dict setValue:@(requiresUsername) forKey:@"Requires Username"];
        
        
        // Requires password
        BOOL requiresPassword = WiFiNetworkRequiresPassword(network);
        [dict setValue:@(requiresPassword) forKey:@"Requires Password"];
        
        
        [dict setValue:@(NO) forKey:@"IsCurrentNetwork"];
        
        if(_currentNetwork) {
            if([BSSID isEqualToString:[IJTWiFiScanner formatBSSID:(__bridge NSString *)WiFiNetworkGetProperty(_currentNetwork, CFSTR("BSSID"))]]) {
                
                [dict setValue:@(YES) forKey:@"IsCurrentNetwork"];
            }
        }//end current network
        
        [self.scanNetworks addObject:dict];
    }
    
    for(int i = 0 ; i < [_scanNetworks count] ; i++) {
        NSDictionary *dict = [_scanNetworks objectAtIndex:i];
        if([[dict valueForKey:@"IsCurrentNetwork"] boolValue]) {
            [_scanNetworks exchangeObjectAtIndex:i withObjectAtIndex:0];
            break;
        }
    }
    
    
    return _scanNetworks;
#endif
    return nil;
}


#pragma mark private
#if !(TARGET_IPHONE_SIMULATOR)
static void scan_callback(WiFiDeviceClientRef device, CFArrayRef results, int error, const void *object)
{
    NSMutableArray *list = (__bridge NSMutableArray *)object;
    
    if(results) {
        unsigned x;
        CFIndex count = CFArrayGetCount(results);
        for (x = 0; x < count; x++) {
            WiFiNetworkRef network = (WiFiNetworkRef)CFArrayGetValueAtIndex(results, x);
            [list addObject:(__bridge id)(network)];
        }
    }
    
    CFRunLoopStop(CFRunLoopGetCurrent());
}

static void associationCallback(WiFiDeviceClientRef device, WiFiNetworkRef networkRef, CFDictionaryRef dict, int error, const void *object)
{
    NSMutableArray *list = (__bridge NSMutableArray *)object;
    
    for(NSMutableDictionary *dict in list) {
        [dict setValue:@(NO) forKey:@"IsCurrentNetwork"];
        
        if (networkRef) {
            NSString *BSSID = [dict valueForKey:@"BSSID"];
            NSString *networkBSSID = (__bridge NSString *)WiFiNetworkGetProperty(networkRef, CFSTR("BSSID"));
            networkBSSID = [IJTWiFiScanner formatBSSID:networkBSSID];
            if([BSSID isEqualToString:networkBSSID]) {
                [dict setValue:@(YES) forKey:@"IsCurrentNetwork"];
            }
        }
    }
    
    for(int i = 0 ; i < [list count] ; i++) {
        NSDictionary *dict = [list objectAtIndex:i];
        if([[dict valueForKey:@"IsCurrentNetwork"] boolValue]) {
            [list exchangeObjectAtIndex:i withObjectAtIndex:0];
            break;
        }
    }
    
    CFRunLoopStop(CFRunLoopGetCurrent());
}
#endif

- (void)reloadCurrentNetwork
{
#if !(TARGET_IPHONE_SIMULATOR)
    if (_currentNetwork) {
        CFRelease(_currentNetwork);
        _currentNetwork = nil;
    }
    
    _currentNetwork = WiFiDeviceClientCopyCurrentNetwork(_client);
#endif
}

+ (NSString *)formattedSmallData: (id)data
{
    if ([data isKindOfClass:[NSString class]]) {
        return data;
    } else if ([data isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)data stringValue];
    } else if ([data isKindOfClass:[NSData class]]) {
        NSString *string = nil;
        if ((string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]))
            return string;
        else
            return [data description];
    } else {
        return nil;
    }
}

+ (NSString *)formatBSSID: (NSString *)BSSID {
    if(BSSID == nil)
        return @"";
    
    NSString *formatedBSSID = [NSString stringWithString:BSSID];
    if(BSSID != nil && ![BSSID isEqualToString:@""]) {
        struct ether_addr *addr =  ether_aton([BSSID UTF8String]);
        formatedBSSID = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", addr->octet[0], addr->octet[1], addr->octet[2], addr->octet[3], addr->octet[4], addr->octet[5]];
    }
    return formatedBSSID;
}

@end