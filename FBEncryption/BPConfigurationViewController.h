//
//  BPConfigurationViewController.h
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BPJavascriptRuntime.h"

@interface BPConfigurationViewController : UIViewController <BPJavascriptRuntimeDelegate>

@property IBOutlet UITextField *passphraseField;
@property IBOutlet UIView *loadingView;
@property IBOutlet UIActivityIndicatorView *spinner;

-(IBAction)generateKeyPair:(id)sender;

@end
