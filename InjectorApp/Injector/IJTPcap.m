//
//  IJTPcap.m
//  Injector
//
//  Created by 聲華 陳 on 2015/3/3.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTPcap.h"

@implementation IJTPcap

@synthesize errorMessage;
@synthesize occurError;

+ (BOOL)testPcapFilter: (NSString *)pcapFilter interface: (NSString *)interface
{
    BOOL ok = YES;

    IJTPcap *pcap = [[IJTPcap alloc] initInterface:interface bpfFilter:pcapFilter promisc:NO toms:1000];
    
    ok = !pcap.occurError;
    [pcap closeHandle];
    
    return ok;
}

+ (NSString *)errorMessageFromErrorFilter: (NSString *)pcapFilter interface: (NSString *)interface
{
    IJTPcap *pcap = [[IJTPcap alloc] initInterface:interface bpfFilter:pcapFilter promisc:NO toms:1000];
    
    NSString *error = pcap.errorMessage;
    [pcap closeHandle];
    return pcap.occurError ? error : nil;
}

- (id) initInterface :(NSString *)interface
            bpfFilter:(NSString *)bpfFilter
              promisc:(BOOL)promisc
                 toms:(unsigned int)toms
{
    self = [super init];
    self.occurError = NO;
    
    if(self) {
        if([bpfFilter isEqualToString:@"all"])
            bpfFilter = @"";
        
        char errbuf[PCAP_ERRBUF_SIZE];
        struct bpf_program bpf_filter;
        bpf_u_int32 net_mask;
        bpf_u_int32 net_ip;
        
        self.handle = pcap_open_live((const char *)[interface UTF8String], PACKET_MAX, promisc ? 1 : 0, toms, errbuf);
        
        if(!self.handle) {
            self.errorMessage = [NSString stringWithUTF8String:errbuf];
            self.occurError = YES;
            return self;
        }//end if
        
        //do not need filter
        if([bpfFilter isEqualToString:@""])
            return self;
        
        //set bpf filter
        if(0 != pcap_lookupnet((const char *)[interface UTF8String], &net_ip, &net_mask, errbuf)) {
            self.errorMessage = [NSString stringWithUTF8String: errbuf];
            [self closeHandle];
            self.occurError = YES;
            return self;
        }//end if
        if(0 != pcap_compile(self.handle, &bpf_filter, (const char *)[bpfFilter UTF8String], 0, net_ip)) {
            goto FAIL;
        }//end if
        if(0 != pcap_setfilter(self.handle, &bpf_filter)) {
            pcap_freecode(&bpf_filter);
            goto FAIL;
        }//end if
        
        pcap_freecode(&bpf_filter);
        
        return self;
    }
    
FAIL:
    self.errorMessage = [NSString stringWithUTF8String: pcap_geterr(self.handle)];
    [self closeHandle];
    self.occurError = YES;
    return self;
}

- (void)breakLoop
{
    if(self.handle) {
        pcap_breakloop(self.handle);
    }
}

- (NSString *) getPcapError
{
    char *temp = NULL;
    if(self.handle)
        temp = pcap_geterr(self.handle);
    if(temp)
        return [NSString stringWithUTF8String:temp];
    else
        return @"";
}

- (void)closeHandle
{
    if(self.handle) {
        pcap_close(self.handle);
        self.handle = NULL;
    }
}

- (void)dealloc
{
    [self closeHandle];
}
@end
