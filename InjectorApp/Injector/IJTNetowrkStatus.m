//
//  IJTNetowrkStatus.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTNetowrkStatus.h"
#import <ifaddrs.h>
#import <sys/socket.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <net/if_dl.h>
#import <arpa/inet.h>
#import <sys/sysctl.h>
#import <net/ethernet.h>

@implementation IJTNetowrkStatus

+ (BOOL)supportCellular
{
    return [self checkInterface:@"pdp_ip0"];
}//end

+ (BOOL)supportWifi
{
    return [self checkInterface:@"en0"];
}//end

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

+ (Reachability *)wifiReachability
{
    return [Reachability reachabilityForLocalWiFi];
}

+ (Reachability *)cellReachability
{
    return [Reachability reachabilityForInternetConnection];
}

+ (NSString *)getWiFiNetworkAndSlash: (int *)slash {
    struct ifreq ifr;
    int sockfd = -1;
    struct in_addr nmask;
    struct in_addr ip;
    struct in_addr netmask;
    int mask = 1;
    *slash = 0;
    
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if(sockfd < 0)
        return nil;
    
    //get mask addr
    memset(&ifr, 0, sizeof(ifr));
    snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "en0");
    if((ioctl(sockfd, SIOCGIFNETMASK, &ifr)) == -1) {
        close(sockfd);
        return nil;
    }
    memcpy(&nmask.s_addr,
           &(*(struct sockaddr_in *)&ifr.ifr_addr).sin_addr,
           sizeof(nmask.s_addr));
    for(int i = 0 ; i < 32 ; i++) {
        if(mask & nmask.s_addr)
            (*slash)++;
        mask <<= 1;
    }
    
    //get ip addr
    memset(&ifr, 0, sizeof(ifr));
    snprintf(ifr.ifr_name, sizeof(ifr.ifr_name), "en0");
    if((ioctl(sockfd, SIOCGIFADDR, &ifr)) == -1) {
        close(sockfd);
        return nil;
    }
    memcpy(&ip.s_addr,
           &(*(struct sockaddr_in *)&ifr.ifr_addr).sin_addr, sizeof(ip.s_addr));
    
    close(sockfd);
    
    mask = 1 << 31;
    netmask.s_addr = 0;
    
    //get real network ip
    for(u_int32_t i = 0 ; i < *slash ; i++) {
        if(mask & ntohl(ip.s_addr))
            netmask.s_addr |= mask;
        mask >>= 1;
    }
    netmask.s_addr = htonl(netmask.s_addr);
    ip.s_addr = ip.s_addr & netmask.s_addr;
    
    return [NSString stringWithUTF8String:inet_ntoa(ip)];
}

+ (NSArray *)getWiFiNetworkStartAndEndIpAddress {
    
    int slash = 0;
    NSString *network = [IJTNetowrkStatus getWiFiNetworkAndSlash:&slash];
    
    struct in_addr startIp, endIp;
    u_int32_t mask;
    NSString *startIpAddress, *endIpAddress;
    
    if(slash < 0 || slash > 32) {
        errno = EINVAL;		/* Invalid argument */
        return nil;
    }//end if
    
    if(network == nil)
        return nil;

    if(inet_aton([network UTF8String], &startIp) == 0)
        return nil;
    
    //padding zero bit
    endIp.s_addr = ntohl(startIp.s_addr);
    mask = 1;
    for(u_int32_t i = 0 ; i < 32 - slash ; i++) {
        endIp.s_addr |= mask;
        mask <<= 1;
    }
    endIp.s_addr = htonl(endIp.s_addr);
    
    char ntop_buf[256];
    memset(ntop_buf, 0, sizeof(ntop_buf));
    
    inet_ntop(AF_INET, &startIp, ntop_buf, sizeof(ntop_buf));
    startIpAddress = [NSString stringWithUTF8String:ntop_buf];
    
    inet_ntop(AF_INET, &endIp, ntop_buf, sizeof(ntop_buf));
    endIpAddress = [NSString stringWithUTF8String:ntop_buf];
    
    return @[startIpAddress, endIpAddress];
}

+ (NSString *)currentIPAddress: (NSString *)interface {
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    NSString *address = nil;
    
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
    NSString *macAddressString = [self ether_ntoa:((const struct ether_addr *)macAddress)];
    //NSLog(@"Mac Address: %@", macAddressString);
    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

+ (NSString *)ether_ntoa:(const struct ether_addr *)addr {
    return [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x", addr->octet[0], addr->octet[1], addr->octet[2], addr->octet[3], addr->octet[4], addr->octet[5]];
}
@end
