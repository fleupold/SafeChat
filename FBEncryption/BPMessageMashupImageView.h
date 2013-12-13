//
//  BPMessageMashupImageView.h
//  SafeChat
//
//  Created by Felix Leupold on 11/7/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, BPMessageMashupStyle) {
    BPMessageMashupStyleCircle,
    BPMessageMashupStyleSqaure
};

@interface BPMessageMashupImageView : UIImageView {

    NSArray *_userIDs;
    UIImage *leftImage, *topRightImage, *bottomRightImage;
    NSDictionary *_missingImages;
    NSThread *fetchMissingImagesThread;
}

@property (nonatomic) NSString *userID;
@property BPMessageMashupStyle style;

-(id)initWithStyle: (BPMessageMashupStyle)aStyle;

-(void)setUserIDs: (NSArray *)userIDs;

@end
