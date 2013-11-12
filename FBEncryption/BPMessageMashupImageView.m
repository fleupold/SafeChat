//
//  BPMessageMashupImageView.m
//  FBEncryption
//
//  Created by Felix Leupold on 11/7/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPMessageMashupImageView.h"
#import "UIImage+JSMessagesView.h"

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

-(id)initWithStyle: (BPMessageMashupStyle)aStyle {
    style = aStyle;
    return [super init];
}

-(void)setUserID:(NSString *)userID
{
    if (!cache) {
        cache = [NSMutableDictionary dictionary];
    }
    
    _userID = userID;
    if ([cache objectForKey: userID] != nil) {
        self.image = [cache objectForKey: userID];
    } else {
        self.image = [UIImage imageNamed:@"defaultUserIcon"];
        [self performSelectorInBackground:@selector(fetchImageForUser:) withObject:userID];
    }
}
-(NSString*)userID
{
    return _userID;
}

-(void)setImage:(UIImage *)image {
    if (style == BPMessageMashupStyleCircle) {
        image = [image js_imageAsCircle:YES
                                      withDiamter:50.0
                                      borderColor:[UIColor colorWithHue:0.0f saturation:0.0f brightness:0.8f alpha:1.0f]
                                      borderWidth:1.0f
                                     shadowOffSet:CGSizeMake(0.0f, 1.0f)];
        
    }
    [super setImage:image];
}

-(void)fetchImageForUser:(NSString *)userID
{
    NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square", userID];
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString: url]];
    
    UIImage *image = [UIImage imageWithData:imageData];
    [cache setObject:image forKey:userID];
    self.image = image;
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
