//
//  BPMessage.h
//  SafeChat
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import "BPFriend.h"

static NSString * const kMessageDecryptedNotification = @"kMessageDecryptedNotification";

@interface BPMessage : NSObject
{
    NSString *_text;
}
@property NSString *id, *text;
@property NSDate *created;
@property BPFriend *from;
@property BOOL failedToSend, encrypted, synced;

+(id)messageFromFBGraphObject: (FBGraphObject *)object;
+(id)messageFromText:(NSString *)text;

-(NSString *)encryptForParticipants: (NSArray *)participants;

@end
