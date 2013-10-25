//
//  BPThread.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPThread.h"
#import "BPMessage.h"
#import "BPThread.h"
#import "BPFacebookDateFormatter.h"
#import "FCBaseChatRequestManager.h"

@implementation BPThread
@synthesize updated_at, unread, messages, participants, delegate;

+ (BPThread *)threadFromFBGraphObject: (FBGraphObject *)object
{
    BPThread *thread = [[BPThread alloc] init];
    
    //Initialize Date
    NSString *dateString = [object objectForKey:@"updated_time"];
    thread.updated_at = [[[BPFacebookDateFormatter alloc] init] dateFromString: dateString];
    
    //Initialize Messages
    NSArray *messages = [[object objectForKey: @"messages"] objectForKey: @"data"];
    thread.messages = [NSMutableArray array];
    for (FBGraphObject *messageObject in [messages reverseObjectEnumerator])
    {
        BPMessage *message = [BPMessage messageFromFBGraphObject: messageObject];
        [thread.messages addObject: message];
    }
    
    //Initialize Participants
    NSArray *participants = [[object objectForKey: @"participants"] objectForKey: @"data"];
    thread.participants = [NSMutableArray array];
    for (FBGraphObject *participantObject in participants) {
        BPFriend *participant = [BPFriend findOrCreateFriendWithId:[participantObject objectForKey:@"id"]
                                                           andName:[participantObject objectForKey:@"name"]];
        [thread.participants addObject: participant];
    }
    
    thread.unread = [[object objectForKey:@"unread_count"] integerValue];
    thread.id = [object objectForKey:@"id"];
    return thread;
}

-(UIImage *)avatar
{
    return [UIImage imageNamed: @"defaultUserIcon"];
}

-(NSString *)textPreview
{
    BPMessage *message = [self.messages lastObject];
    if([message.text length] > 30)
        return [message.text substringToIndex: 30];
    return message.text;
}

-(NSString *)participantsPreview
{
    NSString *preview = @"";
    for (BPFriend *participant in self.participants)
    {
        if([participant isMe])
            continue;
        preview = [preview stringByAppendingString: [NSString stringWithFormat: @"%@,", participant.name]];
        if([preview length] > 10)
            break;
    }
    return preview;
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
@end
