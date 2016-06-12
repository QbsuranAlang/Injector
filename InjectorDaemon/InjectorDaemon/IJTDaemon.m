//
//  IJTDaemon.m
//  InjectorDaemon
//
//  Created by 聲華 陳 on 2015/4/12.
//
//

#import "IJTDaemon.h"
#import "IJTDatabase.h"
//#import <libnet.h>
#import <CFUserNotification.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <Reachability.h>
#import <IJTFirewall.h>
#import <ifaddrs.h>
#import "IJTPacketReader.h"
#import "IJTArptable.h"
#import "IJTRoutetable.h"
#import "IJTConnection.h"
#define DETECT_URL "https://nrl.cce.mcu.edu.tw/injector/dbAccess/ReceiveDetectEvent.php"
#define FOREGROUNDAPP_URL "https://nrl.cce.mcu.edu.tw/injector/dbAccess/ReceiveForegroundApp.php"
#define PREFERENCELOADER @"/var/mobile/Library/Preferences/tw.edu.mcu.cce.nrl.InjectorPreferenceLoader.plist"
#define PREFERENCELOADER_DEFAULT @"/Library/PreferenceBundles/InjectorPreferenceLoader.bundle/InjectorPreferenceLoader.plist"
#define TIMEOUT_TIMES 500
@interface IJTDaemon ()

@property (nonatomic) time_t starttime;
@property (nonatomic) time_t endtime;
@property (nonatomic) NSUInteger packetcount;
@property (nonatomic) NSUInteger packetbytes;
@property (nonatomic, strong) NSString *device;
@property (nonatomic) IJTPacketReaderType type;
@property (nonatomic) pcap_t *pcaphandle;
@property (nonatomic) CURL *curlhandle;
@property (nonatomic, strong) NSString *sn;
@property (nonatomic, strong) NSArray *database;
@property (nonatomic, strong) NSArray *packetType;
@property (nonatomic, strong) NSMutableDictionary *packetTypeCount;

@property (nonatomic, strong) Reachability *wifiReachability;

@property (nonatomic) BOOL arpdefenderNotification;

@end

@implementation IJTDaemon

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

- (void)openPcap {
    
    self.pcaphandle = NULL;
    
    char errbuf[PCAP_ERRBUF_SIZE];
    self.pcaphandle = pcap_open_live([self.device UTF8String], IP_MAXPACKET, 0, 1, errbuf);
    if(!self.pcaphandle) {
        printf("%s: %s\n", [self.device UTF8String], errbuf);
        goto BAD;
    }//end if
    
    self.ok = YES;
BAD:
    self.ok = NO;
}

- (id) initWithInterface: (NSString *)interface
{
    self = [super init];
    if(self) {
        self.device = interface;
        self.pcaphandle = NULL;
        
        char errbuf[PCAP_ERRBUF_SIZE];
        self.pcaphandle = pcap_open_live([self.device UTF8String], IP_MAXPACKET, 0, 1, errbuf);
        if(!self.pcaphandle) {
            printf("%s: %s\n", [self.device UTF8String], errbuf);
            goto BAD;
        }//end if
        
        if([self.device isEqualToString:@"en0"])
            self.type = IJTPacketReaderTypeWiFi;
        else
            self.type = IJTPacketReaderTypeCellular;
        
        self.database = [IJTDatabase getdatabase];
        
        if(curl_global_init(CURL_GLOBAL_SSL) != CURLE_OK)
            goto BAD;

        self.curlhandle = curl_easy_init();
        if(self.curlhandle == NULL)
            goto BAD;
        
        //set URL
        curl_easy_setopt(self.curlhandle, CURLOPT_URL, DETECT_URL);
        
        //enable post
        curl_easy_setopt(self.curlhandle, CURLOPT_POST, 1L);
        
        // support basic, digest, and NTLM authentication
        curl_easy_setopt(self.curlhandle, CURLOPT_HTTPAUTH, CURLAUTH_ANY);
        
        // try not to use signals
        curl_easy_setopt(self.curlhandle, CURLOPT_NOSIGNAL, 1L);
        
        // set a default user agent
        curl_easy_setopt(self.curlhandle, CURLOPT_USERAGENT, curl_version());
        
        //ignore SSL certificate
        curl_easy_setopt(self.curlhandle, CURLOPT_SSL_VERIFYHOST, 0L);
        curl_easy_setopt(self.curlhandle, CURLOPT_SSL_VERIFYPEER, 0L);
        
        //set callback
        curl_easy_setopt(self.curlhandle, CURLOPT_WRITEFUNCTION, &process_data);
        
        self.sn = serialNumber();
        if(self.sn == nil)
            goto BAD;
        
#pragma mark PACKET TYPE
        self.packetType = [IJTPacketReader protocolPostArray];
        
#pragma mark wifi reachability
        if([interface isEqualToString:@"en0"]) {
            _arpdefenderNotification = NO;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
            _wifiReachability = [Reachability reachabilityForLocalWiFi];
            [_wifiReachability startNotifier];
        }
    }
    
    self.ok = YES;
    return self;
    
BAD:
    self.ok = NO;
    [self close];
    return self;
}

