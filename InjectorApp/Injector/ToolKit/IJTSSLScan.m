//
//  IJTSSLScan.m
//  IJTSSLScan
//
//  Created by 聲華 陳 on 2015/12/14.
//
//

#import "IJTSSLScan.h"
#import <netdb.h>
#import <sys/socket.h>
#import <sys/select.h>
#import <string.h>
#import <sys/stat.h>
#import <openssl/err.h>
#import <openssl/ssl.h>
#import <openssl/pkcs12.h>
#import <openssl/x509.h>
#import <openssl/x509v3.h>
#import <openssl/ocsp.h>
#import <unistd.h>
#import <sys/ioctl.h>
#import <sys/sysctl.h>
#import <arpa/inet.h>

struct sslCipher {
    // Cipher Properties...
    const char *name;
    char *version;
    int bits;
    char description[512];
    const SSL_METHOD *sslMethod;
    struct sslCipher *next;
};

// store renegotiation test data
struct renegotiationOutput {
    int supported;
    int secure;
};

@interface IJTSSLScan ()

@property (nonatomic) struct sockaddr_in sin4;
@property (nonatomic) struct sockaddr_in6 sin6;
@property (nonatomic) sa_family_t family;
@property (nonatomic) struct timeval timeout;
@property (nonatomic, strong) NSString *hostname;

@property (nonatomic) BOOL getSupportedClientBoolean;
@property (nonatomic) BOOL testRenegotiationBoolean;
@property (nonatomic) BOOL testCompressionBoolean;
@property (nonatomic) BOOL testHeartbleedBoolean;
@property (nonatomic) BOOL testServerSupportedBoolean;
@property (nonatomic) BOOL showCertificateBoolean;
@property (nonatomic) BOOL showTrustedCAsBoolean;

@property (nonatomic) BOOL stopAll;

@end

@implementation IJTSSLScan

- (id)init {
    self = [super init];
    if(self) {
        SSL_library_init();
        SSLeay_add_all_algorithms();
        ERR_load_crypto_strings();
        
        _getSupportedClientBoolean = _testRenegotiationBoolean = _testCompressionBoolean = _testHeartbleedBoolean = _testServerSupportedBoolean = _showCertificateBoolean = _showTrustedCAsBoolean = NO;
    }
    return self;
}

- (int)setTarget: (NSString *)target port: (u_int16_t)port family: (sa_family_t)family timeout: (u_int32_t)timeout {
    
    int socketDescriptor = 0;
    struct hostent *hp;
    //char hnamebuf[MAXHOSTNAMELEN];
    
    self.hostname = [NSString stringWithString:target];
    _family = family;
    
    if(family == AF_INET) {
        memset(&_sin4, 0, sizeof(_sin4));
        _sin4.sin_family = AF_INET;
        _sin4.sin_len = sizeof(_sin4);
        _sin4.sin_port = htons(port);
        
        if(inet_pton(AF_INET, [target UTF8String], &_sin4.sin_addr) != 1) {
            hp = gethostbyname2([target UTF8String], AF_INET);
            if (!hp) {
                [self.delegate IJTSSLScanResolveHostnameFailure:[NSString stringWithUTF8String:hstrerror(h_errno)]];
                return -1;
            }
            if ((unsigned)hp->h_length > sizeof(_sin4.sin_addr)) {
                [self.delegate IJTSSLScanResolveHostnameFailure:[NSString stringWithUTF8String:hstrerror(h_errno)]];
                return -1;
            }
            
            memcpy(&_sin4.sin_addr, hp->h_addr_list[0], sizeof _sin4.sin_addr);
            //(void)strncpy(hnamebuf, hp->h_name, sizeof(hnamebuf) - 1);
            //hnamebuf[sizeof(hnamebuf) - 1] = '\0';
        }
    }//end if
    else if(family == AF_INET6) {
        memset(&_sin6, 0, sizeof(_sin6));
        _sin6.sin6_family = AF_INET6;
        _sin6.sin6_len = sizeof(_sin6);
        _sin6.sin6_port = htons(port);
        
        if(inet_pton(AF_INET6, [target UTF8String], &_sin6.sin6_addr) != 1) {
            hp = gethostbyname2([target UTF8String], AF_INET6);
            if (!hp) {
                [self.delegate IJTSSLScanResolveHostnameFailure:[NSString stringWithUTF8String:hstrerror(h_errno)]];
                return -1;
            }
            if ((unsigned)hp->h_length > sizeof(_sin6.sin6_addr)) {
                [self.delegate IJTSSLScanResolveHostnameFailure:[NSString stringWithUTF8String:hstrerror(h_errno)]];
                return -1;
            }
            
            memcpy(&_sin6.sin6_addr, hp->h_addr_list[0], sizeof _sin6.sin6_addr);
        }
    }//end else
    
    _timeout.tv_sec = timeout / 1000;
    _timeout.tv_usec = timeout % 1000;
    
    socketDescriptor = [self tcpConnect];
    if(socketDescriptor < 0) {
        return -1;
    }
    else {
        close(socketDescriptor);
    }
    return 0;
}

