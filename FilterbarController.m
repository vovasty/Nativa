//
//  AppController.m
//  Filterbar
//
//  Created by Matteo Bertozzi on 11/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FilterbarController.h"
#import "TorrentState.h"
#import "SynthesizeSingleton.h"

static NSString *FILTER_ALL = @"All";
static NSString *FILTER_DOWNLOAD = @"Downloading";
static NSString *FILTER_UPLOAD = @"Uploading";
static NSString *FILTER_STOP = @"Paused";


@implementation FilterbarController
SYNTHESIZE_SINGLETON_FOR_CLASS(FilterbarController);

@synthesize filter = _filter;

- (void)awakeFromNib {
	[filterBar addGroup:@"Status"];

	[filterBar selectItem:@"All" inGroup:@"Status" selected:YES];
}

- (NSArray *)filterbar:(Filterbar *)filterBar
		itemIdentifiersForGroup:(NSString *)groupIdentifier
{
	if (groupIdentifier == @"Status")
		return [NSArray arrayWithObjects:FILTER_ALL, FILTER_DOWNLOAD, FILTER_UPLOAD, FILTER_STOP, nil];
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
	if (itemIdentifier == FILTER_UPLOAD)
	{
		[FilterbarController sharedFilterbarController].filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat: @"SELF.state == %d",seed]];
	}
	else if (itemIdentifier == FILTER_DOWNLOAD)
	{
		[FilterbarController sharedFilterbarController].filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat: @"SELF.state == %d",leech]];
	}
	else if (itemIdentifier == FILTER_STOP)
	{
		[FilterbarController sharedFilterbarController].filter = [NSPredicate predicateWithFormat:[NSString stringWithFormat: @"SELF.state == %d",stop]];
	}
	else 
		[FilterbarController sharedFilterbarController].filter = nil;
}
@end
