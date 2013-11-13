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
                   completion: (void(^)(NSString *threadID))successBlock
                      failure: (void(^)(NSError *error))failureBlock;
@end
