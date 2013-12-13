//
//  BPInboxThread.m
//  SafeChat
//
//  Created by Felix Leupold on 11/16/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPInboxThread.h"
#import "BPFacebookDateFormatter.h"

@implementation BPInboxThread

+ (BPInboxThread *)threadFromFBGraphObject: (FBGraphObject *)object
{
    return [[[BPInboxThread alloc] init] configureWithFBGraphObject:object];
}

-(BPInboxThread *)configureWithFBGraphObject: (FBGraphObject *)object
{
    //Initialize Date
    NSString *dateString = [object objectForKey:@"updated_time"];
    self.updated_at = [[[BPFacebookDateFormatter alloc] init] dateFromString: dateString];
    
    //Initialize Messages
    NSArray *_messages = [[object objectForKey: @"comments"] objectForKey: @"data"];
    self.messages = [NSMutableArray array];
    for (FBGraphObject *messageObject in _messages)
    {
        BPMessage *message = [BPMessage messageFromFBGraphObject: messageObject];
        [self.messages addObject: message];
    }
    self.nextPage = [[[object objectForKey: @"comments"] objectForKey:@"paging"] objectForKey: @"next"];
    
    //Initialize Participants
    NSArray *_participants = [[object objectForKey: @"to"] objectForKey: @"data"];
    self.participants = [NSMutableArray array];
    for (FBGraphObject *participantObject in _participants) {
        BPFriend *participant = [BPFriend findOrCreateFriendWithId:[participantObject objectForKey:@"id"]
                                                           andName:[participantObject objectForKey:@"name"]];
        [self.participants addObject: participant];
    }
    
    self.unread = [[object objectForKey:@"unread"] integerValue];
    self.id = [object objectForKey:@"id"];
    
    return self;
}


@end
