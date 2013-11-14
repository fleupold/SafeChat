//
//  BPDetailViewController.m
//  FBEncryption
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
    
    //Register for message receive notifications
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(receivedMessage:) name: @"kFCMessageDidComeNotification" object: nil];
    
    //connect with Chat service so that we can receive incoming messages
    [self.detailItem prepareForSending];
}

-(void)viewDidAppear:(BOOL)animated{
    [self.detailItem update];
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

-(void)receivedMessage:(NSNotification *)notification
{
    XMPPMessage *message = notification.object;
    NSString *senderID = [message.fromStr componentsSeparatedByString:@"@"].firstObject; //still has the minus as first character
    senderID = [senderID substringFromIndex:1];
    
    BPFriend *sender = [BPFriend findOrCreateFriendWithId: senderID andName: nil];
    
    if (![self.detailItem.participants containsObject: sender]) {
        return;
    }
    
    if ([message.compactXMLString rangeOfString: @"composing"].location != NSNotFound)
    {
        lastTyping = [NSDate date];
        personTyping = sender;
        [self reloadData];
        [self scrollToBottomAnimated:YES];
        [self performSelector:@selector(reloadData) withObject:nil afterDelay: secondsForTypingIndicator]; //hide typing indicator
    }
    
    if (message.body) {
        lastTyping = nil;
        [self.detailItem addIncomingMessage:message.body from:sender];
        [self reloadData];
        [self scrollToBottomAnimated:YES];
    }
}

-(BOOL)isTyping
{
    return lastTyping != nil && [lastTyping timeIntervalSinceNow] > -1 * secondsForTypingIndicator;
}

#pragma mark - BPThreadDelegate methods

-(void)encryptionSupportHasBeenCheckedAndIsAvailable:(BOOL)isAvailable
{
    self.encryptionEnabled = isAvailable;
    self.lockImage.hidden = !isAvailable;
}

-(void)hasUpdatedThread:(BPThread *)thread
{
    [self reloadData];
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
            UIImage *alert = [IonIcons imageWithIcon:icon_alert_circled iconColor:[UIColor grayColor] iconSize:20 imageSize: CGSizeMake(20, 40)];
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
}

- (void)loadMore {
    if (!self.detailItem || !self.detailItem.nextPage || isReloading){
        return;
    }
    [self showSpinner];
    isReloading = YES;
    
    
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForGraphPath: self.detailItem.nextPage] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           FBGraphObject *thread,
           NSError *error) {
             if (!error) {
                 [self extendDetailItemWith:thread];
             }
             else {
                 NSLog(@"%@", error);
             }
             isReloading = NO;
             [self hideSpinner];
         }];
    }
}

-(void)extendDetailItemWith: (FBGraphObject *)thread {
    NSArray *messages = [thread objectForKey:@"data"];
    for (FBGraphObject *messageInformation in messages)
    {
        BPMessage *message = [BPMessage messageFromFBGraphObject: messageInformation];
        [self.detailItem.messages insertObject: message atIndex: 0];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: messages.count - 2 inSection:0];

    self.detailItem.nextPage = [[thread objectForKey:@"paging"] objectForKey: @"next"];
    [self reloadData];
    
    [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
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

@end