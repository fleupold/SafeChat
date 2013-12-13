//
//  BPMessageTableViewCell.h
//  SafeChat
//
//  Created by Felix Leupold on 11/7/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BPMessageMashupImageView.h"
@interface BPMessageTableViewCell : UITableViewCell

@property IBOutlet BPMessageMashupImageView *messageImage;
@property IBOutlet UIView *messageImageContainer;
@property IBOutlet UILabel *previewLabel, *participantsLabel, *timeLabel, *unreadLabel;

@end
