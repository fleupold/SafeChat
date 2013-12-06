//
//  BPConfigurationViewController.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPConfigurationViewController.h"
#import "BPServerRequestManager.h"
#import "BPFriend.h"
#import "IonIcons.h"
#import "BPAppDelegate.h"

@interface BPConfigurationViewController ()

@end

@implementation BPConfigurationViewController
@synthesize passphraseField, loadingView, spinner;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self registerForKeyboardNotifications];

    //iconize the navbar
    UIImage *backImage = [IonIcons imageWithIcon:icon_chevron_left
                                  iconColor:[UIColor grayColor]
                                   iconSize:24.0f
                                  imageSize:CGSizeMake(24.0f, 24.0f)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage: backImage
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:self
                                                                            action:@selector(handleBack:)];
    
    UIImage *logoutImage = [IonIcons imageWithIcon:icon_log_out
                                        iconColor:[UIColor grayColor]
                                         iconSize:32.0f
                                        imageSize:CGSizeMake(32.0f, 32.0f)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage: logoutImage
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(logoutButtonWasPressed:)];
    
    //initialize personal information
    self.username.text = [BPFriend me].name;
    self.profilePictureView.profileID = [BPFriend me].username;
    self.profilePictureView.layer.cornerRadius = self.profilePictureView.frame.size.height / 2; //makes it a circle\
    
    //initialize the lock icon
    UIImage *icon = [IonIcons imageWithIcon:icon_locked
                                  iconColor:[UIColor grayColor]
                                   iconSize:128.0f
                                  imageSize:CGSizeMake(128.0f, 128.0f)];
    self.lock.image = icon;
    
    //Check if encryption is set up, and tell user that everything is secure or that he needs to enter a key
    if ([BPJavascriptRuntime privateKeyAvailable])
    {
        self.securedView.hidden = NO;
        self.setupView.hidden = YES;
    } else {
        self.securedView.hidden = YES;
        self.setupView.hidden = NO;
        self.passphraseField.text = @"";
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)generateKeyPair:(id)sender
{
    //Hide the keyboard
    [self.passphraseField resignFirstResponder];
    
    if (!self.limitedAccessToken) {
        [self openSessionForAuthenticatorAppOverride: NO];
    }
    else {
        [self generateKeyPairWithAccessToken: self.limitedAccessToken override: NO];
    }
}
    
-(void)generateKeyPairWithAccessToken:(NSString *)token override: (BOOL)override
{
    //start the activity view
    loadingView.hidden = NO;
    [spinner startAnimating];
    self.navigationItem.hidesBackButton = YES;
    
    //if the sender was an alertView it means we should override the public key
    
    BPJavascriptRuntime *jsRuntime = [BPJavascriptRuntime getInstance];
    NSString *publicKey = [jsRuntime generatePublicKeyWithPassphrase: self.passphraseField.text];
    
    [BPServerRequestManager storePublicKey:publicKey
                                     forID:[BPFriend me].username
                                  override: override
                                completion:^(AFHTTPRequestOperation *operation, id responseObject) {
                                    [self keyPairGenerated];
                                }
                                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                       NSLog(@"%@", error);
                                       if ([operation.responseString isEqualToString: @"Wrong public key"]) {
                                           [self wrongPassphraseAlert];
                                       } else {
                                           [self alertError: error];
                                       }
                                   }];
}

- (BOOL)openSessionForAuthenticatorAppOverride: (BOOL) override {
    /*
     * We need two kind of Access tokens: One that has full rights for reading and sending
     * messages on behalf of the user. This token may not leave the application due to
     * privacy concerns.
     * We also need an accesstoken to validate that the user who is setting the public key
     * on our server is authenticated with Facebook and authorized to do so.
     * If we used the first access token for that purpose, the server would be able to read
     * all unencrypted messages of the user.
     * 
     * Therefore, there is another application with minimal rights. The access token for this
     * application is sent to our server to authenitcate the user.
     */

    NSString* authenticatorAppId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AuthenticatorAppId"];
    NSString* clientAppId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"FacebookAppID"];


    //We need a custom caching strategy, otherwise the old token will be reused...
    FBSessionTokenCachingStrategy *cachingStrategy = [[FBSessionTokenCachingStrategy alloc] initWithUserDefaultTokenInformationKeyName: authenticatorAppId];
    [cachingStrategy clearToken];
    FBSession *session = [[FBSession alloc] initWithAppID: authenticatorAppId
                                              permissions:nil
                                          urlSchemeSuffix:nil
                                       tokenCacheStrategy:cachingStrategy];
    
    //We also need to temporarily make the new session the active session to handle back entrance in our app after login
    FBSession *mainSession = [FBSession activeSession];
    FBAccessTokenData *mainToken = mainSession.accessTokenData;
    [FBSession setActiveSession:session];
    

    [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent
            completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         if ([session isOpen]) {
             self.limitedAccessToken = session.accessTokenData.accessToken;
             [self generateKeyPairWithAccessToken: self.limitedAccessToken  override: override];
         }
         if (session.state != FBSessionStateClosed) {
             [[FBSession alloc] openFromAccessTokenData: mainToken
                                  completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                      session.appID = clientAppId;
                                      [FBSession setActiveSession: session];
                                  }];
         }
     }];
    return session.isOpen;
}

-(void)alertError: (NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Error" message:@"Sorry, we could not setup encryption!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
    [alert show];
}

-(void)wrongPassphraseAlert
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Wrong Password" message:@"Do you want to overwrite the current password?" delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:@"No", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString: @"Wrong Password"] && buttonIndex == 0) {
        [self generateKeyPairWithAccessToken: self.limitedAccessToken override: YES];
        return;
    }
    [self resetPassword: nil];
    [self keyPairGenerated];
}


-(void)keyPairGenerated
{
    //Unload spinner
    [spinner stopAnimating];
    loadingView.hidden = YES;
    [self viewDidLoad];
}

-(IBAction)resetPassword:(id)sender
{
    [BPJavascriptRuntime resetPrivateKey];
    [self viewDidLoad];
}

-(void)logoutButtonWasPressed:(id)sender {
    [FBSession.activeSession closeAndClearTokenInformation];
    BPAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate showLoginView];
}

-(void)handleBack:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:TRUE];
}

// Keyboard handling
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height + 30, 0.0);
    if (!UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.width + 35, 0.0);
    }
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        aRect.size.height -= kbSize.height;
    } else {
        aRect.size.width -=kbSize.width;
    }
    
    if (!CGRectContainsPoint(aRect, self.generateButton.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.generateButton.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

@end
