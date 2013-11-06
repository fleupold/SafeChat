//
//  BPConfigurationViewController.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BPJavascriptRuntime.h"
#import <FacebookSDK/FacebookSDK.h>

@interface BPConfigurationViewController : UIViewController <UIAlertViewDelegate>

@property IBOutlet UIScrollView *scrollView;
@property IBOutlet UILabel *username;
@property IBOutlet UIView *loadingView;
@property IBOutlet UIActivityIndicatorView *spinner;
@property IBOutlet FBProfilePictureView *profilePictureView;

@property IBOutlet UIView *setupView;
@property IBOutlet UITextField *passphraseField;
@property IBOutlet UIButton *generateButton;

@property IBOutlet UIView *securedView;
@property IBOutlet UIImageView *lock;

-(IBAction)generateKeyPair:(id)sender;
-(IBAction)resetPassword:(id)sender;

@end
