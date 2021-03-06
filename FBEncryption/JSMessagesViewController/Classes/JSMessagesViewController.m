//
//  Created by Jesse Squires
//  http://www.hexedbits.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSMessagesViewController
//
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//  http://opensource.org/licenses/MIT
//

#import "JSMessagesViewController.h"
#import "JSMessageTextView.h"

#import "NSString+JSMessagesView.h"
#import "UIColor+JSMessagesView.h"
#import "UIButton+JSMessagesView.h"

@interface JSMessagesViewController () <JSDismissiveTextViewDelegate>


@property (assign, nonatomic) CGFloat previousTextViewContentHeight;
@property (assign, nonatomic) BOOL isUserScrolling;

- (void)setup;

- (void)sendPressed:(UIButton *)sender;

- (BOOL)shouldHaveTimestampForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)shouldHaveAvatarForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)shouldHaveSubtitleForRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)shouldAllowScroll;

- (void)handleWillShowKeyboardNotification:(NSNotification *)notification;
- (void)handleWillHideKeyboardNotification:(NSNotification *)notification;
- (void)keyboardWillShowHide:(NSNotification *)notification;

- (UIViewAnimationOptions)animationOptionsForCurve:(UIViewAnimationCurve)curve;

@end



@implementation JSMessagesViewController

#pragma mark - Initialization

- (void)setup
{
    if([self.view isKindOfClass:[UIScrollView class]]) {
        // fix for ipad modal form presentations
        ((UIScrollView *)self.view).scrollEnabled = NO;
    }
    
	_isUserScrolling = NO;
    
    CGSize size = self.view.frame.size;
    
    CGRect tableFrame = CGRectMake(0.0f, 0.0f, size.width, size.height - [JSMessageInputView defaultHeight]);
	UITableView *tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	tableView.dataSource = self;
	tableView.delegate = self;
	[self.view addSubview:tableView];
	_tableView = tableView;
    
    [self setBackgroundColor:[UIColor js_messagesBackgroundColor_iOS6]];
    
    CGRect inputFrame = CGRectMake(0.0f,
                                   size.height - [JSMessageInputView defaultHeight],
                                   size.width,
                                   [JSMessageInputView defaultHeight]);
    
    JSMessageInputView *inputView = [[JSMessageInputView alloc] initWithFrame:inputFrame
                                                             textViewDelegate:self
                                                             keyboardDelegate:self
                                                         panGestureRecognizer:_tableView.panGestureRecognizer];
    
    UIButton *sendButton;
    if([self.delegate respondsToSelector:@selector(sendButtonForInputView)]) {
        sendButton = [self.delegate sendButtonForInputView];
    }
    else {
        //sendButton = [UIButton js_defaultSendButton_iOS6];
        sendButton = [UIButton buttonWithType: UIButtonTypeSystem];
        [sendButton setTitle:@"Send" forState:UIControlStateNormal];
        [sendButton setTitleColor: [UIColor grayColor] forState:UIControlStateDisabled];
        sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin);
        sendButton.titleLabel.textColor = [UIColor blueColor];
    }
    sendButton.enabled = NO;
    sendButton.frame = CGRectMake(inputView.frame.size.width - 65.0f, 8.0f, 59.0f, 30.0f);
    [sendButton addTarget:self
                   action:@selector(sendPressed:)
         forControlEvents:UIControlEventTouchUpInside];
    [inputView setSendButton:sendButton];
    
    [self.view addSubview:inputView];
    _messageInputView = inputView;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self scrollToBottomAnimated:NO];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillShowKeyboardNotification:)
												 name:UIKeyboardWillShowNotification
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleWillHideKeyboardNotification:)
												 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.messageInputView resignFirstResponder];
    [self setEditing:NO animated:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"*** %@: didReceiveMemoryWarning ***", self.class);
}

- (void)dealloc
{
    _delegate = nil;
    _dataSource = nil;
    _tableView = nil;
    _messageInputView = nil;
}

#pragma mark - View rotation

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableView reloadData];
    [self.tableView setNeedsLayout];
}

