//
//  BPThread.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

@protocol BPThreadDelegate <NSObject>
@required
-(void)encryptionSupportHasBeenCheckedAndIsAvailable: (BOOL)isAvailable;
@end

@interface BPThread : NSObject

@property id<BPThreadDelegate> delegate;

@property NSDate *updated_at;
@property NSInteger unread, unseen;
@property NSMutableArray *messages, *participants;
@property NSString *id;

+ (BPThread *)threadFromFBGraphObject: (FBGraphObject *)object;

-(NSString *)participantsPreview;
-(NSString *)textPreview;
-(UIImage *)avatar;

-(void)checkEncryptionSupport;
-(void)sendMessage: (NSString *)text encrypted: (BOOL)shouldBeEncrypted;

@end
