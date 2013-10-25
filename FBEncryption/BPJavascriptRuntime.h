//
//  BPJavascriptRuntime.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BPJavascriptRuntimeDelegate <NSObject, UIWebViewDelegate>
@required
-(void)keyPairGeneratedWithPublicKey:(NSString *)publicKey;
@end

@interface BPJavascriptRuntime : UIWebView

@property NSString *myPrivateKey;
@property (nonatomic, weak) id<BPJavascriptRuntimeDelegate> delegate;

+(BPJavascriptRuntime *)getInstance;

-(NSString *)decrypt: (NSString *)message;
-(NSString *)encrypt: (NSString *)message withPublicKey:(NSString *)publicKey;
-(void)triggerKeyGenerationWithPassphrase:(NSString *)passphrase;

@end
