//
//  BPFacebookDateFormatter.m
//  SafeChat
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

+(NSString *)prettyPrint: (NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:date];
    NSDateComponents *todayComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    
    if (dateComponents.day == todayComponents.day && dateComponents.month == todayComponents.month && dateComponents.year == todayComponents.year) {
        formatter.dateFormat = @"HH:mm"; //Same Day
    } else if (dateComponents.day > todayComponents.day - 7 && dateComponents.month == todayComponents.month && dateComponents.year == todayComponents.year){
        formatter.dateFormat = @"eee"; //Same Week
    } else {
        formatter.dateFormat = @"dd. MMM";
    }
    
    return [formatter stringFromDate: date];
}

@end
