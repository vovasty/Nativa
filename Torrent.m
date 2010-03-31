/******************************************************************************
 * Nativa - MacOS X UI for rtorrent
 * http://www.aramzamzam.net
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
 *****************************************************************************/

#import "Torrent.h"
#import "NativaConstants.h"

@implementation Torrent

@synthesize name, size, thash, state, speedDownload, speedUpload, dataLocation, uploadRate, downloadRate, totalPeersSeed, totalPeersLeech, totalPeersDisconnected, priority, isFolder, error, groupName;

@dynamic active;

- (void)dealloc
{
	[self setName:nil];
	[self setThash:nil];
	[_icon release];
	[self setDataLocation:nil];
	[self setError:nil];
	[self setGroupName:nil];
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
	self.totalPeersSeed=anotherItem.totalPeersSeed;
	self.totalPeersLeech=anotherItem.totalPeersLeech;
	self.totalPeersDisconnected=anotherItem.totalPeersDisconnected;
	self.dataLocation = (anotherItem.dataLocation == nil?self.dataLocation:anotherItem.dataLocation);
	self.priority = anotherItem.priority;
	self.error = anotherItem.error;
	self.groupName = anotherItem.groupName;
}

- (double) progress
{
	return ((float)downloadRate/(float)size);
}

- (NSImage*) icon
{
	if (!_icon)
		_icon = [[[NSWorkspace sharedWorkspace] iconForFileType: [self isFolder] ? NSFileTypeForHFSTypeCode('fldr')
															   : [[self name] pathExtension]] retain];

	return _icon;
}

- (CGFloat) ratio
{
	if (downloadRate == 0)
		return NI_RATIO_NA;
	else
		return (CGFloat)uploadRate/(CGFloat)downloadRate;
}
- (BOOL) active
{
	return state != NITorrentStateStopped;
}
@end
