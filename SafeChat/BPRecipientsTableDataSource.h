//
//  BPRecipientsTableDataSource.h
//  FBEncryption
//
//  Created by Felix Leupold on 11/13/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BPFriend.h"

@interface BPRecipientsTableDataSource : NSObject <UITableViewDataSource> {
    NSString *_searchTerm;
    NSArray *suggestions;
}

@property NSString *searchTerm;

-(BPFriend *)friendForRowAtIndexPath: (NSIndexPath *)indexPath;
@end
