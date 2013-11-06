//
//  BPServerRequestManager.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/25/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperation.h"
#import "AFHTTPRequestOperationManager.h"

@interface BPServerRequestManager : AFHTTPRequestOperationManager

+(void)publicKeyForID: (NSString *)facebookID
           completion: (void(^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
              failure: (void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;
    
+(void)storePublicKey: (NSString *)key
                forID: (NSString *)facebookID
             override: (BOOL) override
           completion: (void(^)(AFHTTPRequestOperation *operation, id responseObject))successBlock
              failure: (void(^)(AFHTTPRequestOperation *operation, NSError *error))failureBlock;


@end
