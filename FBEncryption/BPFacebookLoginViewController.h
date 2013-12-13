//
//  BPFacebookLoginViewController.h
//  SafeChat
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>

@interface BPFacebookLoginViewController : UIViewController

@property (weak) IBOutlet UIActivityIndicatorView *spinner;
@property IBOutlet FBLoginView *loginView;

- (void)loginFailed;

@end
