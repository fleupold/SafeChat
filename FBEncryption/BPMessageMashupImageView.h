//
//  BPMessageMashupImageView.h
//  FBEncryption
//
//  Created by Felix Leupold on 11/7/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, BPMessageMashupStyle) {
    BPMessageMashupStyleSqaure,
    BPMessageMashupStyleCircle
};

@interface BPMessageMashupImageView : UIImageView {
    BPMessageMashupStyle style;
    NSString *_userID;
}

@property (nonatomic) NSString *userID;

-(id)initWithStyle: (BPMessageMashupStyle)aStyle;

@end
