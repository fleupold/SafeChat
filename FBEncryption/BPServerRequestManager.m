//
//  BPServerRequestManager.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/25/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPServerRequestManager.h"
#import <FacebookSDK/FacebookSDK.h>

@implementation BPServerRequestManager

const NSString *BaseUrl = @"http://blockprism2.likescale.com";

+(void)publicKeyForID: (NSString *)facebookID
           completion: (void(^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
              failure: (void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock
{
    NSString *urlString = [NSString stringWithFormat: @"%@/public_key/facebook/", BaseUrl];
    NSDictionary *params = @{@"facebook_id": facebookID};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:urlString parameters: params success:successBlock failure:failureBlock];
}
    
+(void)storePublicKey: (NSString *)key
                forID: (NSString *)facebookID
       withAccessToke: (NSString *)accessToken
             override: (BOOL) override
           completion: (void(^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
              failure: (void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *urlString = [NSString stringWithFormat: @"%@/public_key/facebook/", BaseUrl];
    NSDictionary *params = @{@"facebook_id": facebookID,
                             @"public_key": key,
                             @"access_token": accessToken,
                             @"override": @(override)};
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:urlString parameters:params success:successBlock failure:failureBlock];
}
    

@end
