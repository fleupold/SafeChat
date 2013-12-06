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
#import "BPFriend.h"
#import "BPJavascriptRuntime.h"

@implementation BPAppDelegate

@synthesize navController = _navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    [FBLoginView class];
    [BPJavascriptRuntime getInstance];
    self.navController = (UINavigationController *) self.window.rootViewController;
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        // Yes, so just open the session (this won't display any UX).
        [self openSession];
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

@end
