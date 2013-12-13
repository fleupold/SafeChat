//
//  BPFqlThread.h
//  SafeChat
//
//  Created by Felix Leupold on 11/16/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPThread.h"

@interface BPFqlThread : BPThread


@property BOOL hasLoadedMessages;
@property BOOL isUpdating;

-(void)updateWithThread: (BPThread *)newThread;
-(void)update;

@end
