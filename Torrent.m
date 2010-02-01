//
//  TorrentData.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 06.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Torrent.h"
#import "NativaConstants.h"

@implementation Torrent

@synthesize name, size, thash, downloaded, uploaded, state, speedDownload, speedUpload, dataLocation, uploadRate, downloadRate;

- (void)dealloc
{
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
}

- (double) progress
{
	return ((float)downloaded/(float)size);
}

- (NSImage*) icon
{
	if (!_icon)
		_icon = [[[NSWorkspace sharedWorkspace] iconForFileType: [[self name] pathExtension]] retain];

	return _icon;
}

- (CGFloat) ratio
{
	if (downloadRate == 0)
		return NI_RATIO_NA;
	else
		return (CGFloat)uploadRate/(CGFloat)downloadRate;
}
@end
