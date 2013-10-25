//
//  BPFacebookLoginViewController.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BPFacebookLoginViewController : UIViewController

@property (weak) IBOutlet UIActivityIndicatorView *spinner;

- (IBAction)performLogin:(id)sender;
- (void)loginFailed;

@end
