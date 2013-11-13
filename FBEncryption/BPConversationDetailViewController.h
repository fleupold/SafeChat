//
//  BPDetailViewController.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/21/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BPThread.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSMessagesViewController.h"

@interface BPConversationDetailViewController : JSMessagesViewController <BPThreadDelegate, JSMessagesViewDataSource, JSMessagesViewDelegate>
{
    NSDate *lastTyping;
    BPFriend *personTyping;
    BOOL isReloading;
}
@property (strong, nonatomic) BPThread *detailItem;
@property BOOL encryptionEnabled;

@property IBOutlet UIImageView *lockImage;
@property IBOutlet UIButton *sendButton;
@property IBOutlet UIActivityIndicatorView *spinner;

@end
