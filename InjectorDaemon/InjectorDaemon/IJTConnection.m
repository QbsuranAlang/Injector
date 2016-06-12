//
//  IJTConnection.m
//  InjectorDaemon
//
//  Created by 聲華 陳 on 2015/9/17.
//
//

#import "IJTConnection.h"
#import "Reachability.h"
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "IJTRoutetable.h"
#import "IJTHTTP.h"
#import <fcntl.h>
#import "IJTJson.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <sys/socket.h>
#import <net/ethernet.h>
#import <dlfcn.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <sys/ioctl.h>

@interface IJTConnection ()

@property (nonatomic, strong) Reachability *wifiReachability;
@property (nonatomic, strong) Reachability *cellReachability;
@property (nonatomic, strong) NSString *supportWiFi;
@property (nonatomic, strong) NSString *supportCellular;
@property (nonatomic) BOOL gettingData;

@end
@implementation IJTConnection

- (id)init {
    self = [super init];
    if(self) {
        _supportCellular = @"f";
        _supportWiFi = @"f";
        _gettingData = NO;
    }
    return self;
}

static BOOL checkInterface(NSString *interface)
{
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    BOOL support = NO;
    
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr) {
            if(!strcmp(temp_addr->ifa_name, (const char *)[interface UTF8String])) {
                support = YES;
                break;
            }//end if found
            temp_addr = temp_addr->ifa_next;
        }//end while
        freeifaddrs(interfaces);
    }//end if
    return support;
}

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    if(checkInterface(@"en0")) {
        self.wifiReachability = [Reachability reachabilityForLocalWiFi];
        [self.wifiReachability startNotifier];
        _supportWiFi = @"t";
    }
    if(checkInterface(@"pdp_ip0")) {
        self.cellReachability = [Reachability reachabilityForInternetConnection];
        [self.cellReachability startNotifier];
        _supportCellular = @"t";
    }
    [self reachabilityChanged:nil];
}

- (void)dealloc {
    [self.wifiReachability stopNotifier];
    [self.cellReachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) reachabilityChanged:(NSNotification *)note {
    if(_gettingData)
        return;
    _gettingData = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"Getting connection data...");
        NSMutableArray *gateways = [[NSMutableArray alloc] init];
        IJTRoutetable *route = [[IJTRoutetable alloc] init];
        [route getAllEntriesSkipHostname:YES
                                  target:self
                                selector:ROUTETABLE_SHOW_CALLBACK_SEL
                                  object:gateways];
        [route close];
        
        if(gateways.count <= 0)
            [gateways addObject:@"0.0.0.0"];
        
        NSString *currentIPAddress = [IJTConnection currentIPAddress];
        NSMutableDictionary *connectionDict = [[NSMutableDictionary alloc] init];
        [connectionDict setValue:[gateways firstObject] forKey:@"Gateway"];
        [connectionDict setValue:currentIPAddress forKey:@"CurrentIpAddress"];
        NSMutableDictionary *wifiDataDict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *cellularDataDict = [[NSMutableDictionary alloc] init];
        
        
        if([_supportWiFi isEqualToString:@"t"]) {
            if(self.wifiReachability.currentReachabilityStatus != NotReachable) {
                [wifiDataDict setValue:@"Yes" forKey:@"Connected"];
            }
            else {
                [wifiDataDict setValue:@"No" forKey:@"Connected"];
            }
            [wifiDataDict setValue:[IJTConnection currentIPAddress:@"en0"] forKey:@"IpAddress"];
            [wifiDataDict setValue:[IJTConnection wifiMacAddress] forKey:@"MacAddress"];
            [wifiDataDict setValue:[IJTConnection BSSID] forKey:@"BSSID"];
            [wifiDataDict setValue:[IJTConnection SSID] forKey:@"SSID"];
            [wifiDataDict setValue:[IJTConnection oui:[IJTConnection BSSID]] forKey:@"OUI"];
            [wifiDataDict setValue:[IJTConnection WiFiNetmaskAddress] forKey:@"NetmaskAddress"];
            [wifiDataDict setValue:[IJTConnection WiFiBroadcastAddress] forKey:@"BroadcastAddress"];
        }
        if([_supportCellular isEqualToString:@"t"]) {
            if(self.cellReachability.currentReachabilityStatus != NotReachable) {
                [cellularDataDict setValue:@"Yes" forKey:@"Connected"];
            }
            else {
                [cellularDataDict setValue:@"No" forKey:@"Connected"];
            }
            [cellularDataDict setValue:[IJTConnection currentIPAddress:@"pdp_ip0"] forKey:@"IpAddress"];
            [cellularDataDict setValue:[IJTConnection carrierName] forKey:@"CarrierName"];
            [cellularDataDict setValue:[IJTConnection carrierISOCountryCode] forKey:@"ISOCountryCode"];
        }
        
        NSString *post = [NSString stringWithFormat:@"SerialNumber=%@&Connection=%@&SupportWiFi=%@&SupportCellular=%@&WiFiData=%@&CellularData=%@",
                          serialNumber(), [IJTHTTP string2post:[IJTJson dictionary2sting:connectionDict prettyPrint:YES]],
                          _supportWiFi, _supportCellular,
                          [IJTHTTP string2post:[IJTJson dictionary2sting:wifiDataDict prettyPrint:YES]],
                          [IJTHTTP string2post:[IJTJson dictionary2sting:cellularDataDict prettyPrint:YES]]];
        NSString *result = [IJTHTTP retrieveFrom:@"UserNetworkConnection.php"
                                            post:post
                                         timeout:5];
        NSLog(@"%@", result);
        
        _gettingData = NO;
    });
}

