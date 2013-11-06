//
//  BPJavascriptRuntime.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPJavascriptRuntime.h"
#import "BPFriend.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>

@implementation BPJavascriptRuntime

const CCAlgorithm kAlgorithm = kCCAlgorithmAES128;
const NSUInteger kAlgorithmKeySize = kCCKeySizeAES256;
const NSUInteger kAlgorithmBlockSize = kCCBlockSizeAES128;
const NSUInteger kAlgorithmIVSize = kCCBlockSizeAES128;
const NSUInteger kPBKDFSaltSize = 8;
const NSUInteger kPBKDFRounds = 10000;

#define private_key_identifier @"my_private_key"
    
static BPJavascriptRuntime *instance;

+(BPJavascriptRuntime *)getInstance
{
    if (instance == nil) {
        instance = [[BPJavascriptRuntime alloc] init];
    }
    return instance;
}

+(BOOL)privateKeyAvailable {
    return [[NSUserDefaults standardUserDefaults] objectForKey: private_key_identifier] != nil;
}

+(void)resetPrivateKey
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey: private_key_identifier];
}


-(id)init{
    _myPrivateKey = [[NSUserDefaults standardUserDefaults] objectForKey: private_key_identifier];
    _context = [[JSContext alloc] init];
    
    //Load all Javascript files
    NSString *cryptico_js = [[NSBundle mainBundle] pathForResource:@"cryptico.min" ofType:@"js"];
    NSString *encryption_js = [[NSBundle mainBundle] pathForResource:@"encryption" ofType:@"js"];
    
    NSString *ec_js = [[NSBundle mainBundle] pathForResource:@"ec" ofType:@"js"];
    NSString *jsbn_js = [[NSBundle mainBundle] pathForResource:@"jsbn" ofType:@"js"];
    NSString *jsbn2_js = [[NSBundle mainBundle] pathForResource:@"jsbn2" ofType:@"js"];
    NSString *sec_js = [[NSBundle mainBundle] pathForResource:@"sec" ofType:@"js"];
    
    NSString *gibberish_js = [[NSBundle mainBundle] pathForResource:@"gibberish-aes-1.0.0.min" ofType:@"js"];
    
    NSMutableString *script = [NSMutableString stringWithContentsOfFile:cryptico_js encoding:NSUTF8StringEncoding error:nil];
    [script appendString:[NSString stringWithContentsOfFile:gibberish_js encoding:NSUTF8StringEncoding error:NULL]];
    [script appendString:[NSString stringWithContentsOfFile:encryption_js encoding:NSUTF8StringEncoding error:NULL]];
    [script appendString:[NSString stringWithContentsOfFile:ec_js encoding:NSUTF8StringEncoding error:NULL]];
    [script appendString:[NSString stringWithContentsOfFile:jsbn_js encoding:NSUTF8StringEncoding error:NULL]];
    [script appendString:[NSString stringWithContentsOfFile:jsbn2_js encoding:NSUTF8StringEncoding error:NULL]];
    [script appendString:[NSString stringWithContentsOfFile:sec_js encoding:NSUTF8StringEncoding error:NULL]];
    
    JSValue *result = [_context evaluateScript: script];
    
    return [super init];
}

-(NSString *)decrypt: (NSString *)message withSessionKey:(NSString *)sessionKey
{
    JSValue *dec = _context[@"GibberishAES"][@"dec"];
    
    JSValue *result = [dec callWithArguments: @[message, sessionKey]];
    return result.toString;
}

-(NSString *)encrypt: (NSString *)message withSessionKey:(NSString *)sessionKey
{
    JSValue *enc = _context[@"GibberishAES"][@"enc"];
    
    JSValue *result = [enc callWithArguments: @[message, sessionKey]];
    return result.toString;
}

-(NSString *)generatePublicKeyWithPassphrase:(NSString *)passphrase;
{
    NSData *salt = [[BPFriend me].username dataUsingEncoding:NSUTF8StringEncoding];
    NSData *key = [self keyFromPassphrase:passphrase withSalt:salt];
    _myPrivateKey = [self hexFromNSData: key];
    [[NSUserDefaults standardUserDefaults] setObject:_myPrivateKey forKey:private_key_identifier];
    
    JSValue *derive_public = _context[@"derive_public"];
    //NSLog(@"%@", derive_public);
    JSValue *public = [derive_public callWithArguments: @[_myPrivateKey]];
    NSLog(@"%@", public);
    
    return public.toString;
}

-(NSData *)keyFromPassphrase: (NSString *)passphrase withSalt: (NSData *)salt
{
    NSMutableData *derivedKey = [NSMutableData dataWithLength:kAlgorithmKeySize];
    int result = CCKeyDerivationPBKDF(kCCPBKDF2,            // algorithm
                                      passphrase.UTF8String,  // password
                                      passphrase.length,  // passwordLength
                                      salt.bytes,           // salt
                                      salt.length,          // saltLen
                                      kCCPRFHmacAlgSHA1,    // PRF
                                      kPBKDFRounds,         // rounds
                                      derivedKey.mutableBytes, // derivedKey
                                      derivedKey.length); // derivedKeyLen
    
    NSAssert(result == kCCSuccess,
             @"Unable to create AES key for password: %d", result);
    return derivedKey;
}

-(NSString *)generateSessionKey: (NSString *)public_json {
    if (_myPrivateKey == nil) {
        @throw [NSException exceptionWithName: @"EncryptionException" reason: @"No private key supplied" userInfo:nil];
    }
    
    JSValue *generate_secret_key = _context[@"generate_secret_key"];
    //NSLog(@"%@", generate_secret_key);
    
    JSValue *result = [generate_secret_key callWithArguments: @[_myPrivateKey, public_json]];
    //NSLog(@"%@", result);
    return result.toString;
}

-(NSString *)hexFromNSData: (NSData *)data
{
    //Turn the NSData into its HEX representation
    NSUInteger capacity = [data length] * 2;
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *dataBuffer = [data bytes];
    NSInteger i;
    for (i=0; i < [data length]; ++i) {
        [stringBuffer appendFormat:@"%02X", dataBuffer[i]];
    }
    return stringBuffer;
}

@end