- (void) initFlow
{
    self.packetbytes = 0U;
    self.packetcount = 0U;
    self.starttime = time(NULL);
    self.packetTypeCount = [[NSMutableDictionary alloc] init];
    for(NSString *packet in self.packetType) {
        [self.packetTypeCount setValue:@0 forKey:packet];
    }
}

- (BOOL) flushtofile
{
    if(self.packetbytes == 0U || self.packetcount == 0U)
        return NO;
    
    self.endtime = time(NULL);
    NSString *packet = [IJTDaemon nsdictionary2NSSting:self.packetTypeCount prettyPrint:NO];
    if(packet == nil) {
        printf("oops\n");
        return NO;
    }//end if
    NSString *post = [NSString stringWithFormat:@"SerialNumber=%@&Interface=%@&StartTime=%ld&EndTime=%ld&PacketCount=%ld&PacketBytes=%ld&Packet=%@", self.sn, self.device, self.starttime, self.endtime, (unsigned long)self.packetcount, (unsigned long)self.packetbytes, packet];
    
    char tmpfile[512];
    
    struct stat st = {0};
    //create dir
    if (stat("/var/root/Injector/", &st) == -1) {
        mkdir("/var/root/Injector/", 0755);
    }
    //create dir
    if (stat("/var/root/Injector/PacketFlowTemp", &st) == -1) {
        mkdir("/var/root/Injector/PacketFlowTemp", 0755);
    }
    
    snprintf(tmpfile, sizeof(tmpfile),
             "/var/root/Injector/PacketFlowTemp/%ld%s.ijt",
             time(NULL), [self.device UTF8String]);
    FILE *fp = fopen(tmpfile, "w+");
    if(!fp) {
        printf("cann't create tmp file\n");
        return NO;
    }
    fputs([post UTF8String], fp);
    fclose(fp);
    return YES;
}

- (void) sniffing
{
    [self initFlow];
    int timeout = 0;
    while(1) {
        struct pcap_pkthdr *header = NULL;
        const u_char *content = NULL;
        //wait next open
        if(self.pcaphandle == NULL) {
            usleep(100);
            continue;
        }
        int res = pcap_next_ex(self.pcaphandle, &header, &content);
        
        switch(res) {
            case -1:
                printf("%s error: %s\n", [self.device UTF8String], pcap_geterr(self.pcaphandle));
                break;
            case 0:
                [NSThread sleepForTimeInterval:3];
                if([self flushtofile])
                    timeout++;
                [self initFlow];
                if(timeout >= TIMEOUT_TIMES) {
                    [self updateDatabase];
                    timeout = 0;
                }
                break;
            case 1:
                [self analyserPacket:content header:header];
                break;
            case -2:
            default:
                printf("Never reach here\n");
                break;
        }
        fflush(stdout);
    }
}

