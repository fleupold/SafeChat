//
//  BPFqlRequestManager.h
//  FBEncryption
//
//  Created by Felix Leupold on 11/13/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BPFqlRequestManager : NSObject

+(void)requestThreadIdForUser: (NSString *)name
                   completion: (void(^)(NSDictionary *thread))successBlock
                      failure: (void(^)(NSError *error))failureBlock;

+(void)requestThreadsBefore: (NSDate *)before
             withCompletion: (void(^)(NSDictionary *response))successBlock
                    failure: (void(^)(NSError *error))failureBlock;

+(void)createUsersWithIDs: (NSSet *)userIds
               completion: (void(^)(void))successBlock
                  failure: (void(^)(NSError *error))failureBlock;

+(void)requestMessagesForThreadId: (NSString *)threadID
                           before: (NSDate *)before
                       completion: (void(^)(NSDictionary *response))successBlock
                          failure: (void(^)(NSError *error))failureBlock;
@end
