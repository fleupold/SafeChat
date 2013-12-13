//
//  BPAppDelegate.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/21/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BPAppDelegate : UIResponder <UIApplicationDelegate>
{
    void (^backgroundAppRefreshCompletionHandler)(UIBackgroundFetchResult result);
    NSInteger unfinishedRefreshingThreads;
    NSDate *backgroundEntryTime;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController* navController;

- (void)openSession;
- (void)showLoginView;

- (void)clearConversations;

#pragma mark - Background Mode
-(void)appRefreshDidFail;
-(void)setNumberOfRefreshingThreads: (NSInteger) refreshCount;
-(void)threadFinishedRefresh;
-(BOOL)isInBackgroundMode;
- (NSDate *)backgroundEntryTime;

@end
