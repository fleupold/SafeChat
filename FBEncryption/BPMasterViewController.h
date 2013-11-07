//
//  BPMasterViewController.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/21/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STableViewController.h"
#import "STHeaderView.h"

@interface BPMasterViewController : STableViewController {
    @protected
    
    NSString *nextPage;
}

@property IBOutlet STHeaderView *tableHeaderView;
@property IBOutlet UIView *tableFooterView;

@end
