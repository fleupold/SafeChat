//
//  BPThread.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>
#import "BPMessage.h"

@class BPThread;
@protocol BPThreadDelegate <NSObject>
@required
-(void)encryptionSupportHasBeenCheckedAndIsAvailable: (BOOL)isAvailable;

@optional
- (void)hasUpdatedThread: (BPThread *)thread;
@end

@interface BPThread : NSObject

@property id<BPThreadDelegate> delegate;

@property NSDate *updated_at;
@property NSInteger unread, unseen;
@property NSMutableArray *messages, *participants;
@property NSString *id;

@property NSString *nextPage;

+ (BPThread *)threadFromFBGraphObject: (FBGraphObject *)object;
+ (BPThread *)emptyThreadWith:(BPFriend *)user;

-(NSString *)participantsPreview;
-(NSString *)textPreview;
-(UIImage *)avatar;

-(void)checkEncryptionSupport;
-(void)sendMessage: (NSString *)text encrypted: (BOOL)shouldBeEncrypted;
-(void)addIncomingMessage: (NSString *)text from: (BPFriend *)friend;

-(void)update;
@end
