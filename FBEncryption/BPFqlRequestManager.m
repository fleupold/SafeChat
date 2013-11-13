//
//  BPFqlRequestManager.m
//  FBEncryption
//
//  Created by Felix Leupold on 11/13/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPFqlRequestManager.h"
#import "AFHTTPRequestOperation.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation BPFqlRequestManager

static const NSString *fqlUrl = @"https://graph.facebook.com/fql?q=";

+(void)requestThreadIdForUser: (NSString *)name
                   completion: (void(^)(NSString *threadID))successBlock
                      failure: (void(^)(NSError *error))failureBlock
{
    NSString *fql = [NSString stringWithFormat:@"SELECT thread_id from unified_thread  where '%@' in thread_and_participants_name AND not is_group_conversation", name];
    NSString *url = [NSString stringWithFormat: @"%@%@&access_token=%@", fqlUrl, fql, FBSession.activeSession.accessTokenData.accessToken];
    NSString *escapedUrl = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString: escapedUrl]];

    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest: request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *data = [responseObject objectForKey: @"data"];
        if (data.count == 0) {
            successBlock(nil);
        }
        NSString *threadID = [data.firstObject objectForKey: @"thread_id"];
        successBlock(threadID);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failureBlock(error);
    }];
    
    [operation start];
}

@end