- (int)scan {
    if(_stopAll)
        return -1;
    
    _stopAll = NO;
    int status = 0;
    int s = [self tcpConnect];
    
    if(s < 0) {
        [self.delegate IJTSSLScanResolveHostnameFailure:[NSString stringWithUTF8String:strerror(ECONNREFUSED)]];
        return -1;
    }
    close(s);
    
    //display supported client ciphers
    if(_getSupportedClientBoolean) {
        struct sslCipher *sslCipherPointer = NULL;
        
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
        [self populateCipherList:TLSv1_2_client_method() ciphers:&sslCipherPointer];
        [self populateCipherList:TLSv1_1_client_method() ciphers:&sslCipherPointer];
#endif
        [self populateCipherList:TLSv1_client_method() ciphers:&sslCipherPointer];
#ifndef OPENSSL_NO_SSL3
        [self populateCipherList:SSLv3_client_method() ciphers:&sslCipherPointer];
#endif
#ifndef OPENSSL_NO_SSL2
        [self populateCipherList:SSLv2_client_method() ciphers:&sslCipherPointer];
#endif
        
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
        [self populateCipherList:TLSv1_2_client_method() ciphers:&sslCipherPointer];
        [self populateCipherList:TLSv1_1_client_method() ciphers:&sslCipherPointer];
#endif
        [self populateCipherList:TLSv1_client_method() ciphers:&sslCipherPointer];
        
        NSMutableArray *lists = [[NSMutableArray alloc] init];
        struct sslCipher *temp = sslCipherPointer;
        while(temp) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            [dict setObject:[NSString stringWithUTF8String:temp->name] forKey:@"Name"];
            [dict setObject:[NSString stringWithUTF8String:temp->description] forKey:@"Description"];
            [dict setObject:@(temp->bits) forKey:@"Bits"];
            [dict setObject:[NSString stringWithUTF8String:temp->version] forKey:@"Version"];
            
            [lists addObject:dict];
            
            temp = temp->next;
        }//end while
        [self.delegate IJTSSLScanSupportedClientCiphers:lists];
        
        //free
        temp = NULL;
        while(sslCipherPointer) {
            temp = sslCipherPointer;
            sslCipherPointer = sslCipherPointer->next;
            free(temp);
        }
    }//end if
    if(_stopAll)
        return 0;
    
    
    
    if(_testRenegotiationBoolean) {
        //test renegotiation
        status = [self testRenegotiation:(SSL_METHOD *)TLSv1_client_method()];
    }
    
    if(_stopAll)
        return 0;
    
    if(_testCompressionBoolean) {
        //test compression
        status = [self testCompression:(SSL_METHOD *)TLSv1_client_method()];
    }
    
    if(_stopAll)
        return 0;
    
    if(_testHeartbleedBoolean) {
        //heartbleed
        status = [self testHeartbleed:(SSL_METHOD *)TLSv1_2_client_method()]; //tls 1.2
        if(_stopAll)
            return 0;
        if(status != -1)
            status = [self testHeartbleed:(SSL_METHOD *)TLSv1_1_client_method()]; //tls 1.1
        if(_stopAll)
            return 0;
        if(status != -1)
            status = [self testHeartbleed:(SSL_METHOD *)TLSv1_client_method()]; //tls 1.0
    }
    
    if(_stopAll)
        return 0;
    
    if(_testServerSupportedBoolean) {
        //test server supported
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
        if (status != -1)
            status = [self testProtocolCiphers:(SSL_METHOD *)TLSv1_2_client_method()];
        if(_stopAll)
            return 0;
        if (status != -1)
            status = [self testProtocolCiphers:(SSL_METHOD *)TLSv1_1_client_method()];
        if(_stopAll)
            return 0;
#endif
        if (status != -1)
            status = [self testProtocolCiphers:(SSL_METHOD *)TLSv1_client_method()];
        if(_stopAll)
            return 0;
#ifndef OPENSSL_NO_SSL3
        if (status != -1)
            status = [self testProtocolCiphers:(SSL_METHOD *)SSLv3_client_method()];
        if(_stopAll)
            return 0;
#endif
#ifndef OPENSSL_NO_SSL2
        if (status != -1)
            status = [self testProtocolCiphers:(SSL_METHOD *)SSLv2_client_method()];
        if(_stopAll)
            return 0;
#endif
        
        status = 0;
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
        if (status != -1)
            status = [self testProtocolCiphers:(SSL_METHOD *)TLSv1_2_client_method()];
        if(_stopAll)
            return 0;
        if (status != -1)
            status = [self testProtocolCiphers:(SSL_METHOD *)TLSv1_1_client_method()];
        if(_stopAll)
            return 0;
#endif
        if (status != -1)
            status = [self testProtocolCiphers:(SSL_METHOD *)TLSv1_client_method()];
        if(_stopAll)
            return 0;
    }
    
    if(_stopAll)
        return 0;
    
    if(_showCertificateBoolean) {
        //certificate information
        status = [self showCertificate];
    }
    
    if(_stopAll)
        return 0;
    
    if(_showTrustedCAsBoolean) {
        //show Trusted CAs
        [self showTrustedCAs];
    }
    
    return 0;
}

- (void)stop {
    _stopAll = YES;
}

- (void)setGetSupportedClient: (BOOL)getSupportedClient testRenegotiation: (BOOL)testRenegotiation testCompression: (BOOL)testCompression testHeartbleed: (BOOL)testHeartbleed testServerSupported: (BOOL)testServerSupported showCertificate: (BOOL)showCertificate showTrustedCAs: (BOOL)showTrustedCAs {
    _getSupportedClientBoolean = getSupportedClient;
    _testRenegotiationBoolean = testRenegotiation;
    _testCompressionBoolean = testCompression;
    _testHeartbleedBoolean = testHeartbleed;
    _testServerSupportedBoolean = testServerSupported;
    _showCertificateBoolean = showCertificate;
    _showTrustedCAsBoolean = showTrustedCAs;
}

