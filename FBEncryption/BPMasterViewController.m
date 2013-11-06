//
//  BPMasterViewController.m
//  FBEncryption
//
//  Created by Felix Leupold on 10/21/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPMasterViewController.h"
#import "BPDetailViewController.h"
#import "BPFacebookLoginViewController.h"
#import "BPThread.h"
#import <FacebookSDK/FacebookSDK.h>
#import "IonIcons.h"

@interface BPMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation BPMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *icon = [IonIcons imageWithIcon:icon_ios7_gear
                                  iconColor:[UIColor grayColor]
                                   iconSize:32
                                  imageSize:CGSizeMake(32, 32)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithImage:icon
                                              style:UIBarButtonItemStylePlain
                                              target:self
                                              action:@selector(configButtonWasPressed:)];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    BPThread *object = _objects[indexPath.row];
    cell.textLabel.text = [object participantsPreview];
    cell.detailTextLabel.text = [object textPreview];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
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
    [self fetchThreads];
    [super viewDidAppear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        BPThread *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}

-(void)configButtonWasPressed:(id)sender
{
    [self performSegueWithIdentifier:@"load_configuration" sender:sender];
}

-(void)fetchThreads
{
    //Trigger the Facebook REST API call to get a list of all message threads
    if (FBSession.activeSession.isOpen) {
        [[FBRequest requestForGraphPath: @"me/threads"] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary<FBGraphUser> *inbox,
           NSError *error) {
             if (!error) {
                 _objects = [NSMutableArray array];
                 for (FBGraphObject *threadInformation in [inbox objectForKey:@"data"])
                 {
                     BPThread *thread = [BPThread threadFromFBGraphObject: threadInformation];
                     [_objects addObject: thread];
                 }
                 [self.tableView reloadData];
             }
             else {
                 NSLog(@"%@", error);
             }
         }];
    }
    NSLog(@"%@", [FBSession activeSession].accessTokenData);
}

- (BOOL) refresh
{
    [self fetchThreads];
    return YES;
}

@end
