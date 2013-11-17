//
//  FCBaseChatRequestManager.h
//  FacebookChat
//
//  Created by Kanybek Momukeev on 7/28/13.
//
//

#import <Foundation/Foundation.h>
#import "XMPP.h"

@protocol FCBaseChatRequestManagerDelegate <NSObject>

@optional
-(void)didFailToSendMessage: (NSString *)text;
-(void)didReceiveMessage: (XMPPMessage *)message;
@end

@interface FCBaseChatRequestManager : NSObject <XMPPStreamDelegate>

@property (readonly, nonatomic, strong) XMPPStream *xmppStream;
@property id<FCBaseChatRequestManagerDelegate> delegate;

- (void)sendMessageToFacebook:(NSString*)textMessage
         withFriendFacebookID:(NSString*)friendID;

+(FCBaseChatRequestManager *)getInstance;
@end
