//
//  BPFacebookDateFormatter.h
//  SafeChat
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BPFacebookDateFormatter : NSDateFormatter

+(NSString *)prettyPrint: (NSDate *)date;

@end
