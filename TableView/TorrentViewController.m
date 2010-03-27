/*
 * Nativa - MacOS X UI for rtorrent
 *
 * Copyright Solomenchuk V. 2010.
 * Solomenchuk Vladimir <vovasty@aramzamzam.net>
 *
 * Licensed under the GPL, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.gnu.org/licenses/gpl-3.0.html
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "TorrentViewController.h"
#import "TorrentCell.h"
#import "TorrentTableView.h"
#import "TorrentGroup.h"
#import "Torrent.h";
#import "DownloadsController.h"
#import "FilterbarController.h"
#import "NSStringTorrentAdditions.h"
#import "GroupsController.h"

static NSString* FilterTorrents = @"FilterTorrents";

@interface TorrentViewController(Private)

- (void)updateList:(NSNotification*) notification;

@end


@implementation TorrentViewController

- (void)dealloc 
{
    [_tableContents release];
	[_allGroups release];
	[_orderedGroups release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)awakeFromNib {
	_defaults = [NSUserDefaults standardUserDefaults];

	_allGroups = [[NSMutableDictionary alloc] init];
	_orderedGroups = [[NSMutableArray alloc] init];
	TorrentGroup* noGroup = [[TorrentGroup alloc ] initWithGroup:-1];
	[_orderedGroups addObject:noGroup];
	
	for (NSInteger i=0;i<[[GroupsController groups] numberOfGroups];i++)
	{
		NSInteger index = [[GroupsController groups] indexForRow:i];
		TorrentGroup* group = [[TorrentGroup alloc ] initWithGroup:index];
		NSString *groupName = [[GroupsController groups] nameForIndex:index];
		[_allGroups setObject:group forKey:groupName];
		[_orderedGroups addObject:group];
	}
	
	[_allGroups retain];
	[_orderedGroups retain];
	
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateList:) name: NINotifyUpdateDownloads object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:nil];
	
	_tableContents = [[[NSArray alloc] init] retain]; 
	[[FilterbarController sharedFilterbarController] addObserver:self
													 forKeyPath:@"stateFilter"
													  options:0
													  context:&FilterTorrents];
	_tableContents = [[[NSMutableArray alloc] init] retain];	
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &FilterTorrents)
    {
		[self updateList:nil];
		
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void) setGroup: (id) sender
{
	NSString *group = [[GroupsController groups] nameForIndex:[sender tag]];
	for (Torrent * torrent in [_outlineView selectedTorrents])
    {
		[[DownloadsController sharedDownloadsController] setGroup:torrent group:group response:nil];
    }
	[_outlineView deselectAll: nil];
}

#pragma mark -
#pragma mark NSTableViewDelegate & NSTableViewDataSource

- (NSInteger) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item
{
    if (item)
        return [[item torrents] count];
    else
        return [_tableContents count];
}

- (id) outlineView: (NSOutlineView *) outlineView child: (NSInteger) index ofItem: (id) item
{
    if (item)
        return [[item torrents] objectAtIndex: index];
    else
        return [_tableContents objectAtIndex: index];
}

- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item
{
    return ![item isKindOfClass: [Torrent class]];
}

- (id) outlineView: (NSOutlineView *) outlineView objectValueForTableColumn: (NSTableColumn *) tableColumn byItem: (id) item
{
    if ([item isKindOfClass: [Torrent class]])
        return ((Torrent*)item).thash;
	else 
	{
        NSString * ident = [tableColumn identifier];
        if ([ident isEqualToString: @"Group"])
        {
            NSInteger group = [item groupIndex];
            return group != -1 ? [[GroupsController groups] nameForIndex: group]
				: NSLocalizedString(@"No Group", "Group table row");
        }
        else if ([ident isEqualToString: @"Color"])
        {
            NSInteger group = [item groupIndex];
            return [[GroupsController groups] imageForIndex: group];
        }
        else if ([ident isEqualToString: @"DL Image"])
            return [NSImage imageNamed: @"DownArrowGroupTemplate.png"];
        else if ([ident isEqualToString: @"UL Image"])
            return [NSImage imageNamed: [_defaults boolForKey: @"DisplayGroupRowRatio"]
					? @"YingYangGroupTemplate.png" : @"UpArrowGroupTemplate.png"];
        else
        {
            TorrentGroup * group = (TorrentGroup *)item;
            
            if ([_defaults boolForKey: @"DisplayGroupRowRatio"])
                return [NSString stringForRatio: [group ratio]];
            else
            {
                CGFloat rate = [ident isEqualToString: @"UL"] ? [group uploadRate] : [group downloadRate];
                return [NSString stringForSpeed: rate];
            }
        }
	}
}

#pragma mark -
#pragma mark NSMenuDelegate

- (void) menuNeedsUpdate: (NSMenu *) menu
{
    if (menu == _groupsMenu)
    {
        [menu removeAllItems];
		
        NSMenu * groupMenu;
            groupMenu = [[GroupsController groups] groupMenuWithTarget: self action: @selector(setGroup:) isSmall: NO];
        
        const NSInteger groupMenuCount = [groupMenu numberOfItems];
        for (NSInteger i = 0; i < groupMenuCount; i++)
        {
            NSMenuItem * item = [[groupMenu itemAtIndex: 0] retain];
            [groupMenu removeItemAtIndex: 0];
            [menu addItem: item];
            [item release];
        }
    }
    else;
}

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
    SEL action = [menuItem action];
	
    BOOL canUseTable = [_window isKeyWindow] || [[menuItem menu] supermenu] != [NSApp mainMenu];
	
    if (action == @selector(setGroup:))
    {
        BOOL checked = NO;
        
        NSInteger index = [menuItem tag];
		
		NSString *groupName = [[GroupsController groups] nameForIndex:index];
		
        for (Torrent * torrent in [_outlineView selectedTorrents])
		{
			if ([torrent groupName] == nil)
			{
				if (index == -1) //empty group menu item?
					checked = YES;
				break;
			}
			else if ([groupName isEqualToString:[torrent groupName]])
            {
                checked = YES;
                break;
            }
			else;
			
        }
        [menuItem setState: checked ? NSOnState : NSOffState];
        return canUseTable && [_outlineView numberOfSelectedRows] > 0;
    }
    return YES;
}
@end

@implementation TorrentViewController(Private)

- (void)updateList:(NSNotification*) notification;
{
	//skip updates if window is not visible
	if (![_window isVisible]) 
		return;

	
	NSPredicate* filter = [FilterbarController sharedFilterbarController].stateFilter;
	NSMutableArray* arr = [NSMutableArray arrayWithArray:[[DownloadsController sharedDownloadsController] downloads]];
	
	if (filter != nil)
		[arr filterUsingPredicate:filter];
	
	NSSortDescriptor *nameSorter = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	[arr sortUsingDescriptors:[NSArray arrayWithObject:nameSorter]];
	[nameSorter release];
	
	//clean all groups
	for(int i=0;i<[_tableContents count];i++)
		[[[_tableContents objectAtIndex:i] torrents] removeAllObjects];

	for(Torrent* torrent in arr)
	{
		TorrentGroup *group = [_allGroups objectForKey:[torrent groupName]];

		if (group == nil) //set default group if no group found
			group = [_orderedGroups objectAtIndex:0];
		
		[[group torrents] addObject:torrent];
	}

	//clean view table
	[_tableContents removeAllObjects];
	
	//add only non-empty groups
	for (TorrentGroup *group in _orderedGroups) 
	{
		if ([[group torrents] count] != 0)
		{
			[_tableContents addObject:group];
		}
	}
	
	@synchronized(self)
	{
		[_outlineView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];

		//expand groups
		for (TorrentGroup * group in _tableContents)
		{
			if ([_outlineView isGroupCollapsed: [group groupIndex]])
				[_outlineView collapseItem: group];
			else
				[_outlineView expandItem: group];
		}
		
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[_outlineView saveCollapsedGroups];
}

@end
