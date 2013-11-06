//
//  BPFriend.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

enum{
    EncryptionNotChecked,
    EncryptionAvailable,
    EncryptionNotAvailable,
};
typedef NSInteger BPEncryptionsSupport;

@interface BPFriend : NSObject

@property NSString *name, *id, *username, *sessionKey;
@property BPEncryptionsSupport encryptionSupport;

+(BPFriend *)findOrCreateFriendWithId: (NSString *)id andName: (NSString *)name;
+(BPFriend *)createMe: (NSDictionary<FBGraphUser> *)object;
+(BPFriend *)me;
+(BPFriend *)findByUsername: (NSString *)username;


-(BOOL)isMe;
-(void)checkEncryptionSupportAndExecuteOnCompletion: (void (^)(BOOL))completionHandler;
@end
