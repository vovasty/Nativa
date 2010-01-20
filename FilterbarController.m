//
//  AppController.m
//  Filterbar
//
//  Created by Matteo Bertozzi on 11/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FilterbarController.h"
#import "TorrentState.h"

static NSString *FILTER_ALL = @"All";
static NSString *FILTER_DOWNLOAD = @"Download";
static NSString *FILTER_UPLOAD = @"Upload";


@implementation FilterbarController

- (void)awakeFromNib {
	[filterBar addGroup:@"Status"];

	[filterBar selectItem:@"All" inGroup:@"Status" selected:YES];
}

- (NSArray *)filterbar:(Filterbar *)filterBar
		itemIdentifiersForGroup:(NSString *)groupIdentifier
{
	if (groupIdentifier == @"Status")
		return [NSArray arrayWithObjects:FILTER_ALL, FILTER_DOWNLOAD, FILTER_UPLOAD, nil];
	return nil;
}

- (NSString *)filterbar:(Filterbar *)filterBar
				labelForItemIdentifier:(NSString *)itemIdentifier
				groupIdentifier:(NSString *)groupIdentifier
{
	return itemIdentifier;
}

- (NSImage *)filterbar:(Filterbar *)filterBar
				imageForItemIdentifier:(NSString *)itemIdentifier
				groupIdentifier:(NSString *)groupIdentifier
{
	return nil;
}

- (void)filterbar:(Filterbar *)filterBar
			selectedStateChanged:(BOOL)selected
			fromItem:(NSString *)itemIdentifier
			groupIdentifier:(NSString *)groupIdentifier
{
	NSPredicate *filter;
	if (itemIdentifier == FILTER_UPLOAD)
	{
		filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat: @"SELF.state == %d",seed]];
	}
	else if (itemIdentifier == FILTER_DOWNLOAD)
	{
		filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat: @"SELF.state == %d",leech]];
	}
	else 
		filter = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"FilterTorrents" object: filter]; //incase sort by tracker
}
@end
