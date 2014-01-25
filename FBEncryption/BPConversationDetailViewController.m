    //
//  BPDetailViewController.m
//  SafeChat
//
//  Created by Felix Leupold on 10/21/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPConversationDetailViewController.h"
#import "BPMessage.h"
#import "BPEncryptedObject.h"
#import "FCBaseChatRequestManager.h"
#import "BPFriend.h"
#import "BPMessageMashupImageView.h"
#import "BPFacebookDateFormatter.h"
#import "BPFqlThread.h"

#import "IonIcons.h"

@interface BPConversationDetailViewController ()
- (void)configureView;
@end

@implementation BPConversationDetailViewController
@synthesize lockImage;

NSTimeInterval const secondsBetweenNewTimestamps = 60 * 60;
NSTimeInterval const secondsForTypingIndicator = 10;

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
    self.view.backgroundColor = [UIColor whiteColor];
    self.lockImage.hidden = !self.encryptionEnabled;
    self.title = self.detailItem.participantsPreview;
    [self setBackgroundColor: [UIColor whiteColor]];
    
    //Activity Indicator to load older messanges
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(0, -30, 30, 30);
    [self.tableView addSubview: spinner];
    self.spinner = spinner;
    
    //no support for group chats yet
    if (self.detailItem.participants.count > 2) {
        self.messageInputView.userInteractionEnabled = NO;
        self.messageInputView.alpha = .3;
    }
    
}

- (void)viewDidLoad
{
    self.dataSource = self;
    self.delegate = self;
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    //Register for FBChatRequestManager Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMessage:) name:@"didReceiveMessage" object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToSendMessage:) name:@"didFailToSendMessage" object: nil];
    
    //connect with Chat service so that we can receive incoming messages
    [self.detailItem prepareForSending];
}

-(void)viewDidAppear:(BOOL)animated{
    if (!((BPFqlThread *)self.detailItem).hasLoadedMessages)
        [self.detailItem loadMore];
}
 
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BPMessage *)messageForRowAtIndexPath: (NSIndexPath *)indexPath
{
    if (indexPath.row == self.detailItem.messages.count) {
        BPMessage *placeholder = [BPMessage messageFromText: @"typing..."];
        placeholder.created = lastTyping;
        placeholder.from = personTyping;
        return placeholder;
    }
    return [self.detailItem.messages objectAtIndex: indexPath.row];
}

-(void)didReceiveMessage:(NSNotification *)notification {
    XMPPMessage *message = notification.object;
    NSString *senderID = [message.fromStr componentsSeparatedByString:@"@"].firstObject; //still has the minus as first character
    senderID = [senderID substringFromIndex:1];
    
    BPFriend *sender = [BPFriend findOrCreateFriendWithId: senderID andName: nil];
    
    if (self.detailItem.isGroupChat || ![self.detailItem.participants containsObject: sender]) {
        return;
    }
    
    if ([message.compactXMLString rangeOfString: @"composing"].location != NSNotFound)
    {
        [self startTypingBy: sender];
    }
    
    if (message.body) {
        [self stopTyping];
        [self.detailItem addIncomingMessage:message.body from:sender];
        [self.tableView reloadData];
        [self scrollToBottomAnimated: YES];
    }
}

-(void)didFailToSendMessage: (NSNotification *)notification
{
    XMPPMessage *xmppMessage = notification.object;
    
    for (BPMessage *message in self.detailItem.messages.reverseObjectEnumerator) {
        if([message.text isEqualToString: xmppMessage.body]) {
            message.failedToSend = YES;
            break;
        }
    }
}


-(BOOL)isTyping
{
    return lastTyping != nil && [lastTyping timeIntervalSinceNow] > -1 * secondsForTypingIndicator;
}

#pragma mark - BPThreadDelegate methods

-(void)encryptionSupportHasBeenCheckedAndIsAvailable:(BOOL)isAvailable
{
    self.encryptionAvailable = isAvailable;
    self.encryptionEnabled = isAvailable;
    [self configureLockButton];
}

