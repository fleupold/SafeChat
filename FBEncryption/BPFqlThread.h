//
//  BPFqlThread.h
//  FBEncryption
//
//  Created by Felix Leupold on 11/16/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPThread.h"

@interface BPFqlThread : BPThread

@property BOOL hasLoadedMessages;

-(void)updateWithThread: (BPThread *)newThread;
-(void)update;

@end