#pragma mark - Actions

- (void)sendPressed:(UIButton *)sender
{
    [self.delegate didSendText:[self.messageInputView.textView.text js_stringByTrimingWhitespace]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JSBubbleMessageType type = [self.delegate messageTypeForRowAtIndexPath:indexPath];
    
    UIImageView *bubbleImageView = [self.delegate bubbleImageViewWithType:type
                                                        forRowAtIndexPath:indexPath];
    
    BOOL hasTimestamp = [self shouldHaveTimestampForRowAtIndexPath:indexPath];
    BOOL hasAvatar = [self shouldHaveAvatarForRowAtIndexPath:indexPath];
	BOOL hasSubtitle = [self shouldHaveSubtitleForRowAtIndexPath:indexPath];
    
    NSString *CellIdentifier = [NSString stringWithFormat:@"MessageCell_%d_%d_%d_%d", type, hasTimestamp, hasAvatar, hasSubtitle];
    JSBubbleMessageCell *cell = (JSBubbleMessageCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(!cell) {
        cell = [[JSBubbleMessageCell alloc] initWithBubbleType:type
                                               bubbleImageView:bubbleImageView
                                                  hasTimestamp:hasTimestamp
                                                     hasAvatar:hasAvatar
                                                   hasSubtitle:hasSubtitle
                                               reuseIdentifier:CellIdentifier];
    }
    
    if(hasTimestamp) {
        [cell setTimestamp:[self.dataSource timestampForRowAtIndexPath:indexPath]];
    }
	
    if(hasAvatar) {
        
        [cell setAvatarImageView:[self.dataSource avatarImageViewForRowAtIndexPath:indexPath]];
    }
    
	if(hasSubtitle) {
		[cell setSubtitle:[self.dataSource subtitleForRowAtIndexPath:indexPath]];
    }
    
    [cell setMessage:[self.dataSource textForRowAtIndexPath:indexPath]];
    [cell setBackgroundColor:tableView.backgroundColor];
    
    if([self.delegate respondsToSelector:@selector(configureCell:atIndexPath:)]) {
        [self.delegate configureCell:cell atIndexPath:indexPath];
    }
    
    [cell prepareForReuse];
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [(JSBubbleMessageCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath] height];
}

#pragma mark - Messages view controller

- (BOOL)shouldHaveTimestampForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([self.delegate timestampPolicy]) {
        case JSMessagesViewTimestampPolicyAll:
            return YES;
            
        case JSMessagesViewTimestampPolicyAlternating:
            return indexPath.row % 2 == 0;
            
        case JSMessagesViewTimestampPolicyEveryThree:
            return indexPath.row % 3 == 0;
            
        case JSMessagesViewTimestampPolicyEveryFive:
            return indexPath.row % 5 == 0;
            
        case JSMessagesViewTimestampPolicyCustom:
            if([self.delegate respondsToSelector:@selector(hasTimestampForRowAtIndexPath:)])
                return [self.delegate hasTimestampForRowAtIndexPath:indexPath];
            
        default:
            return NO;
    }
}

- (BOOL)shouldHaveAvatarForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch ([self.delegate avatarPolicy]) {
        case JSMessagesViewAvatarPolicyAll:
            return YES;
            
        case JSMessagesViewAvatarPolicyIncomingOnly:
            return [self.delegate messageTypeForRowAtIndexPath:indexPath] == JSBubbleMessageTypeIncoming;
			
		case JSMessagesViewAvatarPolicyOutgoingOnly:
			return [self.delegate messageTypeForRowAtIndexPath:indexPath] == JSBubbleMessageTypeOutgoing;
            
        case JSMessagesViewAvatarPolicyCustom:
            if([self.delegate respondsToSelector:@selector(hasAvatarForRowAtIndexPath:)])
                return [self.delegate hasAvatarForRowAtIndexPath:indexPath];
        default:
            return NO;
    }
}

