//
//  BPRecipientsTableDataSource.m
//  SafeChat
//
//  Created by Felix Leupold on 11/13/13.
//  Copyright (c) 2013 Felix Leupold. All rights reserved.
//

#import "BPRecipientsTableDataSource.h"
#import "BPRecipientSuggestionTableViewCell.h"

@implementation BPRecipientsTableDataSource

-(NSString *)searchTerm
{
    return _searchTerm;
}

-(void)setSearchTerm:(NSString *)aSearchTerm
{
    if (_searchTerm.length > aSearchTerm.length || !suggestions) {
        suggestions = [BPFriend allFriends];
    }
    _searchTerm = aSearchTerm;
    [self filter];
}

-(void)filter{
    if(self.searchTerm.length == 0) {
        return;
    }
    
    NSMutableArray *filteredCandidates = [NSMutableArray array];
    for (BPFriend *candidate in suggestions) {
        if ([candidate.name.lowercaseString rangeOfString: self.searchTerm.lowercaseString].location != NSNotFound) {
            [filteredCandidates addObject: candidate];
        }
    }
    suggestions = filteredCandidates;
}

-(BPFriend *)friendForRowAtIndexPath: (NSIndexPath *)indexPath
{
    return [suggestions objectAtIndex:indexPath.row];
}

#pragma mark - UITableViewDataSource methods

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!suggestions) {
        return 0;
    }
    return suggestions.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BPRecipientSuggestionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"recipientSuggestionCell"];
    BPFriend *suggestion = [self friendForRowAtIndexPath: indexPath];
    cell.name.text = suggestion.name;
    
    BPMessageMashupImageView *newIcon = [[BPMessageMashupImageView alloc] initWithFrame: cell.icon.frame];
    newIcon.userID = suggestion.id;
    [cell addSubview: newIcon];
    [cell.icon removeFromSuperview];
    cell.icon = newIcon;

    return cell;
}

@end
