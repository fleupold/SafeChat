//
//  BPFacebookLoginViewController.h
//  SafeChat
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface BPFacebookLoginViewController : UIViewController <FBLoginViewDelegate>

@property (weak) IBOutlet UIActivityIndicatorView *spinner;
@property IBOutlet FBLoginView *loginView;
@property IBOutlet UIButton *dismissButton;

- (void)loginFailed;
- (IBAction)dismissButtonPressed:(id)sender;

@end