- (void) analyserPacket: (const u_char *)content header: (const struct pcap_pkthdr *)header
{
    packet_t packet;
    memset(&packet, 0, sizeof(packet));
    memcpy(packet.content, content, header->caplen);
    memcpy(&packet.header, header, sizeof(struct pcap_pkthdr));
    [self countPacket:packet];
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
    self.packetcount++;
    self.packetbytes += packet.header.caplen;
    
    IJTPacketReader *reader = [[IJTPacketReader alloc] initWithPacket:packet type:self.type index:0];
    if(reader.layer2Type != IJTPacketReaderProtocolUnknown) {
        [self count:[IJTPacketReader protocol2PostString:reader.layer2Type]];
    }
    if(reader.layer3Type != IJTPacketReaderProtocolUnknown) {
        [self count:[IJTPacketReader protocol2PostString:reader.layer3Type]];
    }
    if(reader.layer4Type != IJTPacketReaderProtocolUnknown) {
        [self count:[IJTPacketReader protocol2PostString:reader.layer4Type]];
    }
    if(reader.ipv4Header) {
        u_int16_t src_port = reader.sourcePort;
        u_int16_t dst_port = reader.destinationPort;
        if(reader.finalProtocolType == IJTPacketReaderProtocolHTTP) {
            if(src_port == 80)
                [self analyserIp:reader.ipv4Header sourceport:YES];
            else if(dst_port == 80)
                [self analyserIp:reader.ipv4Header sourceport:NO];
        }
        if(reader.finalProtocolType == IJTPacketReaderProtocolHTTPS) {
            if(src_port == 443)
                [self analyserIp:reader.ipv4Header sourceport:YES];
            else if(dst_port == 443)
                [self analyserIp:reader.ipv4Header sourceport:NO];
        }
    }
}

- (void) count: (NSString *)key
{
    NSNumber *count = [self.packetTypeCount objectForKey:key];
    if(!count)
        return;
    count = @([count unsignedLongLongValue] + 1);
    [self.packetTypeCount setObject:count forKey:key];
}

- (void)analyserIp: (struct libnet_ipv4_hdr *)ip sourceport: (BOOL)sourceport
{
    struct in_addr addr = sourceport ? ip->ip_src : ip->ip_dst;
    NSString *hostname = nil;
    NSString *ipAddress = nil;
    int found = 0;
    NSString *post = nil;
    FILE *fp;
    char newline[256];
    NSDictionary *dict;
    NSString *bundleID, *processName, *displayName, *screenLock;
    NSMutableArray *arr;
    NSString *message;
    BOOL switchshownotification;
    id object;
    BOOL white = NO;
    
    for(NSArray *temp in self.database) {
        NSArray *ipArray = [temp objectAtIndex:1];
        for(NSNumber *number in ipArray) {
            if([number unsignedIntegerValue] == addr.s_addr) {
                hostname = [temp objectAtIndex:0];
                found = 1;
            }
        }//end for ip list
        if(found)
            break;
    }
    
    if(found) {
        ipAddress = [NSString stringWithUTF8String:inet_ntoa(addr)];
        //check white list
        NSMutableArray *whitelist = [NSMutableArray arrayWithContentsOfFile:@"/var/root/Injector/WhiteList"];
        NSMutableArray *blacklist = [NSMutableArray arrayWithContentsOfFile:@"/var/root/Injector/BlackList"];
        if(whitelist) {
            for(NSDictionary *dict in whitelist) {
                NSString *ip = [dict valueForKey:@"IpAddress"];
                NSNumber *enable = [dict valueForKey:@"Enable"];
                if([enable boolValue] && [ip isEqualToString:ipAddress]) {
                    printf("%s in white\n", [ip UTF8String]);
                    white = YES;
                    goto FOREGROUND;
                }
            }
        }
        else { //file not exsit
            whitelist = [[NSMutableArray alloc] init];
            [whitelist writeToFile:@"/var/root/Injector/WhiteList" atomically:YES];
        }
        
        //maybe packet still in queue but already block
        if(blacklist) {
            for(NSDictionary *dict in blacklist) {
                NSString *ip = [dict valueForKey:@"IpAddress"];
                NSNumber *enable = [dict valueForKey:@"Enable"];
                if([enable boolValue] && [ip isEqualToString:ipAddress]) {
                    printf("%s in black\n", [ip UTF8String]);
                    return;
                }
            }
        }
        else {
            blacklist = [[NSMutableArray alloc] init];
            [blacklist writeToFile:@"/var/root/Injector/BlackList" atomically:YES];
        }
        
        
        arr = [[NSMutableArray alloc] initWithObjects:@"", nil];
        post = [NSString stringWithFormat:@"SerialNumber=%@&Hostname=%@&IpAddress=%@", self.sn, hostname, ipAddress];
        curl_easy_setopt(self.curlhandle, CURLOPT_URL, DETECT_URL);
        curl_easy_setopt(self.curlhandle, CURLOPT_POSTFIELDS, [post UTF8String]);
        curl_easy_setopt(self.curlhandle, CURLOPT_WRITEDATA, arr);
        
        if(CURLE_OK != curl_easy_perform(self.curlhandle))
            printf("fail to upload detect event\n");
        else {
            //printf("%s\n", [post UTF8String]);
            //printf("detect: %s/%s\n", [hostname UTF8String], [ipAddress UTF8String]);
            
            message = [arr objectAtIndex:0];
            if([message hasPrefix:@"99"]) {
                printf("uploaded detect event\n");
                
            FOREGROUND:
                fp = popen("/Applications/Injector.app/InjectorForeground", "r");
                memset(newline, 0, sizeof(newline));
                fgets(newline, sizeof(newline)-1, fp);
                pclose(fp);
                dict = json2dictionary([NSString stringWithUTF8String:newline]);
                bundleID = [dict valueForKey:@"Bundle ID"];
                processName = [dict valueForKey:@"Process Name"];
                displayName = [dict valueForKey:@"Display Name"];
                screenLock = [dict valueForKey:@"Screen Lock"];
                
                //upload app and ip info
                post = [NSString stringWithFormat:@"SerialNumber=%@&Hostname=%@&IpAddress=%@&BundleID=%@&ProcessName=%@&DisplayName=%@&ScreenLock=%@",
                        self.sn, hostname, ipAddress,
                        [self string2post:bundleID],
                        [self string2post:processName],
                        [self string2post:displayName],
                        screenLock];
                printf("%s\n", [post UTF8String]);
                
                arr = [[NSMutableArray alloc] initWithObjects:@"", nil];
                curl_easy_setopt(self.curlhandle, CURLOPT_URL, FOREGROUNDAPP_URL);
                curl_easy_setopt(self.curlhandle, CURLOPT_POSTFIELDS, [post UTF8String]);
                curl_easy_setopt(self.curlhandle, CURLOPT_WRITEDATA, arr);
                if(CURLE_OK != curl_easy_perform(self.curlhandle)) {
                    printf("fail to upload foreground app information\n");
                }
                else {
                    if(white)
                        return;
                    object = plistObject(@"SwitchShowNotification", 1);
                    switchshownotification = YES;
                    if(object != nil)
                        switchshownotification = [object boolValue];
                    
                    if(switchshownotification) {
                        message = [arr objectAtIndex:0];
                        if(message.length < 4)
                            return;
                        message = [message substringFromIndex:3];
                        [self showAlertMessage:message ipAddress:ipAddress displayName:displayName time:time(NULL)];
                    }
                }
                
            }//end if ok
        }//end
        
    }
}