- (int)showTrustedCAs {
    // Variables...
    int cipherStatus = 0;
    int status = 0;
    int socketDescriptor = 0;
    SSL *ssl = NULL;
    BIO *cipherConnectionBio = NULL;
    //BIO *stdoutBIO = NULL;
    //BIO *fileBIO = NULL;
    const SSL_METHOD *sslMethod = NULL;
    char buffer[1024];
    int tempInt = 0;
    STACK_OF(X509_NAME) *sk2;
    X509_NAME *xn;
    
    
    // Connect to host
    socketDescriptor = [self tcpConnect];
    if (socketDescriptor != 0) {
        
        // Setup Context Object...
        /*if( options->sslVersion == ssl_v2 || options->sslVersion == ssl_v3) {
         printf_verbose("sslMethod = SSLv23_method()");
         sslMethod = SSLv23_method();
         }
         #if OPENSSL_VERSION_NUMBER >= 0x10001000L
         else if( options->sslVersion == tls_v11) {
         printf_verbose("sslMethod = TLSv1_1_method()");
         sslMethod = TLSv1_1_method();
         }
         else if( options->sslVersion == tls_v12) {
         printf_verbose("sslMethod = TLSv1_2_method()");
         sslMethod = TLSv1_2_method();
         }
         #endif
         else {
         printf_verbose("sslMethod = TLSv1_method()\n");
         printf_verbose("If server doesn't support TLSv1.0, manually specificy TLS version\n");
         sslMethod = TLSv1_method();
         }
         */
        sslMethod = TLSv1_method();
        SSL_CTX *ctx = SSL_CTX_new(sslMethod);
        if (ctx != NULL) {
            if (SSL_CTX_set_cipher_list(ctx, "ALL:COMPLEMENTOFALL") != 0) {
                // Load Certs if required...
                //if ((options->clientCertsFile != 0) || (options->privateKeyFile != 0))
                //  status = loadCerts(options);
                
                // Create SSL object...
                ssl = SSL_new(ctx);
                if (ssl != NULL) {
                    // Connect socket and BIO
                    cipherConnectionBio = BIO_new_socket(socketDescriptor, BIO_NOCLOSE);
                    
                    // Connect SSL and BIO
                    SSL_set_bio(ssl, cipherConnectionBio, cipherConnectionBio);
                    
#if OPENSSL_VERSION_NUMBER >= 0x0090806fL && !defined(OPENSSL_NO_TLSEXT)
                    // Based on http://does-not-exist.org/mail-archives/mutt-dev/msg13045.html
                    // TLS Virtual-hosting requires that the server present the correct
                    // certificate; to do this, the ServerNameIndication TLS extension is used.
                    // If TLS is negotiated, and OpenSSL is recent enough that it might have
                    // support, and support was enabled when OpenSSL was built, mutt supports
                    // sending the hostname we think we're connecting to, so a server can send
                    // back the correct certificate.
                    // NB: finding a server which uses this for IMAP is problematic, so this is
                    // untested.  Please report success or failure!  However, this code change
                    // has worked fine in other projects to which the contributor has added it,
                    // or HTTP usage.
                    SSL_set_tlsext_host_name (ssl, [_hostname UTF8String]);
#endif
                    
                    // Connect SSL over socket
                    cipherStatus = SSL_connect(ssl);
                    if (cipherStatus >= 0) {
                        sk2 = SSL_get_client_CA_list(ssl);
                        if ((sk2 != NULL) && (sk_X509_NAME_num(sk2) > 0)) {
                            NSMutableArray *trustedArray = [[NSMutableArray alloc] init];
                            for (tempInt = 0; tempInt < sk_X509_NAME_num(sk2); tempInt++) {
                                xn = sk_X509_NAME_value(sk2,tempInt);
                                X509_NAME_oneline(xn, buffer, sizeof(buffer));
                                [trustedArray addObject:[NSString stringWithUTF8String:buffer]];
                            }
                            
                            [self.delegate IJTSSLScanShowTrustedCAs:trustedArray];
                        }
                        // Disconnect SSL over socket
                        SSL_shutdown(ssl);
                    }
                    
                    // Free SSL object
                    SSL_free(ssl);
                }
                else {
                    status = -1;
                    char buf[1024];
                    [self.delegate IJTSSLScanShowTrustedCAsFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
                }
            }
            else {
                status = -1;
                char buf[1024];
                [self.delegate IJTSSLScanShowTrustedCAsFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
            }
            
            // Free CTX Object
            SSL_CTX_free(ctx);
        }
        
        // Error Creating Context Object
        else {
            status = -1;
            char buf[1024];
            [self.delegate IJTSSLScanShowTrustedCAsFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
        }
        
        // Disconnect from host
        close(socketDescriptor);
    }
    
    // Could not connect
    else
        status = -1;
    
    return status;
}

- (int)showCertificate {
    // Variables...
    int cipherStatus = 0;
    int status = true;
    int socketDescriptor = 0;
    SSL *ssl = NULL;
    BIO *cipherConnectionBio = NULL;
    X509 *x509Cert = NULL;
    EVP_PKEY *publicKey = NULL;
    const SSL_METHOD *sslMethod = NULL;
    ASN1_OBJECT *asn1Object = NULL;
    X509_EXTENSION *extension = NULL;
    char buffer[1024];
    unsigned char *data;
    long tempLong = 0;
    int tempInt = 0;
    int tempInt2 = 0;
    long verifyError = 0;
    
    
    // Connect to host
    socketDescriptor = [self tcpConnect];
    if (socketDescriptor != 0) {
        /*
         // Setup Context Object...
         if( options->sslVersion == ssl_v2 || options->sslVersion == ssl_v3) {
         printf_verbose("sslMethod = SSLv23_method()");
         sslMethod = SSLv23_method();
         }
         #if OPENSSL_VERSION_NUMBER >= 0x10001000L
         else if( options->sslVersion == tls_v11) {
         printf_verbose("sslMethod = TLSv1_1_method()");
         sslMethod = TLSv1_1_method();
         }
         else if( options->sslVersion == tls_v12) {
         printf_verbose("sslMethod = TLSv1_2_method()");
         sslMethod = TLSv1_2_method();
         }
         #endif
         else {
         printf_verbose("sslMethod = TLSv1_method()\n");
         printf_verbose("If server doesn't support TLSv1.0, manually specificy TLS version\n");
         sslMethod = TLSv1_method();
         }*/
        sslMethod = TLSv1_method();
        SSL_CTX *ctx = SSL_CTX_new(sslMethod);
        if (ctx != NULL) {
            if (SSL_CTX_set_cipher_list(ctx, "ALL:COMPLEMENTOFALL") != 0) {
                // Load Certs if required...
                //if ((options->clientCertsFile != 0) || (options->privateKeyFile != 0))
                //  status = loadCerts(options);
                
                // Create SSL object...
                ssl = SSL_new(ctx);
                if (ssl != NULL) {
                    
                    // Connect socket and BIO
                    cipherConnectionBio = BIO_new_socket(socketDescriptor, BIO_NOCLOSE);
                    
                    // Connect SSL and BIO
                    SSL_set_bio(ssl, cipherConnectionBio, cipherConnectionBio);
                    
#if OPENSSL_VERSION_NUMBER >= 0x0090806fL && !defined(OPENSSL_NO_TLSEXT)
                    // Based on http://does-not-exist.org/mail-archives/mutt-dev/msg13045.html
                    // TLS Virtual-hosting requires that the server present the correct
                    // certificate; to do this, the ServerNameIndication TLS extension is used.
                    // If TLS is negotiated, and OpenSSL is recent enough that it might have
                    // support, and support was enabled when OpenSSL was built, mutt supports
                    // sending the hostname we think we're connecting to, so a server can send
                    // back the correct certificate.
                    // NB: finding a server which uses this for IMAP is problematic, so this is
                    // untested.  Please report success or failure!  However, this code change
                    // has worked fine in other projects to which the contributor has added it,
                    // or HTTP usage.
                    SSL_set_tlsext_host_name (ssl, [_hostname UTF8String]);
#endif
                    
                    // Connect SSL over socket
                    cipherStatus = SSL_connect(ssl);
                    if (cipherStatus == 1) {
                        
                        x509Cert = SSL_get_peer_certificate(ssl);
                        
                        if (x509Cert != NULL) {
                            
                            NSString *certificate = @"";
                            long version = 0;
                            NSString *serialNumber = @"";
                            NSString *signatureAlgorithm = @"";
                            NSString *issuer = @"";
                            NSString *notValidBefore = @"";
                            NSString *notValidAfter = @"";
                            NSString *subject = @"";
                            NSString *publicKeyAlgorithm = @"";
                            int publicKeyLength = -1;
                            NSString *publicKeyString = @"";
                            NSString *publicKeyType = @"";
                            NSString *x509v3Extensions = @"";
                            NSString *verifyCertificate = @"";
                            
                            // Print a base64 blob version of the cert
                            //SSL_set_verify(ssl, SSL_VERIFY_NONE|SSL_VERIFY_CLIENT_ONCE, NULL);
                            
                            BIO *bio = BIO_new(BIO_s_mem());
                            PEM_write_bio_X509(bio, x509Cert);
                            tempLong = BIO_get_mem_data(bio, &data);
                            certificate = [[NSString alloc] initWithBytes:data length:tempLong encoding:NSUTF8StringEncoding];
                            BIO_free(bio); // free _after_ you no longer need data
                            
                            // Cert Version
                            if (!(X509_FLAG_COMPAT & X509_FLAG_NO_VERSION)) {
                                version = X509_get_version(x509Cert);
                            }
                            
                            // Cert Serial No. - Code adapted from OpenSSL's crypto/asn1/t_x509.c
                            if (!(X509_FLAG_COMPAT & X509_FLAG_NO_SERIAL)) {
                                ASN1_INTEGER *bs;
                                long l;
                                int i;
                                const char *neg;
                                bs = X509_get_serialNumber(x509Cert);
                                
                                if (bs->length <= 4) {
                                    l = ASN1_INTEGER_get(bs);
                                    if (l < 0) {
                                        l= -l;
                                        neg = "-";
                                    }
                                    else
                                        neg = "";
                                    
                                    serialNumber = [NSString stringWithFormat:@"%lu (%#lx)", l, l];
                                }
                                else {
                                    neg = (bs->type == V_ASN1_NEG_INTEGER)?" (Negative)":"";
                                    serialNumber = [NSString stringWithFormat:@"%s", neg];
                                    for (i = 0; i < bs->length; i++) {
                                        serialNumber = [serialNumber stringByAppendingString:[NSString stringWithFormat:@"%02x%c", bs->data[i], (i+1 == bs->length)?'\n':':']];
                                        
                                    }
                                }
                            }
                            
                            // Signature Algo...
                            if (!(X509_FLAG_COMPAT & X509_FLAG_NO_SIGNAME)) {
                                BIO *bio = BIO_new(BIO_s_mem());
                                i2a_ASN1_OBJECT(bio, x509Cert->cert_info->signature->algorithm);
                                tempLong = BIO_get_mem_data(bio, &data);
                                signatureAlgorithm = [[NSString alloc] initWithBytes:data length:tempLong encoding:NSUTF8StringEncoding];
                                BIO_free(bio); // free _after_ you no longer need data
                            }
                            
                            // SSL Certificate Issuer...
                            if (!(X509_FLAG_COMPAT & X509_FLAG_NO_ISSUER)) {
                                X509_NAME_oneline(X509_get_issuer_name(x509Cert), buffer, sizeof(buffer) - 1);
                                issuer = [NSString stringWithUTF8String:buffer];
                            }
                            
                            // Validity...
                            if (!(X509_FLAG_COMPAT & X509_FLAG_NO_VALIDITY)) {
                                BIO *bio = BIO_new(BIO_s_mem());
                                ASN1_TIME_print(bio, X509_get_notBefore(x509Cert));
                                tempLong = BIO_get_mem_data(bio, &data);
                                notValidBefore = [[NSString alloc] initWithBytes:data length:tempLong encoding:NSUTF8StringEncoding];
                                BIO_free(bio);
                                
                                bio = BIO_new(BIO_s_mem());
                                ASN1_TIME_print(bio, X509_get_notAfter(x509Cert));
                                tempLong = BIO_get_mem_data(bio, &data);
                                notValidAfter = [[NSString alloc] initWithBytes:data length:tempLong encoding:NSUTF8StringEncoding];
                                BIO_free(bio);
                            }
                            
                            // SSL Certificate Subject...
                            if (!(X509_FLAG_COMPAT & X509_FLAG_NO_SUBJECT)) {
                                X509_NAME_oneline(X509_get_subject_name(x509Cert), buffer, sizeof(buffer) - 1);
                                subject = [NSString stringWithUTF8String:buffer];
                            }
                            
                            // Public Key Algo...
                            if (!(X509_FLAG_COMPAT & X509_FLAG_NO_PUBKEY)) {
                                BIO *bio = BIO_new(BIO_s_mem());
                                i2a_ASN1_OBJECT(bio, x509Cert->cert_info->key->algor->algorithm);
                                tempLong = BIO_get_mem_data(bio, &data);
                                publicKeyAlgorithm = [[NSString alloc] initWithBytes:data length:tempLong encoding:NSUTF8StringEncoding];
                                BIO_free(bio);
                                
                                // Public Key...
                                publicKey = X509_get_pubkey(x509Cert);
                                if (publicKey == NULL) {
                                    publicKeyString = @"Could not load";
                                }
                                else {
                                    switch (publicKey->type) {
                                        case EVP_PKEY_RSA:
                                            
                                            publicKeyType = @"RSA";
                                            
                                            if (publicKey->pkey.rsa) {
                                                publicKeyLength = BN_num_bits(publicKey->pkey.rsa->n);
                                                BIO *bio = BIO_new(BIO_s_mem());
                                                RSA_print(bio, publicKey->pkey.rsa, 0);
                                                tempLong = BIO_get_mem_data(bio, &data);
                                                publicKeyString = [[NSString alloc] initWithBytes:data length:tempLong encoding:NSUTF8StringEncoding];
                                                BIO_free(bio);
                                            }
                                            break;
                                        case EVP_PKEY_DSA:
                                            
                                            publicKeyType = @"DSA";
                                            
                                            if (publicKey->pkey.dsa) {
                                                BIO *bio = BIO_new(BIO_s_mem());
                                                DSA_print(bio, publicKey->pkey.dsa, 0);
                                                tempLong = BIO_get_mem_data(bio, &data);
                                                publicKeyString = [[NSString alloc] initWithBytes:data length:tempLong encoding:NSUTF8StringEncoding];
                                                BIO_free(bio);
                                            }
                                            break;
                                        case EVP_PKEY_EC:
                                            publicKeyType = @"EC";
                                            
                                            if (publicKey->pkey.ec)  {
                                                BIO *bio = BIO_new(BIO_s_mem());
                                                EC_KEY_print(bio, publicKey->pkey.ec, 0);
                                                tempLong = BIO_get_mem_data(bio, &data);
                                                publicKeyString = [[NSString alloc] initWithBytes:data length:tempLong encoding:NSUTF8StringEncoding];
                                                BIO_free(bio);
                                            }
                                            break;
                                        default:
                                            publicKeyType = @"Unknown";
                                            break;
                                    }
                                    
                                    EVP_PKEY_free(publicKey);
                                }
                            }
                            
                            // X509 v3...
                            if (!(X509_FLAG_COMPAT & X509_FLAG_NO_EXTENSIONS)) {
                                BIO *bio = BIO_new(BIO_s_mem());
                                if (sk_X509_EXTENSION_num(x509Cert->cert_info->extensions) > 0) {
                                    for (tempInt = 0; tempInt < sk_X509_EXTENSION_num(x509Cert->cert_info->extensions); tempInt++) {
                                        // Get Extension...
                                        extension = sk_X509_EXTENSION_value(x509Cert->cert_info->extensions, tempInt);
                                        
                                        asn1Object = X509_EXTENSION_get_object(extension);
                                        i2a_ASN1_OBJECT(bio, asn1Object);
                                        tempInt2 = X509_EXTENSION_get_critical(extension);
                                        BIO_printf(bio, ": %s\n", tempInt2 ? "critical" : "");
                                        
                                        // Print Extension value...
                                        if (!X509V3_EXT_print(bio, extension, X509_FLAG_COMPAT, 8)) {
                                            M_ASN1_OCTET_STRING_print(bio, extension->value);
                                        }
                                        BIO_printf(bio, "\n");
                                    }//end for
                                }//end if
                                
                                tempLong = BIO_get_mem_data(bio, &data);
                                x509v3Extensions = [[NSString alloc] initWithBytes:data length:tempLong encoding:NSUTF8StringEncoding];
                                BIO_free(bio); // free _after_ you no longer need data
                            }//end if x509v3
                            
                            // Verify Certificate...
                            verifyError = SSL_get_verify_result(ssl);
                            if (verifyError == X509_V_OK)
                                verifyCertificate = @"Certificate passed verification";
                            else
                                verifyCertificate = [NSString stringWithUTF8String:X509_verify_cert_error_string(verifyError)];
                            
                            // Free X509 Certificate...
                            X509_free(x509Cert);
                            
                            [self.delegate IJTSSLScanShowCertificate:certificate
                                                              verion:version
                                                        serialNumber:serialNumber
                                                  signatureAlgorithm:signatureAlgorithm
                                                              issuer:issuer
                                                      notValidBefore:notValidBefore
                                                       notValidAfter:notValidAfter
                                                             subject:subject
                                                  publicKeyAlgorithm:publicKeyAlgorithm
                                                     publicKeyLength:publicKeyLength
                                                       publicKeyType:publicKeyType
                                                     publicKeyString:publicKeyString
                                                    x509v3Extensions:x509v3Extensions
                                                   verifyCertificate:verifyCertificate];
                        }//end if
                        else {
                            [self.delegate IJTSSLScanShowCertificateFailure:@"Unable to parse certificate"];
                        }//end else
                        // Disconnect SSL over socket
                        SSL_shutdown(ssl);
                    }//end else
                    
                    // Free SSL object
                    SSL_free(ssl);
                }
                else {
                    status = -1;
                    char buf[1024];
                    [self.delegate IJTSSLScanShowCertificateFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
                }
            }
            else {
                status = -1;
                char buf[1024];
                [self.delegate IJTSSLScanShowCertificateFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
            }
            
            // Free CTX Object
            SSL_CTX_free(ctx);
        }
        
        // Error Creating Context Object
        else {
            status = -1;
            char buf[1024];
            [self.delegate IJTSSLScanShowCertificateFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
        }
        
        // Disconnect from host
        close(socketDescriptor);
    }
    
    // Could not connect
    else
        status = -1;
    
    return status;
}

- (int)testProtocolCiphers: (SSL_METHOD *)sslMethod {
    int status;
    status = 0;
    char cipherstring[65536] = {};
    
    strncpy(cipherstring, "ALL:eNULL", 10);
    
    // Loop until the server won't accept any more ciphers
    while (status == 0) {
        
        if(_stopAll)
            break;
        
        // Setup Context Object...
        SSL_CTX *ctx = SSL_CTX_new(sslMethod);
        if (ctx != NULL) {
            
            // SSL implementation bugs/workaround
            /*if (options->sslbugs)
             SSL_CTX_set_options(ctx, SSL_OP_ALL | 0);
             else*/
            SSL_CTX_set_options(ctx, 0);
            
            // Load Certs if required...
            //if ((options->clientCertsFile != 0) || (options->privateKeyFile != 0))
            //  status = loadCerts(options);
            
            // Test the cipher
            if (status == 0)
                status = [self testCipher:sslMethod cipherstring:cipherstring ctx:ctx];
            
            // Free CTX Object
            SSL_CTX_free(ctx);
        }
        
        // Error Creating Context Object
        else {
            char buf[1024];
            [self.delegate IJTSSLScanTestSupportedServerCiphersFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
            return -1;
        }
    }
    return 0;
}

- (int)testCipher: (SSL_METHOD *)sslMethod cipherstring: (char *)cipherstring ctx: (SSL_CTX *)ctx {
    // Variables...
    int cipherStatus;
    int status = 0;
    int socketDescriptor = 0;
    SSL *ssl = NULL;
    BIO *cipherConnectionBio;
    char requestBuffer[200];
    char hexCipherId[10];
    int cipherbits;
    uint32_t cipherid;
    const SSL_CIPHER *sslCipherPointer;
    const char *cleanSslMethod = printableSslMethod(sslMethod);
    
    
    // Create request buffer...
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *majorVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    memset(requestBuffer, 0, 200);
    snprintf(requestBuffer, 199, "GET / HTTP/1.0\r\nUser-Agent: Injector-%s\r\nHost: %s\r\n\r\n", [majorVersion UTF8String], [_hostname UTF8String]);
    
    // Connect to host
    socketDescriptor = [self tcpConnect];
    if (socketDescriptor != -1) {
        if (SSL_CTX_set_cipher_list(ctx, cipherstring) != 0) {
            
            // Create SSL object...
            ssl = SSL_new(ctx);
            
            
            if (ssl != NULL) {
                // Connect socket and BIO
                cipherConnectionBio = BIO_new_socket(socketDescriptor, BIO_NOCLOSE);
                
                // Connect SSL and BIO
                SSL_set_bio(ssl, cipherConnectionBio, cipherConnectionBio);
                
#if OPENSSL_VERSION_NUMBER >= 0x0090806fL && !defined(OPENSSL_NO_TLSEXT)
                // This enables TLS SNI
                SSL_set_tlsext_host_name (ssl, [_hostname UTF8String]);
#endif
                
                // Connect SSL over socket
                cipherStatus = SSL_connect(ssl);
                
                sslCipherPointer = SSL_get_current_cipher(ssl);
                cipherbits = SSL_CIPHER_get_bits(sslCipherPointer, NULL);
                
                if (cipherStatus == 0) {
                    SSL_free(ssl);
                    return -1;
                }
                else if (cipherStatus != 1) {
                    char buf[1024];
                    [self.delegate IJTSSLScanTestSupportedServerCiphersFailure:[NSString stringWithUTF8String:ERR_error_string(SSL_get_error(ssl, cipherStatus), buf)]];
                    SSL_free(ssl);
                    return -1;
                }
                
                cipherid = (u_int32_t)SSL_CIPHER_get_id(sslCipherPointer);
                cipherid = cipherid & 0x00ffffff;  // remove first byte which is the version (0x03 for TLSv1/SSLv3)
                
                // Show Cipher Status
                BOOL preferred = NO;
                NSString *version = @"";
                if (cipherStatus == 1) {
                    if (strcmp(cipherstring, "ALL:eNULL")) {
                        preferred = NO;
                    }
                    else {
                        preferred = YES;
                    }
                    
                }
#ifndef OPENSSL_NO_SSL2
                if (strcmp(cleanSslMethod, "SSLv2") == 0) {
                    version = @"SSLv2";
                }
                else
#endif
#ifndef OPENSSL_NO_SSL3
                    if (strcmp(cleanSslMethod, "SSLv3") == 0) {
                        version = @"SSLv3";
                    }
                    else
#endif
                        if (strcmp(cleanSslMethod, "TLSv1.0") == 0) {
                            version = @"TLSv1.0";
                        }
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
                        else {
                            version = [NSString stringWithUTF8String:cleanSslMethod];
                        }
#endif
                
                sprintf(hexCipherId, "0x%X", cipherid);
                
                [self.delegate IJTSSLScanTestSupportedServerCiphersResultVersion:version preferred:preferred bits:cipherbits cipherId:[NSString stringWithUTF8String:hexCipherId] cipher:[NSString stringWithUTF8String:sslCipherPointer->name] cipher_details:[self ssl_tmp_key:ssl]];
                
                // Disconnect SSL over socket
                if (cipherStatus == 1) {
                    strncat(cipherstring, ":!", 2);
                    strncat(cipherstring, SSL_get_cipher_name(ssl), strlen(SSL_get_cipher_name(ssl)));
                    SSL_shutdown(ssl);
                }
                
                // Free SSL object
                SSL_free(ssl);
            }
            else
            {
                status = -1;
                char buf[1024];
                [self.delegate IJTSSLScanTestSupportedServerCiphersFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
            }
        }
        else {
            status = -1;
        }
        
        // Disconnect from host
        close(socketDescriptor);
    }
    
    // Could not connect
    else
        status = -1;
    
    return status;
}

- (int)testHeartbleed: (SSL_METHOD *)sslMethod {
    // Variables...
    int status = true;
    int socketDescriptor = 0;
    
    // Connect to host
    socketDescriptor = [self tcpConnect];
    
    
    if (socketDescriptor != -1) {
        
        // Credit to Jared Stafford (jspenguin@jspenguin.org)
        char hello[] = {0x16,0x03,0x00,0x00,0xdc,0x01,0x00,0x00,0xd8,0x03,0x02,0x53,0x43,0x5b,0x90,0x9d,0x9b,0x72,0x0b,0xbc,0x0c,0xbc,0x2b,0x92,0xa8,0x48,0x97,0xcf,0xbd,0x39,0x04,0xcc,0x16,0x0a,0x85,0x03,0x90,0x9f,0x77,0x04,0x33,0xd4,0xde,0x00,0x00,0x66,0xc0,0x14,0xc0,0x0a,0xc0,0x22,0xc0,0x21,0x00,0x39,0x00,0x38,0x00,0x88,0x00,0x87,0xc0,0x0f,0xc0,0x05,0x00,0x35,0x00,0x84,0xc0,0x12,0xc0,0x08,0xc0,0x1c,0xc0,0x1b,0x00,0x16,0x00,0x13,0xc0,0x0d,0xc0,0x03,0x00,0x0a,0xc0,0x13,0xc0,0x09,0xc0,0x1f,0xc0,0x1e,0x00,0x33,0x00,0x32,0x00,0x9a,0x00,0x99,0x00,0x45,0x00,0x44,0xc0,0x0e,0xc0,0x04,0x00,0x2f,0x00,0x96,0x00,0x41,0xc0,0x11,0xc0,0x07,0xc0,0x0c,0xc0,0x02,0x00,0x05,0x00,0x04,0x00,0x15,0x00,0x12,0x00,0x09,0x00,0x14,0x00,0x11,0x00,0x08,0x00,0x06,0x00,0x03,0x00,0xff,0x01,0x00,0x00,0x49,0x00,0x0b,0x00,0x04,0x03,0x00,0x01,0x02,0x00,0x0a,0x00,0x34,0x00,0x32,0x00,0x0e,0x00,0x0d,0x00,0x19,0x00,0x0b,0x00,0x0c,0x00,0x18,0x00,0x09,0x00,0x0a,0x00,0x16,0x00,0x17,0x00,0x08,0x00,0x06,0x00,0x07,0x00,0x14,0x00,0x15,0x00,0x04,0x00,0x05,0x00,0x12,0x00,0x13,0x00,0x01,0x00,0x02,0x00,0x03,0x00,0x0f,0x00,0x10,0x00,0x11,0x00,0x23,0x00,0x00,0x00,0x0f,0x00,0x01,0x01};
        
        if (sslMethod == TLSv1_client_method()) {
            hello[2] = 0x01;
        }
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
        else if (sslMethod == TLSv1_1_client_method()) {
            hello[2] = 0x02;
        }
        else if (sslMethod == TLSv1_2_client_method()) {
            hello[2] = 0x03;
        }
#endif
        if (send(socketDescriptor, hello, sizeof(hello), 0) <= 0) {
            [self.delegate IJTSSLScanTestHeartbleedFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        
        // Send the heartbeat
        char hb[8] = {0x18,0x03,0x00,0x00,0x03,0x01,0x40,0x00};
        if (sslMethod == TLSv1_client_method()) {
            hb[2] = 0x01;
        }
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
        else if (sslMethod == TLSv1_1_client_method()) {
            hb[2] = 0x02;
        }
        else if (sslMethod == TLSv1_2_client_method()) {
            hb[2] = 0x03;
        }
#endif
        if (send(socketDescriptor, hb, sizeof(hb), 0) <= 0) {
            [self.delegate IJTSSLScanTestHeartbleedFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        
        char hbbuf[65536];
        
        while(1) {
            memset(hbbuf, 0, sizeof(hbbuf));
            
            // Read 5 byte header
            int readResult = (int)recv(socketDescriptor, hbbuf, 5, 0);
            if (readResult <= 0) {
                break;
            }
            
            char typ = hbbuf[0];
            
            // Combine 2 bytes to get payload length
            uint16_t ln = hbbuf[4] | hbbuf[3] << 8; //just like ntohs
            
            memset(hbbuf, 0, sizeof(hbbuf));
            
            // Read rest of record
            readResult = (int)recv(socketDescriptor, hbbuf, ln, 0);
            if (readResult <= 0) {
                break;
            }
            
            // Server returned error
            if (typ == 21) {
                break;
            }
            // Successful response
            else if (typ == 24 && ln > 3) {
                [self.delegate IJTSSLScanTestHeartbleedResultVersion:[NSString stringWithUTF8String:printableSslMethod(sslMethod)] vulnerable:YES];
                close(socketDescriptor);
                return 0;
            }
        }
        [self.delegate IJTSSLScanTestHeartbleedResultVersion:[NSString stringWithUTF8String:printableSslMethod(sslMethod)] vulnerable:NO];
        
        // Disconnect from host
        close(socketDescriptor);
    }
    else {
        // Could not connect
        return -1;
    }
    
    return status;
}

- (int)testCompression: (SSL_METHOD *)sslMethod {
    // Variables...
    int status = 0;
    int socketDescriptor = 0;
    SSL *ssl = NULL;
    BIO *cipherConnectionBio;
    SSL_SESSION session;
    int use_unsafe_renegotiation_flag = 0;
    int use_unsafe_renegotiation_op = 0;
    
    // Connect to host
    socketDescriptor = [self tcpConnect];
    if (socketDescriptor != -1) {
        // Setup Context Object...
        SSL_CTX *ctx = SSL_CTX_new(sslMethod);
        tls_reneg_init(ctx, &use_unsafe_renegotiation_flag, &use_unsafe_renegotiation_op);
        if (ctx != NULL)  {
            if (SSL_CTX_set_cipher_list(ctx, "ALL:COMPLEMENTOFALL") != 0) {
                
                // Load Certs if required...
                //if ((options->clientCertsFile != 0) || (options->privateKeyFile != 0))
                //  status = loadCerts(options);
                
                // Create SSL object...
                ssl = SSL_new(ctx);
                
#if ( OPENSSL_VERSION_NUMBER > 0x009080cfL )
                // Make sure we can connect to insecure servers
                // OpenSSL is going to change the default at a later date
                SSL_set_options(ssl, SSL_OP_LEGACY_SERVER_CONNECT);
#endif
                
                if (ssl != NULL) {
                    // Connect socket and BIO
                    cipherConnectionBio = BIO_new_socket(socketDescriptor, BIO_NOCLOSE);
                    
                    // Connect SSL and BIO
                    SSL_set_bio(ssl, cipherConnectionBio, cipherConnectionBio);
                    
#if OPENSSL_VERSION_NUMBER >= 0x0090806fL && !defined(OPENSSL_NO_TLSEXT)
                    // This enables TLS SNI
                    SSL_set_tlsext_host_name(ssl, [_hostname UTF8String]);
#endif
                    
                    // Connect SSL over socket
                    SSL_connect(ssl);
                    
                    session = *SSL_get_session(ssl);
                    
#ifndef OPENSSL_NO_COMP
                    
                    if (session.compress_meth == 0) {
                        [self.delegate IJTSSLScanTestCompressionResultMessage:@"Compression disabled" disable:YES];
                    }
                    else {
                        [self.delegate IJTSSLScanTestCompressionResultMessage:@"Compression enabled" disable:NO];
                    }
#endif
                    
                    // Disconnect SSL over socket
                    SSL_shutdown(ssl);
                    
                    // Free SSL object
                    SSL_free(ssl);
                }
                else {
                    status = -1;
                    char buf[1024];
                    [self.delegate IJTSSLScanTestCompressionFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
                }
            }
            else {
                status = -1;
                char buf[1024];
                [self.delegate IJTSSLScanTestCompressionFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
            }
            // Free CTX Object
            SSL_CTX_free(ctx);
        }
        // Error Creating Context Object
        else {
            status = -1;
            char buf[1024];
            [self.delegate IJTSSLScanTestCompressionFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
        }
        
        // Disconnect from host
        close(socketDescriptor);
    }
    else {
        // Could not connect
        return -1;
    }
    
    return status;
}

- (int)testRenegotiation: (SSL_METHOD *)sslMethod {
    // Variables...
    int cipherStatus;
    int status = 0;
    int socketDescriptor = 0;
    int res;
    SSL *ssl = NULL;
    BIO *cipherConnectionBio;
    struct renegotiationOutput *renOut = newRenegotiationOutput();
    int use_unsafe_renegotiation_flag = 0;
    int use_unsafe_renegotiation_op = 0;
    
    // Connect to host
    socketDescriptor = [self tcpConnect];
    if (socketDescriptor != -1) {
        
        // Setup Context Object...
        SSL_CTX *ctx = SSL_CTX_new(sslMethod);
        tls_reneg_init(ctx, &use_unsafe_renegotiation_flag, &use_unsafe_renegotiation_op);
        if (ctx != NULL)
        {
            if (SSL_CTX_set_cipher_list(ctx, "ALL:COMPLEMENTOFALL") != 0) {
                
                // Load Certs if required...
                //if ((options->clientCertsFile != 0) || (options->privateKeyFile != 0))
                //  status = loadCerts(options);
                
                // Create SSL object...
                ssl = SSL_new(ctx);
                
#if ( OPENSSL_VERSION_NUMBER > 0x009080cfL )
                // Make sure we can connect to insecure servers
                // OpenSSL is going to change the default at a later date
                SSL_set_options(ssl, SSL_OP_LEGACY_SERVER_CONNECT);
#endif
                
                if (ssl != NULL) {
                    // Connect socket and BIO
                    cipherConnectionBio = BIO_new_socket(socketDescriptor, BIO_NOCLOSE);
                    
                    // Connect SSL and BIO
                    SSL_set_bio(ssl, cipherConnectionBio, cipherConnectionBio);
                    
#if OPENSSL_VERSION_NUMBER >= 0x0090806fL && !defined(OPENSSL_NO_TLSEXT)
                    // This enables TLS SNI
                    // Based on http://does-not-exist.org/mail-archives/mutt-dev/msg13045.html
                    // TLS Virtual-hosting requires that the server present the correct
                    // certificate; to do this, the ServerNameIndication TLS extension is used.
                    // If TLS is negotiated, and OpenSSL is recent enough that it might have
                    // support, and support was enabled when OpenSSL was built, mutt supports
                    // sending the hostname we think we're connecting to, so a server can send
                    // back the correct certificate.
                    // NB: finding a server which uses this for IMAP is problematic, so this is
                    // untested.  Please report success or failure!  However, this code change
                    // has worked fine in other projects to which the contributor has added it,
                    // or HTTP usage.
                    SSL_set_tlsext_host_name(ssl, [_hostname UTF8String]);
#endif
                    
                    // Connect SSL over socket
                    cipherStatus = SSL_connect(ssl);
                    
#ifndef SSL3_FLAGS_ALLOW_UNSAFE_LEGACY_RENEGOTIATION
#    define SSL3_FLAGS_ALLOW_UNSAFE_LEGACY_RENEGOTIATION 0x0010
#endif
                    /* Yes, we know what we are doing here.  No, we do not treat a renegotiation
                     * as authenticating any earlier-received data. */
                    if (use_unsafe_renegotiation_flag) {
                        ssl->s3->flags |= SSL3_FLAGS_ALLOW_UNSAFE_LEGACY_RENEGOTIATION;
                    }
                    if (use_unsafe_renegotiation_op) {
                        SSL_set_options(ssl,
                                        SSL_OP_ALLOW_UNSAFE_LEGACY_RENEGOTIATION);
                    }
                    
                    
                    if (cipherStatus == 1) {
                        
#if ( OPENSSL_VERSION_NUMBER > 0x009080cfL )
                        // SSL_get_secure_renegotiation_support() appeared first in OpenSSL 0.9.8m
                        renOut->secure = (int)SSL_get_secure_renegotiation_support(ssl);
                        if( renOut->secure ) {
                            // If it supports secure renegotiations,
                            // it should have renegotiation support in general
                            renOut->supported = 1;
                            status = 0;
                        }
                        else {
#endif
                            // We can't assume that just because the secure renegotiation
                            // support failed the server doesn't support insecure renegotiations·
                            
                            // assume ssl is connected and error free up to here
                            //setBlocking(ssl); // this is unnecessary if it is already blocking·
                            //printf_verbose("Attempting SSL_renegotiate(ssl)\n");
                            SSL_renegotiate(ssl); // Ask to renegotiate the connection
                            // This hangs when an 'encrypted alert' is sent by the server
                            //printf_verbose("Attempting SSL_do_handshake(ssl)\n");
                            SSL_do_handshake(ssl); // Send renegotiation request to server //TODO :: XXX hanging here
                            
                            if (ssl->state == SSL_ST_OK) {
                                res = SSL_do_handshake(ssl); // Send renegotiation request to server
                                if( res != 1 ) {
                                    char buf[1024];
                                    [self.delegate IJTSSLScanTestRenegotiationFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
                                }
                                if (ssl->state == SSL_ST_OK) {
                                    /* our renegotiation is complete */
                                    renOut->supported = 1;
                                    status = 0;
                                } else {
                                    renOut->supported = 0;
                                    status = -1;
                                    char buf[1024];
                                    [self.delegate IJTSSLScanTestRenegotiationFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
                                }
                            } else {
                                status = -1;
                                renOut->secure = 0;
                            }
#if ( OPENSSL_VERSION_NUMBER > 0x009080cfL )
                        }
#endif
                        // Disconnect SSL over socket
                        SSL_shutdown(ssl);
                    }
                    
                    // Free SSL object
                    SSL_free(ssl);
                }
                else {
                    status = -1;
                    renOut->supported = 0;
                    char buf[1024];
                    [self.delegate IJTSSLScanTestRenegotiationFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
                }
            }
            else
            {
                status = -1;
                renOut->supported = 0;
                char buf[1024];
                [self.delegate IJTSSLScanTestRenegotiationFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
            }
            // Free CTX Object
            SSL_CTX_free(ctx);
        }
        // Error Creating Context Object
        else
        {
            status = -1;
            renOut->supported = 0;
            char buf[1024];
            [self.delegate IJTSSLScanTestRenegotiationFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
        }
        
        // Disconnect from host
        close(socketDescriptor);
    }
    else {
        // Could not connect
        renOut->supported = 0;
        freeRenegotiationOutput(renOut);
        return -1;
    }
    
    NSString *message = @"";
    BOOL insecure = NO;
    if (renOut->secure)
        message = @"Secure session renegotiation supported";
    else if (renOut->supported) {
        message = @"Insecure session renegotiation supported";
        insecure = YES;
    }
    else
        message = @"Session renegotiation not supported";
    
    [self.delegate IJTSSLScanTestRenegotiationResultMessage:message insecure:insecure];
    
    freeRenegotiationOutput(renOut);
    
    return status;
}

-(NSString *)ssl_tmp_key: (SSL *)s {
#if OPENSSL_VERSION_NUMBER >= 0x10002000L && !defined(LIBRESSL_VERSION_NUMBER)
    EVP_PKEY *key;
    NSString *keyString = @"";
    
    if (!SSL_get_server_tmp_key(s, &key))
        return keyString;
    switch (EVP_PKEY_id(key)) {
        case EVP_PKEY_RSA:
            keyString = [NSString stringWithFormat:@"RSA %d bits", EVP_PKEY_bits(key)];
            break;
            
        case EVP_PKEY_DH:
            keyString = [NSString stringWithFormat:@"DHE %d bits", EVP_PKEY_bits(key)];
            break;
#ifndef OPENSSL_NO_EC
        case EVP_PKEY_EC: {
            EC_KEY *ec = EVP_PKEY_get1_EC_KEY(key);
            int nid;
            const char *cname;
            nid = EC_GROUP_get_curve_name(EC_KEY_get0_group(ec));
            EC_KEY_free(ec);
            cname = EC_curve_nid2nist(nid);
            if (!cname)
                cname = OBJ_nid2sn(nid);
            keyString = [NSString stringWithFormat:@"Curve %s DHE %d", cname, EVP_PKEY_bits(key)];
        }
#endif
    }
    EVP_PKEY_free(key);
    return keyString;
#endif
    return keyString;
}

static void tls_reneg_init(SSL_CTX *ctx, int *use_unsafe_renegotiation_flag, int *use_unsafe_renegotiation_op) {
    /* Borrowed from tortls.c to dance with OpenSSL on many platforms, with
     * many versions and release of OpenSSL. */
    SSL_library_init();
    SSL_load_error_strings();
    
    long version = SSLeay();
    if (version >= 0x009080c0L && version < 0x009080d0L) {
        *use_unsafe_renegotiation_flag = 1;
        *use_unsafe_renegotiation_op = 1;
    } else if (version >= 0x009080d0L) {
        *use_unsafe_renegotiation_op = 1;
    } else if (version < 0x009080c0L) {
        *use_unsafe_renegotiation_flag = 1;
        *use_unsafe_renegotiation_op = 1;
    }
    
#ifdef SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION
    SSL_CTX_set_options(ctx,
                        SSL_OP_NO_SESSION_RESUMPTION_ON_RENEGOTIATION);
#endif
}

static const char* printableSslMethod(const SSL_METHOD *sslMethod) {
#ifndef OPENSSL_NO_SSL2
    if (sslMethod == SSLv2_client_method())
        return "SSLv2";
#endif
#ifndef OPENSSL_NO_SSL3
    if (sslMethod == SSLv3_client_method())
        return "SSLv3";
#endif
    if (sslMethod == TLSv1_client_method())
        return "TLSv1.0";
#if OPENSSL_VERSION_NUMBER >= 0x10001000L
    if (sslMethod == TLSv1_1_client_method())
        return "TLSv1.1";
    if (sslMethod == TLSv1_2_client_method())
        return "TLSv1.2";
#endif
    return "unknown SSL_METHOD";
}

static struct renegotiationOutput *newRenegotiationOutput(void) {
    struct renegotiationOutput *myRenOut;
    myRenOut = calloc(1, sizeof(struct renegotiationOutput));
    return (myRenOut);
}

static int freeRenegotiationOutput(struct renegotiationOutput *myRenOut) {
    if (myRenOut != NULL) {
        free(myRenOut);
    }
    return 0;
}

- (int)populateCipherList: (const SSL_METHOD *)sslMethod ciphers: (struct sslCipher **)ciphers {
    struct sslCipher *sslCipherPointer;
    int tempInt;
    int loop;
    char buf[1024];
    
    // STACK_OF is a sign that you should be using C++ :)
    STACK_OF(SSL_CIPHER) *cipherList;
    SSL *ssl = NULL;
    SSL_CTX *ctx = SSL_CTX_new((SSL_METHOD *)sslMethod);
    if (ctx == NULL) {
        [self.delegate IJTSSLScanPopulateCipherFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
        return -1;
    }
    SSL_CTX_set_cipher_list(ctx, "ALL:COMPLEMENTOFALL");
    ssl = SSL_new(ctx);
    if (ssl == NULL) {
        [self.delegate IJTSSLScanPopulateCipherFailure:[NSString stringWithUTF8String:ERR_error_string(ERR_get_error(), buf)]];
        SSL_CTX_free(ctx);
        return -1;
    }
    cipherList = SSL_get_ciphers(ssl);
    // Create Cipher Struct Entries...
    for (loop = 0; loop < sk_SSL_CIPHER_num(cipherList); loop++)
    {
        if (*ciphers == NULL) {
            *ciphers = malloc(sizeof(struct sslCipher));
            sslCipherPointer = *ciphers;
        }
        else {
            //queue
            sslCipherPointer = *ciphers;
            while (sslCipherPointer->next != 0)
                sslCipherPointer = sslCipherPointer->next;
            sslCipherPointer->next = malloc(sizeof(struct sslCipher));
            sslCipherPointer = sslCipherPointer->next;
        }
        // Init
        memset(sslCipherPointer, 0, sizeof(struct sslCipher));
        // Add cipher information...
        sslCipherPointer->sslMethod = sslMethod;
        sslCipherPointer->name = SSL_CIPHER_get_name(sk_SSL_CIPHER_value(cipherList, loop));
        sslCipherPointer->version = SSL_CIPHER_get_version(sk_SSL_CIPHER_value(cipherList, loop));
        SSL_CIPHER_description(sk_SSL_CIPHER_value(cipherList, loop), sslCipherPointer->description, sizeof(sslCipherPointer->description) - 1);
        sslCipherPointer->bits = SSL_CIPHER_get_bits(sk_SSL_CIPHER_value(cipherList, loop), &tempInt);
    }
    SSL_free(ssl);
    SSL_CTX_free(ctx);
    return 0;
}

/**
 * 開啟tcp connect
 */
- (int)tcpConnect {
    // Variables...
    int socketDescriptor;
    int n = 1;
    
    // Create Socket
    socketDescriptor = socket(_family, SOCK_STREAM, IPPROTO_TCP);
    
    if(socketDescriptor < 0) {
        [self.delegate IJTSSLScanCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
        return -1;
    }
    
    setsockopt(socketDescriptor, SOL_SOCKET, SO_RCVTIMEO, (char *)&_timeout, sizeof(struct timeval));
    setsockopt(socketDescriptor, SOL_SOCKET, SO_SNDTIMEO, (char *)&_timeout, sizeof(struct timeval));
    setsockopt(socketDescriptor, SOL_SOCKET, SO_REUSEADDR, &n, sizeof(n));
    
    int oldFlags = fcntl(socketDescriptor, F_GETFL, NULL);
    if(oldFlags < 0) {
        [self.delegate IJTSSLScanCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
        close(socketDescriptor);
        return -1;
    }//end if
    oldFlags |= O_NONBLOCK;
    if(fcntl(socketDescriptor, F_SETFL, oldFlags) < 0) {
        [self.delegate IJTSSLScanCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
        close(socketDescriptor);
        return -1;
    }//end if
    
    // Connect
    if (_family == AF_INET) {
        connect(socketDescriptor, (struct sockaddr *)&_sin4, sizeof(_sin4));
    }
    else {    // IPv6
        connect(socketDescriptor, (struct sockaddr *)&_sin6, sizeof(_sin6));
    }
    
    while(1) {
        fd_set fd;
        struct timespec tv = {};
        int n = 0;
        
        FD_ZERO(&fd);
        FD_SET(socketDescriptor, &fd);
        tv.tv_sec = _timeout.tv_sec;
        tv.tv_nsec = _timeout.tv_usec * 1000;
        
        if ((n = pselect(socketDescriptor + 1, NULL, &fd, NULL, &tv, NULL)) < 0) {
            [self.delegate IJTSSLScanCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        if(n == 0) {
            [self.delegate IJTSSLScanConnectTimeout];
            close(socketDescriptor);
            return -1;
        }//end if timeout
        if(!FD_ISSET(socketDescriptor, &fd))
            continue;
        
        //connected
        //disable block
        int oldFlags = fcntl(socketDescriptor, F_GETFL, NULL);
        if(oldFlags < 0) {
            [self.delegate IJTSSLScanCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        oldFlags &= ~O_NONBLOCK;
        if(fcntl(socketDescriptor, F_SETFL, oldFlags) < 0) {
            [self.delegate IJTSSLScanCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        
        int val;
        int len = sizeof(val);
        getsockopt(socketDescriptor, SOL_SOCKET, SO_ERROR, (void *)&val, (socklen_t *)&len);
        
        if(val == 0) {
            return socketDescriptor;
        }
        else {
            errno = val;
            [self.delegate IJTSSLScanCreateSocketFailure:[NSString stringWithUTF8String:strerror(errno)]];
            close(socketDescriptor);
            return -1;
        }
        
        break;
    }//end while
}

@end
