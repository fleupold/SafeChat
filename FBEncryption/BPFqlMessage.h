//
//  BPFqlMessage.h
//  FBEncryption
//
//  Created by Felix Leupold on 11/16/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPThread.h"

@interface BPFqlMessage : BPThread
+(id)messageFromFBGraphObject: (FBGraphObject *)object;

@end
