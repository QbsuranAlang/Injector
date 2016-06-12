//
//  IJTSysctl.m
//  IJTSysctl
//
//  Created by 聲華 陳 on 2015/8/1.
//
//

#import "IJTSysctl.h"
#import <sys/sysctl.h>

@implementation IJTSysctl

+ (int)sysctlValueByname: (NSString *)name {
    int buf = -1;
    size_t size = sizeof(buf);
    if(sysctlbyname([name UTF8String], &buf, &size, NULL, 0) == -1)
        return -1;
    return buf;
}

+ (int)sysctlSetValue: (int)value name: (NSString *)name {
    if(sysctlbyname([name UTF8String], NULL, NULL, &value, sizeof(value)) == -1) {
        return -1;
    }
    return 0;
}

+ (int)setIPForwarding: (BOOL)enable {
    int state = enable ? 1 : 0;
    [IJTSysctl sysctlSetValue:0 name:@"net.inet.ip.redirect"];
    return [IJTSysctl sysctlSetValue:state name:@"net.inet.ip.forwarding"];
}

+ (int)ipForwarding {
    return [IJTSysctl sysctlValueByname:@"net.inet.ip.forwarding"];
}

+ (void)increaseTo: (int)value name: (NSString *)name {
    int d = 0;
    do {
        d = [IJTSysctl sysctlValueByname:name] + 1;
        if(d > value) {
            break;
        }
    }
    while([IJTSysctl sysctlSetValue:d name:name] != -1);
}

+ (NSArray *)suggestSettings {
    return [@[@"net.inet.ip.redirect", @"net.inet6.ip6.redirect", @"net.inet.icmp.drop_redirect", @"net.inet.icmp.log_redirect", @"net.inet.icmp.bmcastecho", @"net.inet.tcp.blackhole",
             @"net.inet.udp.blackhole", @"net.inet.tcp.drop_synfin", @"net.inet.ip.random_id",
             @"net.inet.icmp.maskrepl", @"net.inet.tcp.always_keepalive", @"net.inet.udp.checksum"]
            sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

+ (int)suggestValue: (NSString *)name {
    if([name isEqualToString:@"net.inet.ip.redirect"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet6.ip6.redirect"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet.icmp.drop_redirect"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.icmp.log_redirect"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.icmp.bmcastecho"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet.tcp.blackhole"]) {
        return 2;
    }
    else if([name isEqualToString:@"net.inet.udp.blackhole"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.tcp.drop_synfin"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.ip.random_id"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.icmp.maskrepl"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet.tcp.always_keepalive"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.udp.checksum"]) {
        return 1;
    }
    else
        return -1;
}

+ (int)oldValue: (NSString *)name {
    if([name isEqualToString:@"net.inet.ip.redirect"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet6.ip6.redirect"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.icmp.drop_redirect"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet.icmp.log_redirect"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet.icmp.bmcastecho"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.tcp.blackhole"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet.udp.blackhole"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet.tcp.drop_synfin"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.ip.random_id"]) {
        return 1;
    }
    else if([name isEqualToString:@"net.inet.icmp.maskrepl"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet.tcp.always_keepalive"]) {
        return 0;
    }
    else if([name isEqualToString:@"net.inet.udp.checksum"]) {
        return 1;
    }
    else
        return -1;
}

@end
