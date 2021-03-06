//
//  BPFriend.h
//  SafeChat
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
@property (readonly) NSDate *lastEncryptionSupportCheck;

+(BPFriend *)findOrCreateFriendWithId: (NSString *)id andName: (NSString *)name;
+(BPFriend *)createMe: (NSDictionary<FBGraphUser> *)object;
+(BPFriend *)me;
+(BOOL)meHasEncryptionConfigured;
+(BPFriend *)findByUsername: (NSString *)username;

+(NSArray *)allFriends;
+(void)resetAllSessionKeys;
+(void)clearFriendList;

-(BOOL)isMe;
-(BPEncryptionsSupport)encryptionSupport;
-(void)checkEncryptionSupportAndExecuteOnCompletion: (void (^)(BOOL))completionHandler;
@end
