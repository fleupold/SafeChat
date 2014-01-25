//
//  BPFriend.m
//  SafeChat
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPFriend.h"
#import "BPServerRequestManager.h"
#import "BPJavascriptRuntime.h"

const static NSTimeInterval kEncryptionSupportRefreshPeriod = 60 * 60 * 24;

@implementation BPFriend {
    BPEncryptionsSupport _encryptionSupport;
}

@synthesize name, id, username, sessionKey;

static NSMutableDictionary *friendList;
static BPFriend *me;

+(BPFriend *)findOrCreateFriendWithId: (NSString *)id andName: (NSString *)name {
    if (friendList == nil) {
        friendList = [NSMutableDictionary dictionary];
    }
    
    //Find
    BPFriend *friend = [friendList objectForKey: id];
    if (friend == nil) {
        //Create if not found
        friend = [[BPFriend alloc] initWithId:id andName:name];
        [friendList setValue:friend forKey:id];
    }
    return friend;
}

+(BPFriend *)createMe: (NSDictionary<FBGraphUser> *)object;
{
    me = [BPFriend findOrCreateFriendWithId: object.id andName: object.name];
    me.username = object.username;
    return me;
}

+(BPFriend *)me
{
    return me;
}

+(BOOL)meHasEncryptionConfigured
{
    return [BPJavascriptRuntime privateKeyAvailable];
}
    
+(BPFriend *)findByUsername: (NSString *)username
{
    for (NSString *id in friendList) {
        BPFriend *friend = [friendList objectForKey:id];
        if ([friend.username isEqualToString: username]) {
            return friend;
        }
    }
    return nil;
}

+(NSArray *)allFriends
{
    NSPredicate *notMe = [NSPredicate predicateWithFormat: @"SELF.isMe == 0"];
    return [[friendList allValues] filteredArrayUsingPredicate:notMe];
}

+(void)clearFriendList
{
    friendList = [NSMutableDictionary dictionary];
}

+(void)resetAllSessionKeys
{
    for (BPFriend *friend in [BPFriend allFriends])
    {
        friend.sessionKey = nil;
    }
}

- (instancetype)initWithId: (NSString *)uid andName: (NSString *)aName
{
    self = [super init];
    if (self) {
        self.name = aName;
        self.id = uid;
        _lastEncryptionSupportCheck = [NSDate distantPast];
    }
    return self;
}

-(BOOL)isMe
{
    return self == me;
}

- (BPEncryptionsSupport)encryptionSupport
{
    if ([self isMe]) {
        return [self.class meHasEncryptionConfigured] ? EncryptionAvailable : EncryptionNotAvailable;
    }
    
    NSTimeInterval sinceLastCheck = [[NSDate date] timeIntervalSinceDate:_lastEncryptionSupportCheck];
    if (_encryptionSupport == EncryptionNotAvailable && sinceLastCheck > kEncryptionSupportRefreshPeriod) {
        _encryptionSupport = EncryptionNotChecked;
    }
    return _encryptionSupport;
}

-(void)checkEncryptionSupportAndExecuteOnCompletion: (void (^)(BOOL))completionHandler
{
    if ([self isMe]) {
        completionHandler([BPJavascriptRuntime privateKeyAvailable]);
        return;
    }
    
    if (self.username == nil)
    {
        if (FBSession.activeSession.isOpen) {
            [[FBRequest requestForGraphPath: self.id] startWithCompletionHandler:
             ^(FBRequestConnection *connection,
               NSDictionary<FBGraphUser> *user,
               NSError *error) {
                 if (!error) {
                     self.username = user.username;
                     [self checkEncryptionSupportAndExecuteOnCompletionHelper: completionHandler];
                 }
                 else {
                     NSLog(@"%@", error);
                 }
             }];
        }
    } else {
        [self checkEncryptionSupportAndExecuteOnCompletionHelper: completionHandler];
    }
    
}

-(void)checkEncryptionSupportAndExecuteOnCompletionHelper: (void (^)(BOOL))completionHandler
{
    //This method is just a helper for the one above. If this method is called the username has
    //to be set
    [BPServerRequestManager publicKeyForID:self.id
                                completion:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    self.sessionKey = [[BPJavascriptRuntime getInstance] generateSessionKey: operation.responseString];
                                    _encryptionSupport = EncryptionAvailable;
                                    completionHandler(YES);
                                }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       _encryptionSupport = EncryptionNotAvailable;
                                       completionHandler(NO);
                                   }];
    
    _lastEncryptionSupportCheck = [NSDate date];
}

@end
