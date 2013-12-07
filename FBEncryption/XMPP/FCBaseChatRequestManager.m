//
//  FCBaseChatRequestManager.m
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import "FCBaseChatRequestManager.h"
#import <FacebookSDK/FacebookSDK.h>

@interface FCBaseChatRequestManager ()
@end

@implementation FCBaseChatRequestManager

static FCBaseChatRequestManager *instance;

+(FCBaseChatRequestManager *)getInstance {
    if (instance == nil) {
        instance = [[FCBaseChatRequestManager alloc] init];
    }
    return instance;
}

- (id)init
{
    if (self = [super init]) {
        FBSession *activeSession = FBSession.activeSession;
        _xmppStream = [[XMPPStream alloc] initWithFacebookAppId:activeSession.appID];
        [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        [self connect];
    }
    return self;
}
-(void) connect
{
    NSError *error= nil;
    if (![_xmppStream connectWithTimeout:DEFAULT_TIMEOUT error:&error]) {
        NSLog(@"Couldn't connect: %@", error);
    }
}

#pragma mark XMPPStream Delegate methods
- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    if (![self.xmppStream isSecure])
    {
        NSLog(@"XMPP STARTTLS...");
        NSError *error = nil;
        BOOL result = [self.xmppStream secureConnection:&error];
        
        if (result == NO)
        {
            NSLog(@"XMPP STARTTLS failed: %@", error);
        }
    }
    else
    {
        NSLog(@"XMPP X-FACEBOOK-PLATFORM SASL...");
        NSError *error = nil;
        BOOL result = [self.xmppStream authenticateWithFacebookAccessToken: FBSession.activeSession.accessTokenData.accessToken
                                                                     error:&error];
        
        if (result == NO)
        {
            NSLog(@"XMPP authentication failed: %@", error);
        }
    }
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	if (NO)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (NO)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		NSString *expectedCertName = [sender hostName];
		if (expectedCertName == nil)
		{
			expectedCertName = [[sender myJID] domain];
		}
        
		[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
    NSLog(@"XMPP STARTTLS...");
    
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"XMPP authenticated");
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
    NSLog(@"XMPP authentication failed: %@", error);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
    NSLog(@"XMPP disconnected");
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    // we recived message
    NSLog(@"Message received: %@", message.description);
    [[NSNotificationCenter defaultCenter] postNotificationName: @"didReceiveMessage" object:message];
}

-(void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error {
    NSLog(@"Failed to send message: %@", error);
    NSInteger numberOfTries = [[[message attributeForName: @"attempt"] stringValue] integerValue];
    if (numberOfTries <= REPEATS_ON_FAILURE) {
        [message addAttributeWithName:@"attempt" stringValue:[NSString stringWithFormat: @"%ld", (long)numberOfTries+1]];
        [self.xmppStream performSelector:@selector(sendElement:) withObject:message afterDelay: WAIT_BETWEEN_REPEATS];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName: @"didFailToSendMessage" object: message];
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    NSLog(@"sent");
}

- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender {
    NSLog(@"Timeout");
}

-(void)xmppStream:(XMPPStream *)sender didReceiveError:(DDXMLElement *)error
{
    NSLog(@"Received Error: %@", error);
}

#pragma mark send message to Facebook.
- (void)sendMessageToFacebook:(NSString*)textMessage withFriendFacebookID:(NSString*)friendID
{
    if (!self.xmppStream.isConnected) {
        [self connect];
    }
    
    if([textMessage length] > 0) {
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:textMessage];
        
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        //[message addAttributeWithName:@"xmlns" stringValue:@"http://www.facebook.com/xmpp/messages"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:[NSString stringWithFormat:@"-%@@chat.facebook.com",friendID]];
        [message addAttributeWithName:@"attempt" stringValue:@"1"];
        [message addChild:body];
        [self.xmppStream sendElement:message];
    }
}

@end
