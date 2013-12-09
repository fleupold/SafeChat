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
#import "BPAppDelegate.h"

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

-(void)sendMessage: (NSString *)text encrypted: (BOOL)shouldBeEncrypted
{
    [super sendMessage:text encrypted:shouldBeEncrypted];
    //make sure message made it to the server
    [self performSelector: @selector(update) withObject:nil afterDelay: 3];
    [self performSelector: @selector(updateAndInvalidateUnsyncedMessages:) withObject:[NSNumber numberWithBool: YES] afterDelay: DEFAULT_TIMEOUT];
}

-(void)loadMore
{
    NSDate *loadBefore = [NSDate date];
    if (hasLoadedMessages && self.messages.count > 0) {
        loadBefore = ((BPMessage *)self.messages.firstObject).created;
    }
    
    [BPFqlRequestManager requestMessagesForThreadId: self.id
                                             before: loadBefore
                                              after: [NSDate dateWithTimeIntervalSince1970:0]
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

-(void)update {
    [self updateAndInvalidateUnsyncedMessages: NO];
}

-(void)updateAndInvalidateUnsyncedMessages: (BOOL)invalidate
{
    //Find the last message in sync
    NSPredicate *unsyncPredicate = [NSPredicate predicateWithFormat: @"(SELF.from.isMe == 1) AND (not SELF.synced == 1)"];
    NSArray *unsyncedMessages = [self.messages filteredArrayUsingPredicate: unsyncPredicate];
    [self.messages removeObjectsInArray: unsyncedMessages];
    
    NSDate *loadAfter = ((BPMessage *)self.messages.lastObject).created;
    NSDate *loadBefore = [NSDate date];
    
    [BPFqlRequestManager requestMessagesForThreadId: self.id
                                             before: loadBefore
                                              after: loadAfter
                                         completion:^(NSDictionary *response) {
                                             [self handleUpdateResponse: response unsyncedMessages: [unsyncedMessages mutableCopy] invalidate: invalidate];
                                         } failure:^(NSError *error) {
                                             [self handleUpdateResponse: [NSDictionary dictionary] unsyncedMessages: [unsyncedMessages mutableCopy] invalidate: invalidate];
                                             NSLog(@"%@", error);
                                             [(BPAppDelegate *)[[UIApplication sharedApplication] delegate] appRefreshDidFail];
                                         }];
}

-(void)handleUpdateResponse: (NSDictionary *)response unsyncedMessages:(NSMutableArray *)unsyncedMessages invalidate: (BOOL)invalidate
{
    NSMutableArray *newlySyncedMessages = [NSMutableArray array];
    
    for (NSDictionary *messageDict in [response objectForKey:@"data"]) {
        BPFqlMessage *message = [BPFqlMessage messageFromFBGraphObject: (FBGraphObject *)messageDict];
        [self.messages addObject: message];
        [self postNotificationFor: message];
        
        //See if this message is one that hasn't been synced
        if (![message.from isMe]) {
            continue;
        }
        for (BPMessage *unsyncedMessage in unsyncedMessages) {
            if ([message.text isEqualToString: unsyncedMessage.text]) {
                [newlySyncedMessages addObject: unsyncedMessage];
            }
        }
    }
    
    //Finally all messages that are still not synced failed to send
    [unsyncedMessages removeObjectsInArray: newlySyncedMessages];
    if (invalidate){
        for (BPMessage *unsyncedMessage in unsyncedMessages) {
            unsyncedMessage.failedToSend = YES;
        }
    }
    [self.messages addObjectsFromArray: unsyncedMessages];
    [self.delegate hasUpdatedThread: self scrollToRow: self.messages.count - 1];
    
    [(BPAppDelegate *)[[UIApplication sharedApplication] delegate] threadFinishedRefresh];
}

-(void)updateWithThread: (BPThread *)newThread
{
    self.updated_at = newThread.updated_at;
    self.unseen = newThread.unseen;
    self.unread = newThread.unread;
    [self update];
}



@end
