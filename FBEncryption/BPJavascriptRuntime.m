//
//  BPJavascriptRuntime.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPJavascriptRuntime.h"
#import "BPFriend.h"

@implementation BPJavascriptRuntime

static BPJavascriptRuntime *instance;

+(BPJavascriptRuntime *)getInstance
{
    if (instance == nil) {
        instance = [[BPJavascriptRuntime alloc] init];
        [instance loadHTMLString:@"<script src=\"encryption.js\"></script><script src=\"cryptico.min.js\"></script>" baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
    }
    return instance;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)init{
    _myPrivateKey = [[NSUserDefaults standardUserDefaults] objectForKey: @"my_private_key"];
    return [super init];
}

-(NSString *)decrypt: (NSString *)message
{
    // Decrypt the message using the javascript functions provided in cryptico.js and the private key of the user
    if (_myPrivateKey == nil) {
        @throw [NSException exceptionWithName: @"EncryptionException" reason: @"No private key supplied" userInfo:nil];
    }
    
    NSString *js = [NSString stringWithFormat: @"cryptico.decrypt('%@', cast_to_rsa_key(JSON.parse('%@'))).plaintext", message, _myPrivateKey];
    NSString *decrypted = [self stringByEvaluatingJavaScriptFromString: js];
    
    if (decrypted.length == 0) {
        @throw [NSException exceptionWithName: @"EncryptionException" reason: @"cryptico.decryot returned empty string" userInfo:nil];
    }
    return decrypted;
}

-(NSString *)encrypt: (NSString *)message withPublicKey:(NSString *)publicKey
{
    NSString *js = [NSString stringWithFormat: @"cryptico.encrypt('%@', '%@').cipher", message, publicKey];
    NSString *encrypted = [self stringByEvaluatingJavaScriptFromString: js];
    return encrypted;
}

-(void)triggerKeyGenerationWithPassphrase:(NSString *)passphrase
{
    NSString *phrase_with_salt = [NSString stringWithFormat: @"%@_%@", [BPFriend me].username, passphrase];
    NSString *js = [NSString stringWithFormat: @"generate_key_pair('%@')", phrase_with_salt];
    [self performSelector: @selector(stringByEvaluatingJavaScriptFromString:) withObject: js afterDelay:1];
    [self performSelector:@selector(tryFetchKey) withObject:nil afterDelay:10];
}

-(void)tryFetchKey {
    _myPrivateKey = [self stringByEvaluatingJavaScriptFromString:@"my_private_key"];
    NSString *myPublicKey = [self stringByEvaluatingJavaScriptFromString:@"my_public_key"];
    
    if([myPublicKey length] == 0 || [_myPrivateKey length] == 0) {
        [self performSelector:@selector(tryFetchKey) withObject:nil afterDelay:1];
        NSLog(@"waiting...");
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject: _myPrivateKey forKey: @"my_private_key"];
    [self.delegate keyPairGeneratedWithPublicKey: myPublicKey];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

/*
 -(void)executeJavaScript
 {
 if (!self.context) {
 self.context = [[JSContext alloc] init];
 NSString *cryptico_js = [[NSBundle mainBundle] pathForResource:@"cryptico.min" ofType:@"js"];
 NSString *script = [NSString stringWithContentsOfFile:cryptico_js encoding:NSUTF8StringEncoding error:NULL];
 [self.context evaluateScript: script];
 
 NSString *encryption_js = [[NSBundle mainBundle] pathForResource:@"encryption" ofType:@"js"];
 script = [NSString stringWithContentsOfFile:encryption_js encoding:NSUTF8StringEncoding error:NULL];
 [self.context evaluateScript: script];
 }
 
 JSValue *generate_key_pair = self.context[@"cryptico"];
 NSLog(@"%@", [generate_key_pair toDictionary]);
 NSArray *args = @[[NSNumber numberWithInt:10]];
 
 JSValue *key = [generate_key_pair callWithArguments: args];
 NSLog(@"%@", [key toString]);
 
 
 JSValue *encrypt = self.context[@"encrypt"];
 args = @[@"Hallo Welt!", key];
 JSValue *encrypted = [encrypt callWithArguments: args];
 BPEncryptedObject *encryptedObject = [encrypted toObject];
 NSLog(@"Cipher: %@", encryptedObject.cipher);
 }
 
 -(void)triggerKeyGeneration
 {
 [self.jsHost stringByEvaluatingJavaScriptFromString:@"generate_key_pair('foo')"];
 [self performSelector:@selector(tryFetchKey) withObject:nil afterDelay:10];
 }
 
 -(void)tryFetchKey {
 myPrivateKey = [self.jsHost stringByEvaluatingJavaScriptFromString:@"my_private_key"];
 myPublicKey = [self.jsHost stringByEvaluatingJavaScriptFromString:@"my_public_key"];
 
 if([myPublicKey length] == 0 || [myPrivateKey length] == 0) {
 [self performSelector:@selector(tryFetchKey) withObject:nil afterDelay:1];
 NSLog(@"waiting...");
 return;
 }
 [spinner stopAnimating];
 NSLog(@"Private: %@\n\nPublic: %@", myPrivateKey, myPublicKey);
 [self encrypt: @"Hallo Welt!"];
 }
 
 -(void)encrypt: (NSString *)message forFriend:(BPFriend *)friend
 {
 NSString *js = [NSString stringWithFormat: @"cryptico.encrypt('%@', '%@').cipher", message, myPublicKey];
 NSString *encrypted = [self.jsHost stringByEvaluatingJavaScriptFromString: js];
 NSLog(@"Encrypted: %@", encrypted);
 [self decrypt: encrypted];
 }
 */

@end