- (BOOL)shouldHaveSubtitleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([self.delegate subtitlePolicy]) {
        case JSMessagesViewSubtitlePolicyAll:
            return YES;
        
        case JSMessagesViewSubtitlePolicyIncomingOnly:
            return [self.delegate messageTypeForRowAtIndexPath:indexPath] == JSBubbleMessageTypeIncoming;
            
        case JSMessagesViewSubtitlePolicyOutgoingOnly:
            return [self.delegate messageTypeForRowAtIndexPath:indexPath] == JSBubbleMessageTypeOutgoing;
            
        case JSMessagesViewSubtitlePolicyNone:
        default:
            return NO;
    }
}

- (void)finishSend
{
    [self.messageInputView.textView setText:nil];
    [self textViewDidChange:self.messageInputView.textView];
    [_tableView reloadData];
}

-(void)reloadData
{
    [_tableView reloadData];
}

- (void)setBackgroundColor:(UIColor *)color
{
    self.view.backgroundColor = color;
    _tableView.backgroundColor = color;
    _tableView.separatorColor = color;
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
	if(![self shouldAllowScroll])
        return;
	
    NSInteger rows = [self.tableView numberOfRowsInSection:0];
    
    if(rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:animated];
    }
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath
			  atScrollPosition:(UITableViewScrollPosition)position
					  animated:(BOOL)animated
{
	if(![self shouldAllowScroll])
        return;
	
	[self.tableView scrollToRowAtIndexPath:indexPath
						  atScrollPosition:position
								  animated:animated];
}

- (BOOL)shouldAllowScroll
{
    if(self.isUserScrolling) {
        if([self.delegate respondsToSelector:@selector(shouldPreventScrollToBottomWhileUserScrolling)]
           && [self.delegate shouldPreventScrollToBottomWhileUserScrolling]) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Scroll view delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	self.isUserScrolling = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.isUserScrolling = NO;
    if(scrollView.contentOffset.y < 0 && [self.delegate respondsToSelector:@selector(loadMore)])
        [self.delegate loadMore];
}

#pragma mark - Text view delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [textView becomeFirstResponder];
	
    if(!self.previousTextViewContentHeight)
		self.previousTextViewContentHeight = textView.contentSize.height;
    
    [self scrollToBottomAnimated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat maxHeight = [JSMessageInputView maxHeight];
    
    //  TODO:
    //
    //  CGFloat textViewContentHeight = textView.contentSize.height;
    //
    //  The line above is broken as of iOS 7.0
    //
    //  There seems to be a bug in Apple's code for textView.contentSize
    //  The following code was implemented as a workaround for calculating the appropriate textViewContentHeight
    //
    //  https://devforums.apple.com/thread/192052
    //  https://github.com/jessesquires/MessagesTableViewController/issues/50
    //  https://github.com/jessesquires/MessagesTableViewController/issues/47
    //
    // BEGIN HACK
    //
        CGSize size = [textView sizeThatFits:CGSizeMake(textView.frame.size.width, maxHeight)];
        CGFloat textViewContentHeight = size.height;
    //
    //  END HACK
    //
    
    BOOL isShrinking = textViewContentHeight < self.previousTextViewContentHeight;
    CGFloat changeInHeight = textViewContentHeight - self.previousTextViewContentHeight;
    
    if(!isShrinking && self.previousTextViewContentHeight == maxHeight) {
        changeInHeight = 0;
    }
    else {
        changeInHeight = MIN(changeInHeight, maxHeight - self.previousTextViewContentHeight);
    }
    
    if(changeInHeight != 0.0f) {
        if(!isShrinking)
            [self.messageInputView adjustTextViewHeightBy:changeInHeight];
        
        [UIView animateWithDuration:0.25f
                         animations:^{
                             UIEdgeInsets insets = UIEdgeInsetsMake(0.0f,
                                                                    0.0f,
                                                                    self.tableView.contentInset.bottom + changeInHeight,
                                                                    0.0f);
                             
                             self.tableView.contentInset = insets;
                             self.tableView.scrollIndicatorInsets = insets;
                             [self scrollToBottomAnimated:NO];
                             
                             CGRect inputViewFrame = self.messageInputView.frame;
                             self.messageInputView.frame = CGRectMake(0.0f,
                                                                      inputViewFrame.origin.y - changeInHeight,
                                                                      inputViewFrame.size.width,
                                                                      inputViewFrame.size.height + changeInHeight);
                         }
                         completion:^(BOOL finished) {
                             if(isShrinking) {
                                 [self.messageInputView adjustTextViewHeightBy:changeInHeight];
                             }
                         }];
        
        self.previousTextViewContentHeight = MIN(textViewContentHeight, maxHeight);
    }
    
    self.messageInputView.sendButton.enabled = ([textView.text js_stringByTrimingWhitespace].length > 0);
}

#pragma mark - Keyboard notifications

- (void)handleWillShowKeyboardNotification:(NSNotification *)notification
{
    [self keyboardWillShowHide:notification];
}

- (void)handleWillHideKeyboardNotification:(NSNotification *)notification
{
    [self keyboardWillShowHide:notification];
}

- (void)keyboardWillShowHide:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration
                          delay:0.0f
                        options:[self animationOptionsForCurve:curve]
                     animations:^{
                         CGFloat keyboardY = [self.view convertRect:keyboardRect fromView:nil].origin.y;
                         
                         CGRect inputViewFrame = self.messageInputView.frame;
                         CGFloat inputViewFrameY = keyboardY - inputViewFrame.size.height;
                         
                         // for ipad modal form presentations
                         CGFloat messageViewFrameBottom = self.view.frame.size.height - [JSMessageInputView defaultHeight];
                         if(inputViewFrameY > messageViewFrameBottom)
                             inputViewFrameY = messageViewFrameBottom;
						 
                         self.messageInputView.frame = CGRectMake(inputViewFrame.origin.x,
																  inputViewFrameY,
																  inputViewFrame.size.width,
																  inputViewFrame.size.height);
                         
                         UIEdgeInsets insets = UIEdgeInsetsMake(0.0f,
                                                                0.0f,
                                                                self.view.frame.size.height - self.messageInputView.frame.origin.y - [JSMessageInputView defaultHeight],
                                                                0.0f);
                         
                         self.tableView.contentInset = insets;
                         self.tableView.scrollIndicatorInsets = insets;
                     }
                     completion:^(BOOL finished) {
                     }];
}

