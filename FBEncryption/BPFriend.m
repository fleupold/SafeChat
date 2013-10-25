//
//  BPFriend.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPFriend.h"
#import "BPServerRequestManager.h"

@implementation BPFriend
@synthesize name, id, username, encryptionSupport, publicKey;

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
        friend = [[BPFriend alloc] init];
        friend.name = name;
        friend.id = id;
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

-(BOOL)isMe
{
    return self == me;
}

-(void)checkEncryptionSupportAndExecuteOnCompletion: (void (^)(BOOL))completionHandler
{
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
    [BPServerRequestManager publicKeyForID:self.username
                                completion:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    self.publicKey = operation.responseString;
                                    self.encryptionSupport = EncryptionAvailable;
                                    completionHandler(YES);
                                }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       completionHandler(NO);
                                   }];
}

@end
