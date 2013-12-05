//
//  BPMasterViewController.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/21/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPConversationMasterViewController.h"
#import "BPConversationDetailViewController.h"
#import "BPFacebookLoginViewController.h"
#import "BPFriend.h"
#import "BPInboxThread.h"
#import "BPFqlThread.h"
#import "BPFqlRequestManager.h"
#import "BPFacebookDateFormatter.h"
#import "BPMessageTableViewCell.h"
#import <FacebookSDK/FacebookSDK.h>
#import "IonIcons.h"

@interface BPConversationMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation BPConversationMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    //Make a plain white view if there are no messages yet
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    //iconize view
    UIImage *icon = [IonIcons imageWithIcon:icon_ios7_gear
                                  iconColor:[UIColor grayColor]
                                   iconSize:32
                                  imageSize:CGSizeMake(32, 32)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithImage:icon
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(configButtonWasPressed:)];
    
    icon = [IonIcons imageWithIcon:icon_ios7_compose_outline
                        iconColor:[UIColor grayColor]
                         iconSize:32
                        imageSize:CGSizeMake(32, 32)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithImage:icon
                                             style:UIBarButtonItemStylePlain
                                             target:self
                                             action:@selector(composeButtonWasPressed:)];

    //Somehow the views from to superclass cannot be connected in the storyboard file, use own
    self.headerView = self.tableHeaderView;
    self.footerView = self.tableFooterView;
    self.footerView.hidden = YES;
    self.tableHeaderView.title.font = [IonIcons fontWithSize:15];
    
    [self checkEncryptionConfigured];
    
    [self performSelector:@selector(fetchThreads) withObject:nil afterDelay:0.5];
}

