//
//  BPDetailViewController.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/21/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPDetailViewController.h"
#import "BPMessage.h"
#import "BPEncryptedObject.h"
#import "FCBaseChatRequestManager.h"
#import "BPFriend.h"

#define kOFFSET_FOR_KEYBOARD 220.0

@interface BPDetailViewController ()
- (void)configureView;
@end

@implementation BPDetailViewController
@synthesize messageView, lockImage, messageInput;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
        _detailItem.delegate = self;
        [self.detailItem checkEncryptionSupport];
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.

    if (self.detailItem) {
        self.messageView.text = @"";
        for (BPMessage *message in self.detailItem.messages)
        {
            [self  addMessageToView: message];
        }
    }
    self.lockImage.hidden = !self.encryptionEnabled;
    self.title = self.detailItem.participantsPreview;
    [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:.1];
}

-(void)scrollToBottom
{
    CGPoint bottomOffset = CGPointMake(0, [self.messageView contentSize].height - self.messageView.bounds.size.height);
    [self.messageView setContentOffset:bottomOffset animated:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    //register keyboard dismiss gesture
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(dismissKeyboard)];
    [self.messageView addGestureRecognizer:singleFingerTap];
}
 
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)sendMessage:(id)sender {
    [self.detailItem sendMessage: messageInput.text encrypted: self.encryptionEnabled];
    [self addMessageToView: self.detailItem.messages.lastObject];
    self.messageInput.text = @"";
    [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:.2];
}

-(void)addMessageToView: (BPMessage *)message
{
    NSString *newText = [NSString stringWithFormat: @"%@: %@\n\n", message.from.name, message.text];
    self.messageView.text = [self.messageView.text stringByAppendingString:newText];
}

-(void)encryptionSupportHasBeenCheckedAndIsAvailable:(BOOL)isAvailable
{
    self.encryptionEnabled = isAvailable;
    self.lockImage.hidden = !isAvailable;
}

-(void)dismissKeyboard
{
    [self.view endEditing:NO];
}

-(void)keyboardWillShow {
    //prepare for sending message
    [FCBaseChatRequestManager getInstance];
    
    // Animate the current view out of the way
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)keyboardWillHide {
    if (self.view.frame.origin.y >= 0)
    {
        [self setViewMovedUp:YES];
    }
    else if (self.view.frame.origin.y < 0)
    {
        [self setViewMovedUp:NO];
    }
}

-(void)setViewMovedUp:(BOOL)movedUp
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        // 1. move the view's origin up so that the text field that will be hidden come above the keyboard
        // 2. increase the size of the view so that the area behind the keyboard is covered up.
        rect.origin.y -= kOFFSET_FOR_KEYBOARD;
        rect.size.height += kOFFSET_FOR_KEYBOARD;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOFFSET_FOR_KEYBOARD;
        rect.size.height -= kOFFSET_FOR_KEYBOARD;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}
@end
