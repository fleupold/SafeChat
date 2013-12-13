//
//  BPComposeViewController.h
//  SafeChat
//
//  Created by Felix Leupold on 11/13/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPConversationDetailViewController.h"
#import "BPRecipientsTableDataSource.h"

@interface BPComposeViewController : BPConversationDetailViewController <UITextFieldDelegate> {
    BPRecipientsTableDataSource *recipientTableViewDataSource;
}

@property IBOutlet UITextField *recipientTextField;
@property IBOutlet UITableView *recipientTableView;
@end
