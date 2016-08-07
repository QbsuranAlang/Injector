//
//  IJTDatabase.m
//  InjectorDaemon
//
//  Created by 聲華 陳 on 2015/4/15.
//
//

#import "IJTDatabase.h"
#import <curl/curl.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <spawn.h>
extern char **environ;
#define DATABASEURL "https://nrl.cce.mcu.edu.tw/injector/dbAccess/Database"
#define DATABASE_FILE "/var/root/Injector/MaliceDatabase"
@interface IJTDatabase ()

/*
@property (nonatomic) CURL *curlhandle;
@property (nonatomic) FILE *databasefile;
*/

@end

@implementation IJTDatabase

- (id) init
{
    self = [super init];
    if(self) {
        self.updateTimer =
        [NSTimer scheduledTimerWithTimeInterval:UPDATE_INTERVAL
                                         target:self
                                       selector:@selector(retrieve)
                                       userInfo:nil
                                        repeats:YES];
        /*
        if(curl_global_init(CURL_GLOBAL_SSL) != CURLE_OK)
            goto BAD;
        
        self.curlhandle = curl_easy_init();
        if(self.curlhandle == NULL)
            goto BAD;
        
        //set URL
        curl_easy_setopt(self.curlhandle, CURLOPT_URL, DATABASEURL);
        
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
        curl_easy_setopt(self.curlhandle, CURLOPT_WRITEDATA, &_databasefile);
        curl_easy_setopt(self.curlhandle, CURLOPT_WRITEFUNCTION, writeCallback);
        
        self.databasefile = NULL;
         */
    }
    
BAD:
    return self;
}

- (void) retrieve
{
    printf("updating database\n");
    struct stat st = {0};
    //create dir
    if (stat("/var/root/Injector/", &st) == -1) {
        mkdir("/var/root/Injector/", 0755);
    }
    /*
    self.databasefile = fopen(DATABASE_FILE, "w+");
    if(!self.databasefile) {
        printf("fail to update database\n");
        return;
    }
    curl_easy_perform(self.curlhandle);
    fflush(self.databasefile);
    fclose(self.databasefile);
     */
#if 0
    remove(DATABASE_FILE);
    
    pid_t pid;
    char *argv[] = {
        "/usr/bin/curl",
        "-o",
        DATABASE_FILE,
        "-k",
        DATABASEURL,
        NULL
    };
    
    posix_spawn(&pid, argv[0], NULL, NULL, argv, environ);
    waitpid(pid, NULL, 0);

    printf("update successfully\n");
#endif
}

/*
static size_t writeCallback(char *ptr, size_t size, size_t nmemb, void *userdata)
{
    FILE *fp = *(FILE **)userdata;
    fprintf(fp, "%s", ptr);
    return nmemb;
}*/

+ (NSArray *) getdatabase
{
    NSString *filename = [NSString stringWithUTF8String:DATABASE_FILE];
    NSDictionary *dict = [IJTDatabase file2dictionary:filename];
    if(!dict)
        return nil;
    return [dict valueForKey:@"database"];
}

+ (NSDictionary *)file2dictionary :(NSString *)filename
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filename];
    NSData *data = [fileHandle readDataToEndOfFile];
    return [IJTDatabase json2dictionary:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
}

+ (NSDictionary *)json2dictionary: (NSString *)json
{
    NSDictionary *dict = nil;
    
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    dict = [NSJSONSerialization JSONObjectWithData:data
                                           options:kNilOptions
                                             error:&error];
    if(error) {
        printf("%s\n", [error.localizedDescription UTF8String]);
        return nil;
    }
    return dict;
}
@end
