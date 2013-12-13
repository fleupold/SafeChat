//
//  BPFqlRequestManager.m
//  SafeChat
//
//  Created by Felix Leupold on 11/13/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPFqlRequestManager.h"
#import "BPFriend.h"
#import "AFHTTPRequestOperation.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation BPFqlRequestManager

static const NSString *fqlUrl = @"https://graph.facebook.com/fql?q=";

+(void)requestThreadIdForUser: (NSString *)userId
                   completion: (void(^)(NSDictionary *thread))successBlock
                      failure: (void(^)(NSError *error))failureBlock
{
    NSString *fql = [NSString stringWithFormat:@"SELECT thread_id,  updated_time, snippet, snippet_author, unread, recipients from thread  where '%@' in recipients AND folder_id = 0", userId];

    AFHTTPRequestOperation *operation = [BPFqlRequestManager operationForFql:fql];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *data = [responseObject objectForKey: @"data"];        
        for (NSDictionary *thread in data) {
            NSArray *recipients  = [thread objectForKey: @"recipients"];
            if (recipients.count == 2) {
                successBlock(thread);
                return;
            }
        }
        successBlock(nil);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(error);
    }];
    
    [operation start];
}

+(void)requestThreadsBefore: (NSDate *)before
                      after: (NSDate *)after
             withCompletion: (void(^)(NSDictionary *response))successBlock
                    failure: (void(^)(NSError *error))failureBlock
{
    NSString *fql = [NSString stringWithFormat: @"SELECT thread_id, updated_time, snippet, snippet_author, unread, recipients FROM thread where folder_id = 0 AND updated_time < %.0f AND updated_time >= %.0f ORDER BY updated_time DESC", [before timeIntervalSince1970], [after timeIntervalSince1970]];
    AFHTTPRequestOperation *operation = [BPFqlRequestManager operationForFql:fql];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        successBlock(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", fql);
        failureBlock(error);
    }];
    
    [operation start];
}

+(void)createUsersWithIDs: (NSSet *)userIds
               completion: (void(^)(void))successBlock
                  failure: (void(^)(NSError *error))failureBlock
{
    NSMutableString *prettySetString = [@"(" mutableCopy];
    for (NSString *userId in userIds) {
        [prettySetString appendFormat: @"%@,", userId];
    }
    [prettySetString replaceCharactersInRange: NSMakeRange(prettySetString.length - 1, 1) withString:@")"];
    
    NSString *fql = [NSString stringWithFormat: @"SELECT name, username, uid from user where uid in %@", prettySetString];
    AFHTTPRequestOperation *operation = [BPFqlRequestManager operationForFql:fql];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        for (NSDictionary *userInfo in [responseObject objectForKey:@"data"])
        {
            BPFriend *user = [BPFriend findOrCreateFriendWithId: [[userInfo objectForKey: @"uid"] stringValue] andName: [userInfo objectForKey:@"name"]];
            user.username = [userInfo objectForKey: @"username"];
        }
        successBlock();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(error);
    }];
    
    [operation start];
}

+(void)requestMessagesForThreadId: (NSString *)threadID
                           before: (NSDate *)before
                            after: (NSDate *)after
                     completion: (void(^)(NSDictionary *response))successBlock
                        failure: (void(^)(NSError *error))failureBlock
{
    NSString *fql = [NSString stringWithFormat:@"SELECT author_id, body, created_time, message_id from message WHERE thread_id=%@ AND created_time < %.0f AND created_time > %.0f", threadID, [before timeIntervalSince1970], [after timeIntervalSince1970]];
    AFHTTPRequestOperation *operation = [BPFqlRequestManager operationForFql:fql];

    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        successBlock(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(error);
    }];
    
    [operation start];
}


+(AFHTTPRequestOperation *)operationForFql: (NSString *)fql
{
    NSString *url = [NSString stringWithFormat: @"%@%@&access_token=%@", fqlUrl, fql, FBSession.activeSession.accessTokenData.accessToken];
    NSString *escapedUrl = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString: escapedUrl]];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest: request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    return operation;
}

@end
