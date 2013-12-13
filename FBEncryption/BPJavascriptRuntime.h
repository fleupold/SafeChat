//
//  BPJavascriptRuntime.h
//  SafeChat
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface BPJavascriptRuntime : NSObject

@property JSContext *context;
@property NSString *myPrivateKey;

+(BPJavascriptRuntime *)getInstance;
+(BOOL)privateKeyAvailable;
+(void)resetPrivateKey;

-(NSString *)decrypt: (NSString *)message withSessionKey:(NSString *)sessionKey;
-(NSString *)encrypt: (NSString *)message withSessionKey:(NSString *)sessionKey;
-(NSString *)generatePublicKeyWithPassphrase:(NSString *)passphrase;
-(NSString *)generateSessionKey: (NSString *)public_json;

@end
