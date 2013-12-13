//
//  BPFqlMessage.h
//  SafeChat
//
//  Created by Felix Leupold on 11/16/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPThread.h"

@interface BPFqlMessage : BPMessage
+(id)messageFromFBGraphObject: (FBGraphObject *)object;

@end
