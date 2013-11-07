//
//  BPMessageMashupImageView.m
//  FBEncryption
//
//  Created by Felix Leupold on 11/7/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPMessageMashupImageView.h"

@implementation BPMessageMashupImageView {
}

static NSMutableDictionary *cache;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

-(void)setUserID:(NSString *)userID
{
    if (!cache) {
        cache = [NSMutableDictionary dictionary];
    }
    _userID = userID;
    if ([cache objectForKey: userID] != nil) {
        self.image = [cache objectForKey: userID];
        return;
    }
    self.image = [UIImage imageNamed:@"defaultUserIcon"];
    [self performSelectorInBackground:@selector(fetchImageForUser:) withObject:userID];
}
-(NSString*)userID
{
    return _userID;
}

-(void)fetchImageForUser:(NSString *)userID
{
    NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square", userID];
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString: url]];
    
    self.image = [UIImage imageWithData:imageData];
    [cache setObject:self.image forKey:userID];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