-(void)hasUpdatedThread:(BPThread *)thread scrollToRow:(NSInteger)row
{
    [self reloadData];
    [self.spinner stopAnimating];
    isReloading = NO;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:0];
    [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated: NO];
}

-(void)startTypingBy:(BPFriend *)typer
{
    lastTyping = [NSDate date];
    personTyping = typer;
    [self reloadData];
    [self scrollToBottomAnimated:YES];
    [self performSelector:@selector(reloadData) withObject:nil afterDelay: secondsForTypingIndicator]; //hide typing indicator
}

-(void)stopTyping
{
    lastTyping = nil;
}

#pragma mark - Messages view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([self isTyping])
        return self.detailItem.messages.count + 1; //space for typing indicator
    
    return self.detailItem.messages.count;
}

- (NSString *)textForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self messageForRowAtIndexPath:indexPath].text;
}


- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self messageForRowAtIndexPath:indexPath].created;
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath {
    BPFriend *sender = [self messageForRowAtIndexPath:indexPath].from;

    if ([sender isMe]) {
        BPMessage *message = [self messageForRowAtIndexPath:indexPath];
        if(message.failedToSend) {
            UIImage *alert = [IonIcons imageWithIcon:icon_alert_circled iconColor:[UIColor grayColor] iconSize:20 imageSize: CGSizeMake(40, 40)];
            return [[UIImageView alloc] initWithImage:alert];
        } else if(message.encrypted) {
            UIImage *lock = [IonIcons imageWithIcon:icon_locked iconColor:[UIColor grayColor] iconSize:20 imageSize: CGSizeMake(40, 40)];
            return [[UIImageView alloc] initWithImage:lock];
        }
        return nil;
    
    } else {
        BPMessageMashupImageView *avatar = [[BPMessageMashupImageView alloc] initWithFrame: CGRectMake(0, 0, 40, 40)];
        avatar.userID = sender.id;
        return avatar;
    }
}

- (NSString *)subtitleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self messageForRowAtIndexPath:indexPath].from.name;
}


#pragma mark - Messages view delegate

- (void)didSendText:(NSString *)text {
    [self.detailItem sendMessage: text encrypted: self.encryptionEnabled];
    [self finishSend];
    [self scrollToBottomAnimated: YES];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[self messageForRowAtIndexPath:indexPath].from isMe])
    {
        return JSBubbleMessageTypeOutgoing;
    }
    return JSBubbleMessageTypeIncoming;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    if ([self messageForRowAtIndexPath: indexPath].text == nil && [self isTyping]) {
        return [JSBubbleImageViewFactory  bubbleImageViewForType: JSBubbleMessageTypeOutgoing style:JSBubbleImageViewStyleTyping];
    }*/
    
    if (type == JSBubbleMessageTypeOutgoing) {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                          style:JSBubbleImageViewStyleClassicSquareBlue];
    }
    return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                      style:JSBubbleImageViewStyleClassicSquareGray];
}

- (JSMessagesViewTimestampPolicy)timestampPolicy {
    return JSMessagesViewTimestampPolicyCustom;
}

- (JSMessagesViewAvatarPolicy)avatarPolicy {
    return JSMessagesViewAvatarPolicyCustom;
}

- (JSMessagesViewSubtitlePolicy)subtitlePolicy {
    if(self.detailItem.participants.count < 3) {
        return JSMessagesViewSubtitlePolicyNone;
    }
    return JSMessagesViewSubtitlePolicyIncomingOnly;
}

- (BOOL)hasTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 0) {
        return YES;
    }
    
    NSIndexPath *lastMessagePath = [NSIndexPath indexPathForRow: indexPath.row - 1 inSection:indexPath.section];
    BPMessage *thisMessage = [self messageForRowAtIndexPath: indexPath];
    BPMessage *lastMessage = [self messageForRowAtIndexPath: lastMessagePath];
    
    return ([thisMessage.created timeIntervalSinceDate: lastMessage.created] > secondsBetweenNewTimestamps);
}

