//
//  BPRecipientSuggestionTableViewCell.h
//  FBEncryption
//
//  Created by Felix Leupold on 11/13/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BPMessageMashupImageView.h"

@interface BPRecipientSuggestionTableViewCell : UITableViewCell

@property IBOutlet BPMessageMashupImageView *icon;
@property IBOutlet UILabel *name;

@end
