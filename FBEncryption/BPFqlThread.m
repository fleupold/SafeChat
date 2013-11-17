//
//  BPFqlThread.m
//  FBEncryption
//
//  Created by Felix Leupold on 11/16/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPFqlThread.h"
#import "BPFacebookDateFormatter.h"
#import "BPFqlRequestManager.h"
#import "BPFqlMessage.h"

@implementation BPFqlThread
@synthesize hasLoadedMessages;

+ (BPFqlThread *)threadFromFBGraphObject: (FBGraphObject *)object
{
    return [[[BPFqlThread alloc] init] configureWithFBGraphObject:object];
}

-(BPFqlThread *)configureWithFBGraphObject: (FBGraphObject *)object
{
    //Initialize Date
    NSNumber *epoch = [object objectForKey:@"updated_time"];
    self.updated_at = [NSDate dateWithTimeIntervalSince1970: [epoch doubleValue]];  
    
    //Initialize Messages
    BPMessage *preview = [BPMessage messageFromText: [object objectForKey: @"snippet"]];
    NSNumber *snippetAuthor = [object objectForKey:@"snippet_author"];
    preview.from = [BPFriend findOrCreateFriendWithId:[snippetAuthor stringValue]
                                              andName:[snippetAuthor stringValue]];
    self.messages = [NSMutableArray arrayWithObjects: preview, nil];
    
    //Initialize Participants
    NSArray *_participants = [object objectForKey: @"recipients"];
    self.participants = [NSMutableArray array];
    for (NSNumber *recipientID in _participants) {
        BPFriend *participant = [BPFriend findOrCreateFriendWithId:[recipientID stringValue]
                                                           andName:[recipientID stringValue]];
        [self.participants addObject: participant];
    }
    
    self.unread = [[object objectForKey:@"unread"] integerValue];
    self.id = [object objectForKey:@"thread_id"];
    hasLoadedMessages = NO;
    
    return self;
}

-(void)update
{
    NSDate *loadBefore = [NSDate date];
    if (hasLoadedMessages && self.messages.count > 0) {
        loadBefore = ((BPMessage *)self.messages.firstObject).created;
    }
    
    [BPFqlRequestManager requestMessagesForThreadId: self.id
                                             before: loadBefore
                                         completion:
     ^(NSDictionary *response) {
         NSMutableArray *newMessages = [NSMutableArray array];
         for (NSDictionary *messageDict in [response objectForKey:@"data"]) {
             BPFqlMessage *message = [BPFqlMessage messageFromFBGraphObject: (FBGraphObject *)messageDict];
             [newMessages addObject: message];
         }
         
         if (!hasLoadedMessages) {
             hasLoadedMessages = YES;
             self.messages = newMessages;
         } else {
             self.messages = [[newMessages arrayByAddingObjectsFromArray: self.messages] mutableCopy];
         }
         [self.delegate hasUpdatedThread: self scrollToRow: newMessages.count-1];
         
     } failure:^(NSError *error) {
         NSLog(@"%@", error);
     }];
}
@end
