//
//  BPThread.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPThread.h"
#import "BPFacebookDateFormatter.h"
#import "BPAppDelegate.h"

@implementation BPThread
@synthesize updated_at, unread, messages, participants, delegate, nextPage;

+ (BPThread *)threadFromFBGraphObject: (FBGraphObject *)object
{
    return [[[BPThread alloc] init] configureWithFBGraphObject:object];
}

+ (BPThread *)emptyThreadWith:(BPFriend *)user
{
    BPThread *thread = [[BPThread alloc] init];
    thread.updated_at = [NSDate date];
    thread.unread = 0;
    thread.messages = [NSMutableArray array];
    thread.participants = [NSMutableArray arrayWithArray: @[user, [BPFriend me]]];
    return thread;
}

-(BPThread *)configureWithFBGraphObject: (FBGraphObject *)object
{
    //Initialize Date
    NSString *dateString = [object objectForKey:@"updated_time"];
    self.updated_at = [[[BPFacebookDateFormatter alloc] init] dateFromString: dateString];
    
    //Initialize Messages
    NSArray *_messages = [[object objectForKey: @"messages"] objectForKey: @"data"];
    self.messages = [NSMutableArray array];
    for (FBGraphObject *messageObject in [_messages reverseObjectEnumerator])
    {
        BPMessage *message = [BPMessage messageFromFBGraphObject: messageObject];
        [self.messages addObject: message];
    }
    self.nextPage = [[[object objectForKey: @"messages"] objectForKey:@"paging"] objectForKey: @"next"];
    
    //Initialize Participants
    NSArray *_participants = [[object objectForKey: @"participants"] objectForKey: @"data"];
    self.participants = [NSMutableArray array];
    for (FBGraphObject *participantObject in _participants) {
        BPFriend *participant = [BPFriend findOrCreateFriendWithId:[participantObject objectForKey:@"id"]
                                                           andName:[participantObject objectForKey:@"name"]];
        [self.participants addObject: participant];
    }
    
    self.unread = [[object objectForKey:@"unread_count"] integerValue];
    self.id = [object objectForKey:@"id"];
    
    return self;
}

-(void)loadMessages
{
    
}

-(UIImage *)avatar
{
    return [UIImage imageNamed: @"defaultUserIcon"];
}

-(NSString *)textPreview
{
    BPMessage *message = [self.messages lastObject];
    return message.text;
}

-(NSString *)participantsPreview
{
    NSMutableString *preview = [NSMutableString string];
    for (BPFriend *participant in self.participants)
    {
        if([participant isMe])
            continue;
        
        if (self.participants.count > 3) {
            //too many to display
            return [NSString stringWithFormat: @"%@, +%i", participant.name, (int)(self.participants.count - 2)];
        }
        
        [preview appendString: [NSString stringWithFormat: @"%@, ", participant.name]];
    }
    if (preview.length > 1)
        [preview deleteCharactersInRange: NSMakeRange(preview.length-2,2)];
    return preview;
}

-(void)setNextPage: (NSString *)page
{
    NSURL *nextPageURL = [NSURL URLWithString: page];
    nextPage = [NSString stringWithFormat:@"%@?%@", nextPageURL.relativePath, nextPageURL.query];
}

-(NSString *)nextPage{
    return nextPage;
}

-(BOOL)isGroupChat
{
    return self.participants.count > 2;
}

-(void)prepareForSending
{
    [FCBaseChatRequestManager getInstance];
}

-(void)checkEncryptionSupport
{
    //Asynchronously check if all participants have a public key on the server and
    //notify the delegate once done. If only one participant does not have
    //encryption supper we are done. After each successful response, we may check if all participants
    //have complete information
    if (![BPFriend meHasEncryptionConfigured]) {
        [self.delegate encryptionSupportHasBeenCheckedAndIsAvailable:NO];
        return;
    }
    
    for (BPFriend *participant in self.participants)
    {
        if ([participant isMe]) {
            participant.encryptionSupport = EncryptionAvailable;
            continue;
        }
        
        if (participant.encryptionSupport == EncryptionNotAvailable)
        {
            [self.delegate encryptionSupportHasBeenCheckedAndIsAvailable: NO];
            return;
        }
        if (participant.encryptionSupport == EncryptionNotChecked)
        {
            [participant checkEncryptionSupportAndExecuteOnCompletion: ^(BOOL isAvailable) {
               if (isAvailable)
               {
                   [self encryptionSupportAvailableForAllParticipants];
               } else {
                   [self.delegate encryptionSupportHasBeenCheckedAndIsAvailable: NO];
               }
            }];
        }
    }
    [self encryptionSupportAvailableForAllParticipants];
}

-(void)encryptionSupportAvailableForAllParticipants
{
    //This method is called whenever we get a successful response for encryption support
    //for any participant. If all participants have encryption available we may notify
    //the delegate
    for (BPFriend *participant in self.participants)
    {
        if (participant.encryptionSupport != EncryptionAvailable)
        {
            return;
        }
    }
    [self.delegate encryptionSupportHasBeenCheckedAndIsAvailable: YES];
}

-(void)sendMessage: (NSString *)text encrypted: (BOOL)shouldBeEncrypted
{
    BPMessage *newMessage = [BPMessage messageFromText: text];
    [self.messages addObject: newMessage];

    if (shouldBeEncrypted) {
        text = [newMessage encryptForParticipants: self.participants];
    }
    
    for (BPFriend *participant in self.participants)
    {
        if ([participant isMe]) {
            continue;
        }
        [[FCBaseChatRequestManager getInstance] sendMessageToFacebook: text withFriendFacebookID:participant.id];
    }
}

-(void)addIncomingMessage: (NSString *)text from: (BPFriend *)friend
{
    BPMessage *newMessage = [BPMessage messageFromText: text];
    newMessage.from = friend;
    newMessage.created = [NSDate date];
    [self.messages addObject:newMessage];
}

-(void)loadMore
{
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForGraphPath: self.id] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           FBGraphObject *thread,
           NSError *error) {
             if (!error) {
                 [self configureWithFBGraphObject:thread];
                 [self.delegate hasUpdatedThread: self scrollToRow: 0];
             }
             else {
                 NSLog(@"%@", error);
             }
         }];
    }
}

-(BOOL)isEqual:(id)object
{
    return [object isMemberOfClass: [self class]] && [self.id isEqualToString: ((BPThread *)object).id];
}

-(void)postNotificationFor: (BPMessage *)message
{
    if ([message.from isMe] || ![(BPAppDelegate *)[[UIApplication sharedApplication] delegate] isInBackgroundMode]) {
        return;
    }
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
    localNotification.alertBody = [NSString stringWithFormat:@"%@: %@", message.from.name, message.text];
    localNotification.userInfo = [NSDictionary dictionaryWithObject: self.id forKey:@"thread_id"];
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    [UIApplication sharedApplication].applicationIconBadgeNumber += 1;
}
@end
