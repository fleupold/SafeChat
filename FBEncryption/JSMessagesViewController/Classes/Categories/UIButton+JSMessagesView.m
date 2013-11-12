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

#import "UIButton+JSMessagesView.h"

@implementation UIButton (JSMessagesView)

+ (UIButton *)js_defaultSendButton_iOS6
{
    UIButton *sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin);
    
    UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 13.0f, 0.0f, 13.0f);
    UIImage *sendBack = [[UIImage imageNamed:@"send-button"] resizableImageWithCapInsets:insets];
    UIImage *sendBackHighLighted = [[UIImage imageNamed:@"send-button-pressed"] resizableImageWithCapInsets:insets];
    [sendButton setBackgroundImage:sendBack forState:UIControlStateNormal];
    [sendButton setBackgroundImage:sendBack forState:UIControlStateDisabled];
    [sendButton setBackgroundImage:sendBackHighLighted forState:UIControlStateHighlighted];
    
    NSString *title = NSLocalizedString(@"Send", nil);
    [sendButton setTitle:title forState:UIControlStateNormal];
    [sendButton setTitle:title forState:UIControlStateHighlighted];
    [sendButton setTitle:title forState:UIControlStateDisabled];
    sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    
    UIColor *titleShadow = [UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1.0f];
    [sendButton setTitleShadowColor:titleShadow forState:UIControlStateNormal];
    [sendButton setTitleShadowColor:titleShadow forState:UIControlStateHighlighted];
    sendButton.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
    
    [sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [sendButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:0.5f] forState:UIControlStateDisabled];
    
    return sendButton;
}

@end