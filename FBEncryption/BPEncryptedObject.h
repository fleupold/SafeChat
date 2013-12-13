//
//  BPEncryptedObject.h
//  SafeChat
//
//  Created by Felix Leupold on 10/22/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EncryptedObjectExport
@property  NSString *cipher;

@end

@interface BPEncryptedObject : NSObject <EncryptedObjectExport>
@end
