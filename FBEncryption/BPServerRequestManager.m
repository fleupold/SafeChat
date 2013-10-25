//
//  BPServerRequestManager.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/25/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPServerRequestManager.h"

@implementation BPServerRequestManager

const NSString *BaseUrl = @"http://blockprism.likescale.com/";

+(void)publicKeyForID: (NSString *)facebookID
           completion: (void(^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
              failure: (void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock
{
    NSString *urlString = [NSString stringWithFormat: @"%@/public_key/facebook?facebook_id=%@", BaseUrl, facebookID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL: url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess: successBlock failure:failureBlock];
    [operation start];
}

@end