ROUTETABLE_SHOW_CALLBACK_METHOD {
    NSMutableArray *list = (NSMutableArray *)object;
    [list addObject:gateway];
}

+ (NSString *)WiFiNetmaskAddress {
    // Set up the variable
    struct ifreq afr;
    // Copy the string
    strncpy(afr.ifr_name, [@"en0" UTF8String], IFNAMSIZ-1);
    // Open a socket
    int afd = socket(AF_INET, SOCK_DGRAM, 0);
    
    // Check the socket
    if (afd == -1) {
        // Error, socket failed to open
        return @"0.0.0.0";
    }
    
    // Check the netmask output
    if (ioctl(afd, SIOCGIFNETMASK, &afr) == -1) {
        // Error, netmask wasn't found
        // Close the socket
        close(afd);
        // Return error
        return @"0.0.0.0";
    }
    
    // Close the socket
    close(afd);
    
    // Create a char for the netmask
    char *netstring = inet_ntoa(((struct sockaddr_in *)&afr.ifr_addr)->sin_addr);
    
    // Create a string for the netmask
    NSString *Netmask = [NSString stringWithUTF8String:netstring];
    
    // Check to make sure it's not nil
    if (Netmask == nil || Netmask.length <= 0) {
        // Error, netmask not found
        return @"0.0.0.0";
    }
    
    // Return successful
    return Netmask;
}

+ (NSString *)WiFiBroadcastAddress {
    // Set up strings for the IP and Netmask
    NSString *IPAddress = [self currentIPAddress];
    NSString *NMAddress = [self WiFiNetmaskAddress];
    
    // Check to make sure they aren't nil
    if (IPAddress == nil || IPAddress.length <= 0) {
        // Error, IP Address can't be nil
        return @"0.0.0.0";
    }
    if (NMAddress == nil || NMAddress.length <= 0) {
        // Error, NM Address can't be nil
        return @"0.0.0.0";
    }
    
    // Check the formatting of the IP and NM Addresses
    NSArray *IPCheck = [IPAddress componentsSeparatedByString:@"."];
    NSArray *NMCheck = [NMAddress componentsSeparatedByString:@"."];
    
    // Make sure the IP and NM Addresses are correct
    if (IPCheck.count != 4 || NMCheck.count != 4) {
        // Incorrect IP Addresses
        return @"0.0.0.0";
    }
    
    // Set up the variables
    NSUInteger IP = 0;
    NSUInteger NM = 0;
    NSUInteger CS = 24;
    
    // Make the address based on the other addresses
    for (NSUInteger i = 0; i < 4; i++, CS -= 8) {
        IP |= [[IPCheck objectAtIndex:i] intValue] << CS;
        NM |= [[NMCheck objectAtIndex:i] intValue] << CS;
    }
    
    // Set it equal to the formatted raw addresses
    NSUInteger BA = ~NM | IP;
    
    // Make a string for the address
    NSString *BroadcastAddress = [NSString stringWithFormat:@"%d.%d.%d.%d", (BA & 0xFF000000) >> 24,
                                  (BA & 0x00FF0000) >> 16, (BA & 0x0000FF00) >> 8, BA & 0x000000FF];
    
    // Check to make sure the string is valid
    if (BroadcastAddress == nil || BroadcastAddress.length <= 0) {
        // Error, no address
        return @"0.0.0.0";
    }
    
    // Return Successful
    return BroadcastAddress;
}

+ (NSString *)oui: (NSString *)macAddress {
    
    NSString *path = @"/Applications/Injector.app/oui.json";
    
    NSDictionary *ouiDatabase = [IJTJson file2dictionary:path];
    NSDictionary *list = [ouiDatabase valueForKey:@"db"];
    struct ether_addr *ether = ether_aton([macAddress UTF8String]);
    NSString *oui = nil;
    if(ether == NULL)
        return @"Unknown";
    
    macAddress = [NSString stringWithFormat:@"%02X%02X%02X", ether->octet[0], ether->octet[1], ether->octet[2]];
    
    oui = [list valueForKey:macAddress];
    return oui == nil ? @"Unknown" : oui;
}

+ (NSString *)BSSID {
    /*! Get the interfaces */
    NSArray *interfaces = (__bridge NSArray *) CNCopySupportedInterfaces();
    NSString *BSSID = @"00:00:00:00:00:00";
    
    /*! Cycle interfaces */
    for (NSString *interface in interfaces)
    {
        CFDictionaryRef networkDetails = CNCopyCurrentNetworkInfo((__bridge CFStringRef) interface);
        if (networkDetails)
        {
            BSSID = (NSString *)CFDictionaryGetValue(networkDetails, kCNNetworkInfoKeyBSSID);
            CFRelease(networkDetails);
        }
    }
    return BSSID;
}

