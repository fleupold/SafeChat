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
@synthesize id, created, from;

+(BPMessage *)messageFromFBGraphObject: (FBGraphObject *)object {
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

+(BPMessage *)messageFromText:(NSString *)text
{
    BPMessage *message = [[BPMessage alloc] init];
    message.from = [BPFriend me];
    message.created = [NSDate date];
    message.text = text;
    return message;
}

-(NSString *)text
{
    if ([_text rangeOfString: @"BLOCKPRISM.ORG"].location != NSNotFound) {
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
    //Each message consists of multiple ciphers, one for each user.
    //We break up the message into a submessage for each user and
    //look for the one that is currently logged in.
    BPFriend *me = [BPFriend me];
    NSArray *submessages = [message componentsSeparatedByString: @"BLOCKPRISM.ORG_"];
    for (NSString *submessage in submessages)
    {
        if ([submessage rangeOfString: me.username].location == NSNotFound)
            continue;
        NSString *cipher = [submessage componentsSeparatedByString: @"@"][1];
        
        @try {
            return [[BPJavascriptRuntime getInstance] decrypt: cipher];
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
    for (BPFriend *participant in participants)
    {
        NSString *cipher = [[BPJavascriptRuntime getInstance] encrypt: self.text withPublicKey:participant.publicKey];
        NSString *encryptedPart = [NSString stringWithFormat: @"BLOCKPRISM.ORG_%@@%@", participant.username, cipher];
        encryptedMessage = [encryptedMessage stringByAppendingString: encryptedPart];
    }
    return encryptedMessage;
}

@end
