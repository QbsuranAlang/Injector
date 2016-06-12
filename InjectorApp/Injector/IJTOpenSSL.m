//
//  IJTOpenSSL.m
//  Injector
//
//  Created by 聲華 陳 on 2015/11/5.
//  Copyright (c) 2015年 Qbsuran Alang. All rights reserved.
//

#import "IJTOpenSSL.h"
#import <openssl/md5.h>
#import <openssl/sha.h>
#import <openssl/evp.h>

#include <openssl/pem.h>
#include <openssl/conf.h>
#include <openssl/x509v3.h>
#ifndef OPENSSL_NO_ENGINE
# include <openssl/engine.h>
#endif

@implementation IJTOpenSSL

+ (NSString *)md5FromString:(NSString *)string {
    unsigned char *inStrg = (unsigned char *) [[string dataUsingEncoding:NSASCIIStringEncoding] bytes];
    unsigned long lngth = [string length];
    unsigned char result[MD5_DIGEST_LENGTH];
    NSMutableString *outStrg = [NSMutableString string];
    
    MD5(inStrg, lngth, result);
    
    unsigned int i;
    for (i = 0; i < MD5_DIGEST_LENGTH; i++) {
        [outStrg appendFormat:@"%02x", result[i]];
    }
    return [outStrg copy];
}

+ (NSString *)sha256FromString:(NSString *)string {
    unsigned char *inStrg = (unsigned char *) [[string dataUsingEncoding:NSASCIIStringEncoding] bytes];
    unsigned long lngth = [string length];
    unsigned char result[SHA256_DIGEST_LENGTH];
    NSMutableString *outStrg = [NSMutableString string];
    
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, inStrg, lngth);
    SHA256_Final(result, &sha256);
    
    unsigned int i;
    for (i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        [outStrg appendFormat:@"%02x", result[i]];
    }
    return [outStrg copy];
}

+ (NSString *)base64FromString:(NSString *)string encodeWithNewlines:(BOOL)encodeWithNewlines {
    BIO *mem = BIO_new(BIO_s_mem());
    BIO *b64 = BIO_new(BIO_f_base64());
    
    if (!encodeWithNewlines) {
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    }
    mem = BIO_push(b64, mem);
    
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger length = stringData.length;
    void *buffer = (void *) [stringData bytes];
    int bufferSize = (int)MIN(length, INT_MAX);
    
    NSUInteger count = 0;
    
    BOOL error = NO;
    
    // Encode the data
    while (!error && count < length) {
        int result = BIO_write(mem, buffer, bufferSize);
        if (result <= 0) {
            error = YES;
        }
        else {
            count += result;
            buffer = (void *) [stringData bytes] + count;
            bufferSize = (int)MIN((length - count), INT_MAX);
        }
    }
    
    int flush_result = BIO_flush(mem);
    if (flush_result != 1) {
        return nil;
    }
    
    char *base64Pointer;
    NSUInteger base64Length = (NSUInteger) BIO_get_mem_data(mem, &base64Pointer);
    
    NSData *base64data = [NSData dataWithBytesNoCopy:base64Pointer length:base64Length freeWhenDone:NO];
    NSString *base64String = [[NSString alloc] initWithData:base64data encoding:NSUTF8StringEncoding];
    
    BIO_free_all(mem);
    return base64String;
}

