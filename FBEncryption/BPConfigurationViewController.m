//
//  BPConfigurationViewController.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/23/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPConfigurationViewController.h"

@interface BPConfigurationViewController ()

@end

@implementation BPConfigurationViewController
@synthesize passphraseField, loadingView, spinner;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)generateKeyPair:(id)sender
{
    loadingView.hidden = NO;
    [spinner startAnimating];
    self.navigationItem.hidesBackButton = YES;
    
    BPJavascriptRuntime *jsRuntime = [BPJavascriptRuntime getInstance];
    jsRuntime.delegate = self;
    [jsRuntime triggerKeyGenerationWithPassphrase: self.passphraseField.text];
}

-(void)keyPairGeneratedWithPublicKey:(NSString *)publicKey
{
    //Unload spinner
    self.navigationItem.hidesBackButton = NO;
    [spinner stopAnimating];
    loadingView.hidden = YES;
    
    //Replace passphrase Field with public Key with
    passphraseField.text = publicKey;
}


@end
