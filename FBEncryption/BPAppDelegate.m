//
//  BPAppDelegate.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/21/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPAppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>
#import "BPFacebookLoginViewController.h"
#import "BPConversationMasterViewController.h"
#import "BPFriend.h"
#import "BPJavascriptRuntime.h"

@implementation BPAppDelegate

@synthesize navController = _navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval: 10];
    [self registerDefaultsFromSettingsBundle];
    
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    [FBLoginView class];
    [BPJavascriptRuntime getInstance];
    self.navController = (UINavigationController *) self.window.rootViewController;
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        // Yes, so just open the session (this won't display any UX).
        [self openSession];
        [self checkEncryptionConfigured];
    } else {
        // No, display the login page.
        [self showLoginView];
    }
    [FBProfilePictureView class];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString* authenticatorAppId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"AuthenticatorAppId"];
    if ([url.absoluteString hasPrefix: [@"fb" stringByAppendingString: authenticatorAppId]]) {
        return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    }
    else {
        BOOL result = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
        FBSession *activeSession = [FBSession activeSession];
        [self sessionStateChanged: activeSession state: activeSession.state error:nil];
        [self checkEncryptionConfigured];

        return result;
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Background Mode
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    backgroundAppRefreshCompletionHandler = completionHandler;
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    BPConversationMasterViewController *conversations = [navController.viewControllers objectAtIndex:0];
    [conversations fetchThreads];
}

-(BOOL)isInBackgroundMode
{
    return backgroundAppRefreshCompletionHandler != nil;
}

-(void)appRefreshDidFail
{
    [self appRefreshFinished: UIBackgroundFetchResultFailed];
}

-(void)appRefreshFinished: (UIBackgroundFetchResult) result
{
    if (backgroundAppRefreshCompletionHandler) {
        backgroundAppRefreshCompletionHandler(result);
    }
    unfinishedRefreshingThreads = 0;
    backgroundAppRefreshCompletionHandler = nil;
}

-(void)setNumberOfRefreshingThreads: (NSInteger) refreshCount
{
    if (![self isInBackgroundMode])
        return;
    
    if (refreshCount == 0) {
        [self appRefreshFinished: UIBackgroundFetchResultNoData];
    }
    
    unfinishedRefreshingThreads = refreshCount;
}

-(void)threadFinishedRefresh
{
    unfinishedRefreshingThreads -= 1;
    if (unfinishedRefreshingThreads == 0) {
        [self appRefreshFinished: UIBackgroundFetchResultNewData];
    }
}

#pragma marke - Facebook login methods

- (void)showLoginView
{
    UIViewController *modalViewController = self.window.rootViewController.presentedViewController;
    
    // If the login screen is not already displayed, display it. If the login screen is
    // displayed, then getting back here means the login in progress did not successfully
    // complete. In that case, notify the login view so it can update its UI appropriately.
    if (![modalViewController isKindOfClass:[BPFacebookLoginViewController class]]) {
        [self.navController performSegueWithIdentifier: @"LoginWithFacebook" sender:self];
    } else {
        BPFacebookLoginViewController* loginViewController = (BPFacebookLoginViewController*)modalViewController;
        [loginViewController loginFailed];
    }
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen: {
            [self registerMe];
            [self fetchFriends];
            UIViewController *modalViewController = self.window.rootViewController.presentedViewController;
            if ([modalViewController isKindOfClass:[BPFacebookLoginViewController class]]) {
                [modalViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }
            break;
        case FBSessionStateClosedLoginFailed:
            // Once the user has logged in, we want them to
            // be looking at the root view.
            [self.navController popToRootViewControllerAnimated:NO];
            
            [FBSession.activeSession closeAndClearTokenInformation];
            
            [self showLoginView];
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)openSession
{
    [FBSession openActiveSessionWithReadPermissions:@[@"read_mailbox", @"xmpp_login"]
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
}

#pragma mark - launch queries

-(void)registerMe
{
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary<FBGraphUser> *user,
           NSError *error) {
             if (!error) {
                 [BPFriend createMe: user];
             }
         }];
    }
}

-(void)fetchFriends
{
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForGraphPath:@"me/friends?fields=username,name"] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary *friends,
           NSError *error) {
             if (!error) {
                 for (NSDictionary<FBGraphUser> *friend in [friends objectForKey: @"data"])
                     [BPFriend findOrCreateFriendWithId: friend.id andName:friend.name];
             }
             else {
                 NSLog(@"%@", error);
             }
         }];
    }
}

-(void)checkEncryptionConfigured
{
    if([BPFriend meHasEncryptionConfigured] || FBSession.activeSession.state == FBSessionStateCreated) {
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"No Private Key"
                                                    message: @"Do you want to set up encryption now?"
                                                   delegate: self
                                          cancelButtonTitle: @"Yes"
                                          otherButtonTitles:@"No", nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *configurationVc = [storyboard instantiateViewControllerWithIdentifier:@"ConfigurationViewController"];
        [(UINavigationController*) self.window.rootViewController pushViewController: configurationVc animated:YES];
    }
}

#pragma mark - Settings
- (void)registerDefaultsFromSettingsBundle {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // Look up the bundle in order to get the preference list
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    // Get the preferences for the ESV App
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    
    // For each preference check if the key is already set in the general settings.
    // If not, then add the key together with the corresponding default value.
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        
        if(key) {
            NSObject *existingValue = [userDefaults objectForKey:key];
            if (!existingValue) {
                [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
            }
        }
    }
    // Adding the default keys to the preferences
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

@end
