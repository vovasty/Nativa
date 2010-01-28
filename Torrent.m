//
//  TorrentData.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 06.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Torrent.h"


@implementation Torrent

@synthesize name, size, progress, thash, downloaded, uploaded, state;

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		// Set up discrete progress.
		progress = [[NSProgressIndicator alloc] init];
		[progress setStyle:NSProgressIndicatorBarStyle];
		[progress setIndeterminate:NO];
		[progress setControlSize:NSSmallControlSize];
		[progress setMinValue:0];
		[progress setMaxValue:100];
		[progress startAnimation:nil];
		[progress setHidden:NO];
		
		[progress setDoubleValue:0];
	}
	return self;
}

- (void)dealloc
{
	[progress removeFromSuperview];
	[progress release];
	[name release];
	[thash release];
	[_icon release];
	[super dealloc];
}

- (NSUInteger)hash;
{
	return [thash hash];
}

- (BOOL)isEqual:(id)anObject;
{
	return [thash hash] == [anObject hash];
}

- (void) update: (Torrent *) anotherItem;
{
	self.downloaded = anotherItem.downloaded;
	self.uploaded = anotherItem.uploaded;
	self.state = anotherItem.state;
	[progress setDoubleValue:[self donePercent]];
}

- (double) donePercent
{
	return ((float)downloaded/(float)size)*100;
}

- (NSImage*) icon
{
//	static int x = 0;

	if (!_icon)
		{
			_icon = [[[NSWorkspace sharedWorkspace] iconForFileType: [[self name] pathExtension]] retain];
//			_icon = [[NSImage alloc] initByReferencingFile:[NSString stringWithFormat: @"/Users/vovasty/%d.jpg", x]];
//			x += x>6?(-x+1):1;
//			[_icon retain];
			//_icon = [[[NSWorkspace sharedWorkspace] iconForFileType: @"txt"] retain];
		}
		
		return _icon;
}
@end