-(void)checkEncryptionConfigured
{
    if([BPFriend meHasEncryptionConfigured]) {
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"No Private Key"
                                                    message: @"Do you want to set up encryption now?"
                                                   delegate: self
                                          cancelButtonTitle: @"Yes"
                                          otherButtonTitles:@"No", nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0)
        [self performSegueWithIdentifier: @"load_configuration"  sender: alertView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BPMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageCell" forIndexPath:indexPath];
   
    BPThread *object = _objects[indexPath.row];
    cell.participantsLabel.text = [object participantsPreview];
    cell.previewLabel.text = [object textPreview];
    cell.timeLabel.text = [BPFacebookDateFormatter prettyPrint: object.updated_at];
    
    
    //Mashup Image
    NSMutableArray *userIDs = [NSMutableArray array];
    for (BPFriend *user in object.participants) {
        if (userIDs.count > 2)
            break;
        if([user isMe])
            continue;
        [userIDs addObject: user.id];
    }
    BPMessageMashupImageView *newMashup = [[BPMessageMashupImageView alloc] initWithFrame: cell.messageImage.frame];
    [newMashup setUserIDs: userIDs];
    [cell.messageImageContainer addSubview: newMashup];
    [cell.messageImage removeFromSuperview];
    cell.messageImage = newMashup;
    
    
    if (object.unread > 0) {
        cell.timeLabel.textColor = self.view.window.tintColor;
        cell.previewLabel.textColor = [UIColor blackColor];
        cell.previewLabel.font = [UIFont boldSystemFontOfSize:13];
        cell.participantsLabel.font = [UIFont boldSystemFontOfSize:14];
    } else {
        cell.timeLabel.textColor = [UIColor darkGrayColor];
        cell.previewLabel.textColor = [UIColor darkGrayColor];
        cell.previewLabel.font = [UIFont systemFontOfSize:13];
        cell.participantsLabel.font = [UIFont systemFontOfSize:14];
    }
        
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/
- (void) viewDidAppear:(BOOL) animated {
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(resizeHeaderAndFooter)  name:UIDeviceOrientationDidChangeNotification  object:nil];
    [self resizeHeaderAndFooter];
    [self fetchThreads];
    
    [super viewDidAppear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        BPFqlThread *object = _objects[indexPath.row];
        
        BPConversationDetailViewController *destination = ((BPConversationDetailViewController *)[segue destinationViewController]);
        if(destination.detailItem == nil)
            [destination setDetailItem:object];
    }
}

-(void)configButtonWasPressed:(id)sender
{
    [self performSegueWithIdentifier:@"load_configuration" sender:sender];
}

-(void)composeButtonWasPressed:(id)sender
{
    [self performSegueWithIdentifier:@"composeMessage" sender:sender];
}

-(void)fetchThreads
{
    [self fetchThreads: NO];
}

-(void)fetchThreads: (BOOL)loadingMore
{
    /*
     * Asynchronously fetch all thread_ids, snippets, etc using FQL
     * Fql only gives us the participants ids, no username etc.
     * Therefore there has to be another intermediate asyn call to the friends API
     *
     * Is either called to load older messages or the most recent ones, which is indicated
     * by the boolean parameter
    */
    
    NSDate *threadsBefore = [NSDate date];
    if (loadingMore) {
        threadsBefore = ((BPThread *)[_objects lastObject]).updated_at;
    }
    
    [BPFqlRequestManager requestThreadsBefore: threadsBefore
                               withCompletion:
     ^(NSDictionary *response) {
         FBGraphObject *threadInformation;
         
         //First get information about involved friends, on completion continue initializing the threads
         NSMutableSet *userIDs = [NSMutableSet set];
         for (threadInformation in [response objectForKey:@"data"])
         {
             NSArray *recipients = [threadInformation objectForKey:@"recipients"];
             [userIDs unionSet: [NSSet setWithArray: recipients]];
         }
         [BPFqlRequestManager createUsersWithIDs: userIDs
                                      completion:
          ^{
              if (!loadingMore)
                  _objects = [NSMutableArray array];
              
              for (threadInformation in [response objectForKey:@"data"])
              {
                  BPThread *thread = [BPFqlThread threadFromFBGraphObject: threadInformation];
                  [_objects addObject: thread];
              }
              //adjustments that are necessary after first loading
              self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
              self.footerView.hidden = NO;
              
              [self.tableView reloadData];

              if (loadingMore)
              {
                  [self loadMoreCompleted];
              } else {
                  [self refreshCompleted];
              }

          } failure:
          ^(NSError *error) {
              NSLog(@"%@", error);
          }];
     }
                                      failure:
     ^(NSError *error) {
          NSLog(@"%@", error);
      }];
    
    /*
    //Trigger the Facebook REST API call to get a list of all message threads
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForGraphPath: @"me/inbox"] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary<FBGraphUser> *inbox,
           NSError *error) {
             if (!error) {
                 _objects = [NSMutableArray array];
                 for (FBGraphObject *threadInformation in [inbox objectForKey:@"data"])
                 {
                     BPThread *thread = [BPInboxThread threadFromFBGraphObject: threadInformation];
                     [_objects addObject: thread];
                 }
                 [self setNextPage: [[inbox objectForKey:@"paging"] objectForKey: @"next"]];
                 
                 //adjustments that are necessary after first loading
                 self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
                 self.footerView.hidden = NO;
                 
                 [self.tableView reloadData];
                 [self refreshCompleted];
             }
             else {
                 NSLog(@"%@", error);
             }
         }];
    }
    NSLog(@"%@", [FBSession activeSession].accessTokenData);
    */
}

-(void)setNextPage: (NSString *)page
{
    NSURL *nextPageURL = [NSURL URLWithString: page];
    nextPage = [NSString stringWithFormat:@"%@?%@", nextPageURL.relativePath, nextPageURL.query];
}

-(void)encryptionSupportHasBeenCheckedAndIsAvailable:(BOOL)isAvailable {
    if (isAvailable) {
        [self.tableView reloadData];
    }
}

# pragma mark - STTabelViewController methods
- (BOOL) refresh
{
    [super refresh];
    [self fetchThreads];
    return YES;
}

- (BOOL) loadMore
{
    if (![super loadMore])
        return NO;
    
    if (!FBSession.activeSession.isOpen)
        return NO;
    
    [self fetchThreads: YES];
    
    /*
    if (!nextPage)
        return NO;
    [[FBRequest requestForGraphPath: nextPage] startWithCompletionHandler:
     ^(FBRequestConnection *connection,
       NSDictionary<FBGraphUser> *inbox,
       NSError *error) {
         if (!error) {
             for (FBGraphObject *threadInformation in [inbox objectForKey:@"data"])
             {
                 BPThread *thread = [BPInboxThread threadFromFBGraphObject: threadInformation];
                 [_objects addObject: thread];
             }
             [self setNextPage: [[inbox objectForKey:@"paging"] objectForKey: @"next"]];
             
             [self.tableView reloadData];
             [self loadMoreCompleted];
         }
         else {
             NSLog(@"%@", error);
         }
     }]; 
     */
    return YES;
}

-(void)pinHeaderView
{
    [super pinHeaderView];
    self.tableHeaderView.loadingView.hidden = NO;
}
-(void)unpinHeaderView
{
    [super unpinHeaderView];
    self.tableHeaderView.loadingView.hidden = YES;
}
- (void) headerViewDidScroll:(BOOL)willRefreshOnRelease scrollView:(UIScrollView *)scrollView
{
    STHeaderView *hv = (STHeaderView *)self.headerView;
    if (willRefreshOnRelease)
        hv.title.text = [NSString stringWithFormat: @"%@ Release to refresh...", icon_arrow_up_a];
    else
        hv.title.text = [NSString stringWithFormat: @"%@Pull down to refresh...", icon_arrow_down_a];
}

- (void)resizeHeaderAndFooter {
    self.headerView.frame = CGRectMake(self.headerView.frame.origin.x,
                                       self.headerView.frame.origin.y,
                                       self.view.frame.size.width,
                                       self.headerView.frame.size.height);

    self.footerView.frame = CGRectMake(self.footerView.frame.origin.x,
                                       self.footerView.frame.origin.y,
                                       self.view.frame.size.width,
                                       self.footerView.frame.size.height);
    
}

@end
