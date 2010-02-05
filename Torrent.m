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

@synthesize name, size, thash, state, speedDownload, speedUpload, dataLocation, uploadRate, downloadRate;

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

- (BOOL)isEqual:(id)anObject
{
	if ([anObject isKindOfClass: [Torrent class]])
		return [[anObject thash] isEqualToString: thash];
	else
		return NO;
}

- (void) update: (Torrent *) anotherItem;
{
	self.state = anotherItem.state;
	self.speedUpload = anotherItem.speedUpload;
	self.speedDownload = anotherItem.speedDownload;
	self.uploadRate = anotherItem.uploadRate;
	self.downloadRate = anotherItem.downloadRate;
}

- (double) progress
{
	return ((float)downloadRate/(float)size);
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