#pragma mark - Dismissive text view delegate

- (void)keyboardDidScrollToPoint:(CGPoint)point
{
    CGRect inputViewFrame = self.messageInputView.frame;
    CGPoint keyboardOrigin = [self.view convertPoint:point fromView:nil];
    inputViewFrame.origin.y = keyboardOrigin.y - inputViewFrame.size.height;
    self.messageInputView.frame = inputViewFrame;
}

- (void)keyboardWillBeDismissed
{
    CGRect inputViewFrame = self.messageInputView.frame;
    inputViewFrame.origin.y = self.view.bounds.size.height - inputViewFrame.size.height;
    self.messageInputView.frame = inputViewFrame;
}

- (void)keyboardWillSnapBackToPoint:(CGPoint)point
{
    CGRect inputViewFrame = self.messageInputView.frame;
    CGPoint keyboardOrigin = [self.view convertPoint:point fromView:nil];
    inputViewFrame.origin.y = keyboardOrigin.y - inputViewFrame.size.height;
    self.messageInputView.frame = inputViewFrame;
}

#pragma mark - Utilities

- (UIViewAnimationOptions)animationOptionsForCurve:(UIViewAnimationCurve)curve
{
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            return UIViewAnimationOptionCurveEaseInOut;
            
        case UIViewAnimationCurveEaseIn:
            return UIViewAnimationOptionCurveEaseIn;
            
        case UIViewAnimationCurveEaseOut:
            return UIViewAnimationOptionCurveEaseOut;
            
        case UIViewAnimationCurveLinear:
            return UIViewAnimationOptionCurveLinear;
            
        default:
            return kNilOptions;
    }
}

@end