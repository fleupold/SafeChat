//
//  BPComposeViewController.m
//  SafeChat
//
//  Created by Felix Leupold on 11/13/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPComposeViewController.h"
#import "BPRecipientSuggestionTableViewCell.h"
#import "BPFqlRequestManager.h"
#import "BPFqlThread.h"

@interface BPComposeViewController ()

@end

@implementation BPComposeViewController

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
    
    self.title = @"New Message";
    self.tableView.hidden = YES;
    
    self.recipientTextField.delegate = self;
    [self.recipientTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.recipientTextField becomeFirstResponder];
    
    //Setup the table view that displays potential recipients
    recipientTableViewDataSource = [[BPRecipientsTableDataSource alloc] init];
    self.recipientTableView.dataSource = recipientTableViewDataSource;
    self.recipientTableView.delegate = self;
    self.recipientTableView.hidden = YES;
    
    //bottom border below input field
    UIView *container = self.recipientTextField.superview;
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.borderColor = [UIColor grayColor].CGColor;
    bottomBorder.borderWidth = .5;
    bottomBorder.frame = CGRectMake(-.5, CGRectGetHeight(container.frame) - .5, CGRectGetHeight(self.view.frame) + 1, .5);
    [container.layer addSublayer: bottomBorder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)loadThreadForUser:(BPFriend *)user
{
    [BPFqlRequestManager requestThreadIdForUser:user.id completion:^(NSDictionary *thread) {
        if (thread) {
            self.detailItem = [BPFqlThread threadFromFBGraphObject: (FBGraphObject *)thread];
            [self.detailItem loadMore];
        } else {
            self.detailItem = [BPFqlThread emptyThreadWith: user];
        }
        [self.detailItem prepareForSending];
    } failure:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}

#pragma mark - UITextFieldDelegate Methods

-(void)textFieldDidChange:(UITextField *)textField {
    recipientTableViewDataSource.searchTerm = textField.text;
    self.recipientTableView.dataSource = recipientTableViewDataSource;
    self.recipientTableView.hidden = NO;
    [self.recipientTableView reloadData];
    
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView == self.recipientTableView) {
        return 40;
    } else {
        return [super tableView: tableView heightForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BPFriend *user = [recipientTableViewDataSource friendForRowAtIndexPath: indexPath];
    [self loadThreadForUser: user];
    
    //make view look like a BPComposeViewController
    self.title = user.name;
    [self.recipientTableView removeFromSuperview];
    self.recipientTextField.superview.hidden = YES;
    self.tableView.hidden = NO;
    
    //User wants to type the message right away
    [self.messageInputView.textView becomeFirstResponder];
    
}




@end
