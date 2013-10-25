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

@interface BPDetailViewController : UIViewController <BPThreadDelegate, UITextViewDelegate>

@property (strong, nonatomic) BPThread *detailItem;
@property BOOL encryptionEnabled;

@property IBOutlet UITextView *messageView;
@property IBOutlet UIImageView *lockImage;
@property IBOutlet UITextField *messageInput;

-(IBAction)sendMessage:(id)sender;
@end
