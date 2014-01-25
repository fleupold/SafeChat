//
//  BPFacebookLoginViewController.m
//  SafeChat
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPFacebookLoginViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#import "IonIcons.h"

#import "BPAppDelegate.h"
#import "BPFriend.h"
#import "BPJavascriptRuntime.h"

@interface BPFacebookLoginViewController ()

@end

@implementation BPFacebookLoginViewController
@synthesize spinner = _spinner;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.loginView.delegate = self;
    [self.loginView setReadPermissions: @[@"read_mailbox", @"xmpp_login"]];
    
    //if we are not logged in, there should be no way to dismiss the view
    if (FBSession.activeSession.isOpen) {
        self.dismissButton.hidden = NO;
    } else {
        self.dismissButton.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loginFailed
{
    // User switched back to the app without authorizing. Stay here, but
    // stop the spinner.
    [self.spinner stopAnimating];
}

- (IBAction)dismissButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    self.dismissButton.hidden = YES;
    [BPJavascriptRuntime resetPrivateKey];
    
    BPAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate clearConversations];
    
    [BPFriend clearFriendList];
}
@end