-(BOOL)hasAvatarForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self messageTypeForRowAtIndexPath: indexPath] == JSBubbleMessageTypeIncoming)
        return YES;
    
    BPMessage *message = [self messageForRowAtIndexPath:indexPath];
    return message.failedToSend || message.encrypted;
}

- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if ([[self messageForRowAtIndexPath: indexPath].text isEqualToString:@"typing..."]) {
        cell.bubbleView.font = [UIFont italicSystemFontOfSize: 16];
    }
    
    if(cell.messageType == JSBubbleMessageTypeOutgoing) {
        cell.bubbleView.textColor = [UIColor whiteColor];
    }
    
    BPMessage *message = [self messageForRowAtIndexPath: indexPath];
    if ([message.from isMe] && !message.synced) {
        cell.bubbleView.alpha = 0.6;
    }
}

- (void)loadMore {
    if (!self.detailItem || isReloading){
        return;
    }
    [self showSpinner];
    isReloading = YES;
    
    [self.detailItem loadMore];
}


-(void)showSpinner {
    self.spinner.frame = CGRectMake(self.tableView.frame.size.width/2 - 15, -30, 30, 30);
    [self.spinner startAnimating];
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.tableView.contentInset = UIEdgeInsetsMake(self.spinner.frame.size.height, 0, 0, 0);
    }];
}

-(void)hideSpinner {
    [self.spinner stopAnimating];
    self.tableView.contentInset = UIEdgeInsetsZero;
}

-(void)configureLockButton {
    
    UIButton *lock = [UIButton buttonWithType:UIButtonTypeContactAdd];
    lock.frame = CGRectMake(3, 11, 25, 25);

    UIImage *lockIcon;

    
    if (!self.encryptionAvailable) {
        lockIcon = [self encryptionNotSupportedImage];
    }
    else if (self.encryptionEnabled) {
        lockIcon = [self lockedImage];
    }
    else {
        lockIcon = [self unlockedImage];
    }
    
    [lock setImage: lockIcon forState:UIControlStateNormal];
    [lock addTarget:self action:@selector(toggleEncryption:) forControlEvents:UIControlEventTouchDown];
    [self.messageInputView addSubview: lock];
}

-(void)toggleEncryption: (UIButton *)sender
{
    if (!self.encryptionAvailable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Encryption not available"
                                                        message:@"Tell your friend!"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Ok",nil];
        alert.delegate = self;
        [alert show];
        return;
    }
    if(self.encryptionEnabled) {
        self.encryptionEnabled = NO;
        [sender setImage: [self unlockedImage] forState:UIControlStateNormal];
    } else {
        self.encryptionEnabled = YES;
        [sender setImage: [self lockedImage] forState:UIControlStateNormal];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 1)
        return;
    
    [self.messageInputView.textView becomeFirstResponder];
    self.messageInputView.textView.text = [self.messageInputView.textView.text stringByAppendingString: @"SafeChat.IM Encrypted Facebook Messenger\nwww.safechat.im"];
    self.messageInputView.sendButton.enabled = YES;
    [self textViewDidChange: self.messageInputView.textView];
}

-(UIImage *)lockedImage
{
    return [IonIcons imageWithIcon:icon_locked iconColor:[UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1] iconSize:20 imageSize:CGSizeMake(20, 20)];
}

-(UIImage *)unlockedImage
{
    return [IonIcons imageWithIcon:icon_unlocked iconColor:[UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1] iconSize:20 imageSize:CGSizeMake(20, 20)];
}

-(UIImage *)encryptionNotSupportedImage
{
    return [IonIcons imageWithIcon:icon_alert_circled iconColor:[UIColor colorWithRed:0 green:0.478431 blue:1 alpha:1] iconSize:20 imageSize:CGSizeMake(20, 20)];
}

@end
