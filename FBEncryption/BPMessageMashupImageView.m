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
@synthesize style;

static NSMutableDictionary *cache;
static NSLock *cache_lock;

-(id)initWithStyle: (BPMessageMashupStyle)aStyle {
    style = aStyle;
    return [super init];
}

-(void)setUserID:(NSString *)userID
{
    [self setUserIDs:@[userID]];
}

-(void)setUserIDs: (NSArray *)userIDs
{
    [self resetImage];
    
    if (!cache) {
        cache = [NSMutableDictionary dictionary];
        cache_lock = [[NSLock alloc] init];
    }
    
    if (userIDs.count == 0)
        return;
    
    NSMutableDictionary *missingImages = [NSMutableDictionary dictionary];
    if (userIDs.count >= 1) {
        NSString *firstUser = userIDs.firstObject;
        //leftImage = [cache objectForKey: firstUser];
        if (!leftImage) {
            leftImage = [UIImage imageNamed:@"defaultUserIcon"];
            [missingImages setObject: [NSNumber numberWithInt: 0] forKey:firstUser];
        }
    }
    
    if (userIDs.count >= 2)
    {
        NSString *secondUser = [userIDs objectAtIndex:1];
        //topRightImage = [cache objectForKey: secondUser];
        if (!topRightImage)
            topRightImage = [UIImage imageNamed:@"defaultUserIcon"];
            [missingImages setObject: [NSNumber numberWithInt: 1] forKey:secondUser];
    }
    
    if (userIDs.count >= 3)
    {
        NSString *thirdUser = [userIDs objectAtIndex:2];
        //bottomRightImage = [cache objectForKey: thirdUser];
        if (!bottomRightImage)
            bottomRightImage = [UIImage imageNamed:@"defaultUserIcon"];
            [missingImages setObject: [NSNumber numberWithInt: 2] forKey:thirdUser];
    }
    _userIDs = userIDs;
    self.image = [self mashup];
    _missingImages = missingImages;
    [self fetchMissingImagesAsync];
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

-(void)fetchMissingImagesAsync
{
    fetchMissingImagesThread = [[NSThread alloc] initWithTarget:self selector:@selector(fetchMissingImages) object:nil];
    [fetchMissingImagesThread start];
}

-(void)fetchMissingImages
{
    for (NSString *userID in _missingImages.keyEnumerator) {
        NSNumber *index = [_missingImages objectForKey: userID];
        if (index == nil || [NSThread currentThread].isCancelled) {
            return;
        }
        
        UIImage *temp = [cache objectForKey: userID];
        if (!temp) {
            [self fetchImageForUser: userID to: &temp];
        }
        
        if ([index intValue] == 0)
            leftImage = temp;
        else if ([index intValue] == 1)
            topRightImage = temp;
        else if ([index intValue] == 2)
            bottomRightImage = temp;
    }    
    self.image = [self mashup];
}

-(void)fetchImageForUser:(NSString *)userID to: (UIImage **)image
{
    if (!userID) {
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square", userID];
    NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString: url]];
    
    UIImage *newImage = [UIImage imageWithData:imageData];
    if (newImage == nil) {
        return;
    }
    
    //cache write operation has to be thread safe
    [cache_lock lock];
    [cache setObject:newImage forKey:userID];
    [cache_lock unlock];
    
    *image = newImage;
}

-(UIImage *)mashup {   
    CGSize size = self.frame.size;
    UIGraphicsBeginImageContext(size);
    
    //For seperator lines
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 1.0);
    
    if (_userIDs.count == 1) {
        [leftImage drawInRect: CGRectMake(0, 0, size.width, size.height)];
    } else {
        [leftImage drawInRect:CGRectMake(-size.width/4, 0, size.width, size.height)];
        CGContextMoveToPoint(context, size.width/2, 0);
        CGContextAddLineToPoint(context, size.width/2, size.height);
        
        if (_userIDs.count == 2)
            [topRightImage drawInRect: CGRectMake(size.width/2 + 1, 0, size.width, size.height)];
        else {
            [topRightImage drawInRect: CGRectMake(size.width/2 + 1, 0, size.width/2, size.height/2)];
            [bottomRightImage drawInRect: CGRectMake(size.width/2, size.height/2, size.width/2, size.height/2)];
            
            CGContextMoveToPoint(context, size.width/2, size.height/2);
            CGContextAddLineToPoint(context, size.width, size.height/2);
        }
    }
    CGContextStrokePath(context);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(void)resetImage
{
    [fetchMissingImagesThread cancel];
    _missingImages = nil;
    _userIDs = nil;
    leftImage = nil;
    topRightImage = nil;
    bottomRightImage = nil;
}

@end
