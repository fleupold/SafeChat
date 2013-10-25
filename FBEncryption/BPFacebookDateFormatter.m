//
//  BPFacebookDateFormatter.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPFacebookDateFormatter.h"

@implementation BPFacebookDateFormatter

-(BPFacebookDateFormatter *)init
{
    self = [super init];
    [self setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    return self;
}

@end
