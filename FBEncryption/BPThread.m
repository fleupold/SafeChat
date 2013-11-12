//
//  BPThread.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPThread.h"
#import "BPFacebookDateFormatter.h"
#import "FCBaseChatRequestManager.h"

@implementation BPThread
@synthesize updated_at, unread, messages, participants, delegate, nextPage;

+ (BPThread *)threadFromFBGraphObject: (FBGraphObject *)object
{
    return [[[BPThread alloc] init] configureWithFBGraphObject:object];
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

-(void)checkEncryptionSupport
{
    //Asynchronously check if all participants have a public key on the server and
    //notify the delegate once done. If only one participant does not have
    //encryption supper we are done. After each successful response, we may check if all participants
    //have complete information
    for (BPFriend *participant in self.participants)
    {
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

-(void)update
{
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForGraphPath: self.id] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           FBGraphObject *thread,
           NSError *error) {
             if (!error) {
                 [self configureWithFBGraphObject:thread];
                 [self.delegate hasUpdatedThread: self];
             }
             else {
                 NSLog(@"%@", error);
             }
         }];
    }
}
@end