id plistObject(NSString *key, int index)
{
    NSDictionary *plist =
    [[NSDictionary alloc] initWithContentsOfFile:PREFERENCELOADER];
    id object = nil;
    
    if(plist && plist.count == 0) {
        plist = [[NSDictionary alloc] initWithContentsOfFile:PREFERENCELOADER_DEFAULT];
        NSArray *items = [plist valueForKey:@"items"];
        object = [items[index] valueForKey:@"default"];
    }
    else {
        object = [plist valueForKey:key];
    }
    return object;
}

- (NSString *)string2post: (NSString *)string {
    //http://en.wikipedia.org/wiki/Percent-encoding
    NSString *output = [NSString stringWithString:string];
    NSArray *key = @[@"!", @"#", @"&", @"\'", @"(", @")", @"*", @"+", @",", @"/", @":", @";", @"=", @"?", @"@", @"[", @"]"];
    NSArray *value = @[@"%21", @"%23", @"%26", @"%27", @"%28", @"%29", @"%2A", @"%2B", @"%2C", @"%2F", @"%3A", @"%3B", @"%3D", @"%3F", @"%40", @"%5B", @"%5D"];
    for(int i = 0 ; i < key.count ; i++) {
        output = [output stringByReplacingOccurrencesOfString:key[i] withString:value[i]];
    }
    return output;
}

static NSDictionary *json2dictionary(NSString *json)
{
    NSDictionary *dict = nil;
    
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    dict = [NSJSONSerialization JSONObjectWithData:data
                                           options:NSJSONReadingAllowFragments
                                             error:&error];
    if(error)
        return nil;
    return dict;
}