+ (NSString *)SSID {
    /*! Get the interfaces */
    NSArray *interfaces = (__bridge NSArray *) CNCopySupportedInterfaces();
    NSString *SSID = @"";
    
    /*! Cycle interfaces */
    for (NSString *interface in interfaces)
    {
        CFDictionaryRef networkDetails = CNCopyCurrentNetworkInfo((__bridge CFStringRef) interface);
        if (networkDetails)
        {
            SSID = (NSString *)CFDictionaryGetValue(networkDetails, kCNNetworkInfoKeySSID);
            CFRelease(networkDetails);
        }
    }
    return SSID;
}

+ (NSString *)carrierName {
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    return [carrier carrierName];
}

+ (NSString *)carrierISOCountryCode {
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [netinfo subscriberCellularProvider];
    return [carrier isoCountryCode];
}

+ (NSString *)currentIPAddress: (NSString *)interface {
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *address = @"0.0.0.0";
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if(sa_type == AF_INET) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                //NSLog(@"NAME: \"%@\" addr: %@", name, addr); // see for yourself
                
                if([name isEqualToString:interface]) {
                    // Interface is the wifi connection on the iPhone
                    address = addr;
                    break;
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    
    if(address == nil)
        errno = EFAULT; /* Bad address */
    
    return address;
}

+ (NSString *)wifiMacAddress {
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    
    if(geteuid())
        return @"d8:bb:2c:cc:16:ab";
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        return nil;
    
    if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
        return nil;
    
    if ((msgBuffer = malloc(length)) == NULL)
        return nil;
    // Get system information, store in buffer
    if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0) {
        free(msgBuffer);
        return nil;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithUTF8String:ether_ntoa((const struct ether_addr *)macAddress)];
    //NSLog(@"Mac Address: %@", macAddressString);
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

// This code is an answer to
// this question :
// http://stackoverflow.com/questions/7072989/iphone-ipad-how-to-get-my-ip-address-programmatically
// by David H
+ (NSString *)currentIPAddress {
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *wifiAddress = nil;
    NSString *cellAddress = nil;
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            if(sa_type == AF_INET) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                //NSLog(@"NAME: \"%@\" addr: %@", name, addr); // see for yourself
                
                if([name isEqualToString:@"en0"])
                    // Interface is the wifi connection on the iPhone
                    wifiAddress = addr;
                else
                    if([name isEqualToString:@"pdp_ip0"])
                        // Interface is the cell connection on the iPhone
                        cellAddress = addr;
                
            }
            temp_addr = temp_addr->ifa_next;
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    
    NSString *addr = wifiAddress ? wifiAddress : cellAddress;
    return addr ? addr : @"0.0.0.0";
}

+ (BOOL)connectedViaWiFi {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == ReachableViaWiFi)
        return YES;
    else
        return NO;
}

+ (BOOL)connectedVia3G {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    NetworkStatus status = [reachability currentReachabilityStatus];
    if (status == ReachableViaWWAN)
        return YES;
    else
        return NO;
}

static NSString *serialNumber()
{
    NSString *sn = nil;
    
    void *IOKit = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    if (IOKit)
    {
        mach_port_t *kIOMasterPortDefault = dlsym(IOKit, "kIOMasterPortDefault");
        CFMutableDictionaryRef (*IOServiceMatching)(const char *name) = dlsym(IOKit, "IOServiceMatching");
        mach_port_t (*IOServiceGetMatchingService)(mach_port_t masterPort, CFDictionaryRef matching) = dlsym(IOKit, "IOServiceGetMatchingService");
        CFTypeRef (*IORegistryEntryCreateCFProperty)(mach_port_t entry, CFStringRef key, CFAllocatorRef allocator, uint32_t options) = dlsym(IOKit, "IORegistryEntryCreateCFProperty");
        kern_return_t (*IOObjectRelease)(mach_port_t object) = dlsym(IOKit, "IOObjectRelease");
        
        if (kIOMasterPortDefault && IOServiceGetMatchingService && IORegistryEntryCreateCFProperty && IOObjectRelease)
        {
            mach_port_t platformExpertDevice = IOServiceGetMatchingService(*kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
            if (platformExpertDevice)
            {
                CFTypeRef platformSerialNumber = IORegistryEntryCreateCFProperty(platformExpertDevice, CFSTR("IOPlatformSerialNumber"), kCFAllocatorDefault, 0);
                if (CFGetTypeID(platformSerialNumber) == CFStringGetTypeID())
                {
                    sn = [NSString stringWithString:(__bridge NSString*)platformSerialNumber];
                    CFRelease(platformSerialNumber);
                }
                IOObjectRelease(platformExpertDevice);
            }
        }
        dlclose(IOKit);
    }
    
    return sn;
}

@end
