//
//  BPFqlMessage.m
//  FBEncryption
//
//  Created by Felix Leupold on 11/16/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPFqlMessage.h"

@implementation BPFqlMessage

+(id)messageFromFBGraphObject: (FBGraphObject *)object {
    BPMessage *message = [[BPMessage alloc] init];
    
    NSNumber *createdEpoch = [object objectForKey:@"created_time"];
    message.created = [NSDate dateWithTimeIntervalSince1970: [createdEpoch doubleValue]];
    
    message.id = [object objectForKey: @"message_id"];
    message.text = [object objectForKey: @"body"];
    
    NSNumber *auther_id = [object objectForKey: @"author_id"];
    message.from = [BPFriend findOrCreateFriendWithId:[auther_id stringValue]
                                              andName:[auther_id stringValue]];
    return message;
}

@end
