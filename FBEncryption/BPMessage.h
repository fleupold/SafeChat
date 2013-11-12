//
//  BPMessage.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import "BPFriend.h"

@interface BPMessage : NSObject
{
    NSString *_text;
}
@property NSString *id, *text;
@property NSDate *created;
@property BPFriend *from;

+(id)messageFromFBGraphObject: (FBGraphObject *)object;
+(id)messageFromText:(NSString *)text;

-(NSString *)encryptForParticipants: (NSArray *)participants;

@end
