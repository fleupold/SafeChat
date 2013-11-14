//
//  BPMessage.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPMessage.h"
#import "BPFacebookDateFormatter.h"
#import "BPJavascriptRuntime.h"

@implementation BPMessage
@synthesize id, created, from, failedToSend, encrypted;

+(id)messageFromFBGraphObject: (FBGraphObject *)object {
    BPMessage *message = [[BPMessage alloc] init];
    
    NSString *createdString = [object objectForKey:@"created_time"];
    message.created = [[[BPFacebookDateFormatter alloc] init] dateFromString:createdString];
    
    message.id = [object objectForKey: @"id"];
    message.text = [object objectForKey: @"message"];
    
    FBGraphObject *from = [object objectForKey: @"from"];
    message.from = [BPFriend findOrCreateFriendWithId:[from objectForKey: @"id"]
                                              andName:[from objectForKey: @"name"]];
    return message;
}

+(id)messageFromText:(NSString *)text
{
    BPMessage *message = [[BPMessage alloc] init];
    message.from = [BPFriend me];
    message.created = [NSDate date];
    message.text = text;
    return message;
}

-(id)init
{
    self = [super init];
    self.failedToSend = NO;
    self.encrypted = NO;
    return self;
}

-(NSString *)text
{
    if (_text != nil && [_text rangeOfString: @"BLOCKPRISM.ORG"].location != NSNotFound) {
        self.text = [self decryptMessage: _text];
    }
    return _text;
}

-(void)setText:(NSString *)text
{
    _text = text;
}

-(NSString *)decryptMessage: (NSString *)message
{
    self.encrypted = YES;
    //Each message consists of multiple ciphers, one for each user.
    //We break up the message into a submessage for each user and
    //look for the one that is currently logged in.
    BPFriend *me = [BPFriend me];
    NSArray *submessages = [message componentsSeparatedByString: @"BLOCKPRISM.ORG_"];
    for (NSString *submessage in submessages)
    {
        if ([submessage rangeOfString: me.username].location == NSNotFound)
            continue;
        
        NSArray *messageParts = [submessage componentsSeparatedByString: @"@"];
        if (messageParts.count != 3)
            //Does not confirm with the protocol
            continue;
        
        BPFriend *other = [BPFriend findByUsername: messageParts[0]];
        if (other == me) {
            other = [BPFriend findByUsername: messageParts[1]];
        }
        
        NSString *cipher = messageParts[2];
        @try {
            return [[BPJavascriptRuntime getInstance] decrypt:cipher withSessionKey: other.sessionKey];
        }
        @catch (NSException *exception) {
            return message;
        }
    }
    return @"Message couldn't be decrypted";
}

-(NSString *)encryptForParticipants: (NSArray *)participants
{
    NSString *encryptedMessage = @"";
    BPFriend *me = [BPFriend me];
    for (BPFriend *participant in participants)
    {
        if (participant == me) {
            continue;
        }
        NSString *cipher = [[BPJavascriptRuntime getInstance] encrypt: self.text withSessionKey:participant.sessionKey];
        NSString *encryptedPart = [NSString stringWithFormat: @"BLOCKPRISM.ORG_%@@%@@%@", me.username, participant.username, cipher];
        encryptedMessage = [encryptedMessage stringByAppendingString: encryptedPart];
    }
    self.encrypted = YES;
    return encryptedMessage;
}

@end