+ (int)generateCertificatePath: (NSString *)certificatePath
                 publicKeyPath: (NSString *)publicKeyPath
                privateKeyPath: (NSString *)privateKeyPath
                      hostname: (NSString *)hostname
                       subject: (X509_NAME *)subject
                       issuser: (X509_NAME *)issuser {
    /*
     Before we can actually create a certificate, we need to create a private key. OpenSSL provides the EVP_PKEY structure for storing an algorithm-independent private key in memory. This structure is declared in openssl/evp.h but is included by openssl/x509.h (which we will need later) so you don't really need to explicitly include the header.
     
     In order to allocate an EVP_PKEY structure, we use EVP_PKEY_new:
     */
    EVP_PKEY * pkey;
    pkey = EVP_PKEY_new();
    /*
     There is also a corresponding function for freeing the structure - EVP_PKEY_free - which accepts a single argument: the EVP_PKEY structure initialized above.
     */
    
    /*
     Now we need to generate a key. For our example, we will generate an RSA key. This is done with the RSA_generate_key function which is declared in openssl/rsa.h. This function returns a pointer to an RSA structure.
     
     A simple invocation of the function might look like this:
     */
    RSA * rsa;
    rsa = RSA_generate_key(
                           2048,   /* number of bits for the key - 2048 is a sensible value */
                           RSA_F4, /* exponent - RSA_F4 is defined as 0x10001L */
                           NULL,   /* callback - can be NULL if we aren't displaying progress */
                           NULL    /* callback argument - not needed in this case */
                           );
    if(!rsa) {
        EVP_PKEY_free(pkey);
        return -1;
    }
    /*
     If the return value of RSA_generate_key is NULL, then something went wrong. If not, then we now have an RSA key, and we can assign it to our EVP_PKEY structure from earlier:
     */
    EVP_PKEY_assign_RSA(pkey, rsa);
    /*
     The RSA structure will be automatically freed when the EVP_PKEY structure is freed.
     */
    
    /*
     Now for the certificate itself.
     
     OpenSSL uses the X509 structure to represent an x509 certificate in memory. The definition for this struct is in openssl/x509.h. The first function we are going to need is X509_new. Its use is relatively straightforward:
     */
    X509 * x509;
    x509 = X509_new();
    /*
     As was the case with EVP_PKEY, there is a corresponding function for freeing the structure - X509_free.
     */
    
    /*
     Now we need to set a few properties of the certificate using some X509_* functions:
     */
    ASN1_INTEGER_set(X509_get_serialNumber(x509), 1);
    
    /*
     This sets the serial number of our certificate to '1'. Some open-source HTTP servers refuse to accept a certificate with a serial number of '0', which is the default. The next step is to specify the span of time during which the certificate is actually valid. We do that with the following two function calls:
     */
    X509_gmtime_adj(X509_get_notBefore(x509), 0);
    X509_gmtime_adj(X509_get_notAfter(x509), 31536000L);
    /*
     The first line sets the certificate's notBefore property to the current time. (The X509_gmtime_adj function adds the specified number of seconds to the current time - in this case none.) The second line sets the certificate's notAfter property to 365 days from now (60 seconds * 60 minutes * 24 hours * 365 days).
     */
    
    /*
     Now we need to set the public key for our certificate using the key we generated earlier:
     */
    X509_set_pubkey(x509, pkey);
    
    /*
     Since this is a self-signed certificate, we set the name of the issuer to the name of the subject. The first step in that process is to get the subject name:
     */
    //X509_NAME * name;
    //name = X509_get_subject_name(x509);
    /*
     If you've ever created a self-signed certificate on the command line before, you probably remember being asked for a country code. Here's where we provide it along with the organization ('O') and common name ('CN'):
     */
    /*X509_NAME_add_entry_by_txt(name, "C",  MBSTRING_ASC,
                               (unsigned char *)"TW", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "O",  MBSTRING_ASC,
                               (unsigned char *)"TU", -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC,
                               (unsigned char *)[hostname UTF8String], -1, -1, 0);
     */
    /*
     (I'm using the value 'CA' here because I'm Canadian and that's our country code. Also note that parameter #4 needs to be explicitly cast to an unsigned char *.)
     */
    
    /*
     Now we can actually set the issuer name:
     */
    X509_NAME *name = NULL;
    if(subject) {
        X509_set_subject_name(x509, subject);
    }
    else {
        name = X509_get_subject_name(x509);
        X509_NAME_add_entry_by_txt(name, "C",  MBSTRING_ASC,
                                   (unsigned char *)"TW", -1, -1, 0);
        X509_NAME_add_entry_by_txt(name, "O",  MBSTRING_ASC,
                                   (unsigned char *)"TU", -1, -1, 0);
        X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC,
                                   (unsigned char *)[hostname UTF8String], -1, -1, 0);
        X509_set_subject_name(x509, name);
    }
    
    if(issuser) {
        X509_set_issuer_name(x509, issuser);
    }
    else if (name) {
        X509_set_issuer_name(x509, name);
    }
    
    /*
     And finally we are ready to perform the signing process. We call X509_sign with the key we generated earlier. The code for this is painfully simple:
     */
    X509_sign(x509, pkey, EVP_sha1());
    /*
     Note that we are using the SHA-1 hashing algorithm to sign the key. This differs from the mkcert.c demo I mentioned at the beginning of this answer, which uses MD5.
     */
    
    
    /*
     We now have a self-signed certificate! But we're not done yet - we need to write these files out to disk. Thankfully OpenSSL has us covered there too with the PEM_* functions which are declared in openssl/pem.h. The first one we will need is PEM_write_PrivateKey for saving our private key.
     */
    FILE * f;
    f = fopen([privateKeyPath UTF8String], "wb");
    PEM_write_PrivateKey(
                         f,                  /* write the key to the file we've opened */
                         pkey,               /* our key from earlier */
                         NULL,//EVP_des_ede3_cbc(), /* default cipher for encrypting the key on disk */
                         NULL,//(unsigned char *)"replace_me",       /* passphrase required for decrypting the key on disk */
                         10,                 /* length of the passphrase string */
                         NULL,               /* callback for requesting a password */
                         NULL                /* data to pass to the callback */
                         );
    fflush(f);
    fclose(f);
    /*
     If you don't want to encrypt the private key, then simply pass NULL for the third and fourth parameter above. Either way, you will definitely want to ensure that the file is not world-readable. (For Unix users, this means chmod 600 key.pem.)
     */
    
    /*
     Whew! Now we are down to one function - we need to write the certificate out to disk. The function we need for this is PEM_write_X509:
     */
    
    f = fopen([certificatePath UTF8String], "wb");
    PEM_write_X509(
                   f,   /* write the certificate to the file we've opened */
                   x509 /* our certificate */
                   );
    fflush(f);
    fclose(f);
    
    //public key
    f = fopen([publicKeyPath UTF8String], "wb");
    PEM_write_PUBKEY(f, pkey);
    fflush(f);
    fclose(f);
    
    X509_free(x509);
    EVP_PKEY_free(pkey);
    return 0;
}













@end