- (void) showAlertMessage: (NSString *)message ipAddress: (NSString *)ipAddress displayName: (NSString *)displayName time: (time_t)time
{
    /* from
     * http://stackoverflow.com/questions/15025174/pull-notification-locally-on-jailbroken-device
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject: @"Injector Alert!" forKey: (__bridge NSString*)kCFUserNotificationAlertHeaderKey];
        [dict setObject: message forKey: (__bridge NSString*)kCFUserNotificationAlertMessageKey];
        [dict setObject: @"Block" forKey:(__bridge NSString*)kCFUserNotificationAlternateButtonTitleKey];
        [dict setObject: @"Allow" forKey:(__bridge NSString*)kCFUserNotificationOtherButtonTitleKey];
        [dict setObject: @"Allow once" forKey:(__bridge NSString*)kCFUserNotificationDefaultButtonTitleKey];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge NSString *)kCFUserNotificationAlertTopMostKey];
        
        SInt32 error = 0;
        CFUserNotificationRef alert =
        CFUserNotificationCreate(NULL, 0, kCFUserNotificationPlainAlertLevel, &error, (__bridge CFDictionaryRef)dict);
        CFOptionFlags response;
        if((error) || (CFUserNotificationReceiveResponse(alert, 0, &response))) {
            NSLog(@"alert error or no user response");
        } else if((response & 0x3) == kCFUserNotificationAlternateResponse) {
            NSLog(@"Block");
            
            NSMutableArray *blacklist = [NSMutableArray arrayWithContentsOfFile:@"/var/root/Injector/BlackList"];
            if(blacklist == nil) {
                blacklist = [[NSMutableArray alloc] init];
            }
            
            BOOL found = NO;
            for(NSDictionary *dict in blacklist) {
                NSString *ip = [dict valueForKey:@"IpAddress"];
                if([ip isEqualToString:ipAddress]) {
                    found = YES;
                    break;
                }
            }
            if(found) {
                return;
            }
            
            IJTFirewall *fw = [[IJTFirewall alloc] init];
            if([IJTDaemon checkInterface:@"en0"]) {
                [fw blockAtInterface:@"en0"
                              family:AF_INET
                           ipAddress:ipAddress quick:YES];
            }
            if([IJTDaemon checkInterface:@"pdp_ip0"]) {
                [fw blockAtInterface:@"pdp_ip0"
                              family:AF_INET
                           ipAddress:ipAddress quick:YES];
            }
            //[fw generateRuleFile];
            [fw close];
            
            if(fw.errorHappened)
                return;
            
            NSMutableDictionary *newone = [[NSMutableDictionary alloc] init];
            [newone setObject:ipAddress forKey:@"IpAddress"];
            [newone setObject:displayName forKey:@"DisplayName"];
            [newone setObject:[NSNumber numberWithLong:time] forKey:@"AddTime"];
            [newone setObject:@(YES) forKey:@"Enable"];
            [blacklist addObject:newone];
            [blacklist writeToFile:@"/var/root/Injector/BlackList" atomically:YES];
            
        } else if((response & 0x3) == kCFUserNotificationDefaultResponse) {
            NSLog(@"Allow once");
        }else if((response & 0x3) == kCFUserNotificationOtherResponse) {
            NSLog(@"Allow");
            NSMutableArray *whitelist = [NSMutableArray arrayWithContentsOfFile:@"/var/root/Injector/WhiteList"];
            if(whitelist == nil) {
                whitelist = [[NSMutableArray alloc] init];
            }
            BOOL found = NO;
            for(NSDictionary *dict in whitelist) {
                NSString *ip = [dict valueForKey:@"IpAddress"];
                if([ip isEqualToString:ipAddress]) {
                    found = YES;
                    break;
                }
            }
            if(found) {
                return;
            }
            NSMutableDictionary *newone = [[NSMutableDictionary alloc] init];
            [newone setObject:ipAddress forKey:@"IpAddress"];
            [newone setObject:displayName forKey:@"DisplayName"];
            [newone setObject:[NSNumber numberWithLong:time] forKey:@"AddTime"];
            [newone setObject:@(YES) forKey:@"Enable"];
            [whitelist addObject:newone];
            [whitelist writeToFile:@"/var/root/Injector/WhiteList" atomically:YES];
        }
        
        CFRelease(alert);
    });
}

+ (BOOL)checkInterface: (NSString *)interface
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

static size_t process_data(void *buffer, size_t size, size_t nmemb, void *user_p)
{
    NSMutableArray *arr = (__bridge NSMutableArray *)user_p;
    NSString *message = [arr objectAtIndex:0];
    message = [message stringByAppendingString:[NSString stringWithUTF8String:(char *)buffer]];
    [arr replaceObjectAtIndex:0 withObject:message];
    printf("%s\n", (char *)buffer);
    return nmemb;
}

- (void) start
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sniffing];
    });
}

- (void) updateDatabase
{
    NSArray *arr = [IJTDatabase getdatabase];
    if(arr)
        self.database = [IJTDatabase getdatabase];
}

+ (NSString *)nsdictionary2NSSting: (NSDictionary *)dictionary prettyPrint: (BOOL)prettyPrint
{
    NSError *error;
    NSData *jsonData =
    [NSJSONSerialization dataWithJSONObject:dictionary
                                    options:(NSJSONWritingOptions)
     (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                      error:&error];
    
    if (!jsonData) {
        NSLog(@"nsdictionary2NSSting: %@", error.localizedDescription);
        return nil;
    } else
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void) dealloc
{
    if([_device isEqualToString:@"en0"]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        [_wifiReachability stopNotifier];
    }
    [self close];
}

- (void) closePcap {
    if(self.pcaphandle)
        pcap_close(self.pcaphandle);
    self.pcaphandle = NULL;
}
- (void) close
{
    [self closePcap];
    if(self.curlhandle) {
        curl_easy_cleanup(self.curlhandle);
    }
    curl_global_cleanup();
}


#pragma mark wifi reachability changed
- (void) reachabilityChanged:(NSNotification *)note {

    id object = plistObject(@"SwitchARPDefender", 3);
    if(![object boolValue]) {
        return;
    }
    
    if(_arpdefenderNotification) {
        return;
    }
    if(_wifiReachability.currentReachabilityStatus != ReachableViaWiFi) {
        return;
    }
    
    sleep(1);
    NSString *BSSID = [IJTConnection BSSID];
    NSMutableString *defaultGateway = [[NSMutableString alloc] init];
    IJTRoutetable *routeTable = [[IJTRoutetable alloc] init];
    [routeTable getGatewayByDestinationIpAddress:@"0.0.0.0"
                                          target:self
                                        selector:ROUTETABLE_SHOW_CALLBACK_SEL
                                          object:defaultGateway];
    [routeTable close];
    IJTArptable *arpTable = [[IJTArptable alloc] init];
    [arpTable addIpAddress:defaultGateway
                macAddress:BSSID
                  isstatic:YES
               ispublished:NO isonly:NO];
    [arpTable close];
    if(defaultGateway.length <= 0 || [BSSID isEqualToString:@"00:00:00:00:00:00"]) {
        return;
    }
    
    object = plistObject(@"SwitchShowNotification", 1);
    BOOL show = NO;
    if(object != nil) {
        show = [(NSNumber *)object boolValue];
    }
    if(!show) {
        return;
    }
    _arpdefenderNotification = YES;
    
    __block NSString *message = [NSString stringWithFormat:@"ARP Defender: set %@ at %@", defaultGateway, BSSID];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject: @"Injector Alert!" forKey: (__bridge NSString*)kCFUserNotificationAlertHeaderKey];
        [dict setObject: message forKey: (__bridge NSString*)kCFUserNotificationAlertMessageKey];
        [dict setObject: @"OK" forKey:(__bridge NSString*)kCFUserNotificationDefaultButtonTitleKey];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:(__bridge NSString *)kCFUserNotificationAlertTopMostKey];
        
        SInt32 error = 0;
        CFUserNotificationRef alert =
        CFUserNotificationCreate(NULL, 0, kCFUserNotificationPlainAlertLevel, &error, (__bridge CFDictionaryRef)dict);
        CFOptionFlags response;
        if((error) || (CFUserNotificationReceiveResponse(alert, 0, &response))) {
            NSLog(@"alert error or no user response");
        } else if((response & 0x3) == kCFUserNotificationDefaultResponse) { //click ok
            _arpdefenderNotification = NO;
            
        }
        CFRelease(alert);
    });
    
}

ROUTETABLE_SHOW_CALLBACK_METHOD {
    if([destinationIpAddress isEqualToString:@"0.0.0.0"] && [interface isEqualToString:@"en0"]) {
        NSMutableString *s = (NSMutableString *)object;
        [s appendString:gateway];
    }
}

@end
