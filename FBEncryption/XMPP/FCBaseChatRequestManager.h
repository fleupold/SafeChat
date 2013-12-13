//
//  FCBaseChatRequestManager.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>
#import "XMPP.h"

#define DEFAULT_TIMEOUT 10
#define REPEATS_ON_FAILURE 2
#define WAIT_BETWEEN_REPEATS 5

@interface FCBaseChatRequestManager : NSObject <XMPPStreamDelegate>

@property (readonly, nonatomic, strong) XMPPStream *xmppStream;

- (void)sendMessageToFacebook:(NSString*)textMessage
         withFriendFacebookID:(NSString*)friendID;

+(FCBaseChatRequestManager *)getInstance;
@end
