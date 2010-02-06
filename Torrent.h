//
//  TorrentData.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 06.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef TORRENT_H
#define TORRENT_H

typedef enum 
{ 
	NITorrentStateStopped = 0,
	NITorrentStateSeeding = 1,
	NITorrentStateLeeching = 2,
	NITorrentStateChecking = 3,
	NITorrentStateUnknown = 4
} TorrentState;

#endif /* TORRENT_H */


@interface Torrent : NSObject 
{
	NSString* name;
	
	NSString* thash;
	
	uint64_t size;

	TorrentState state;
	
	NSImage* _icon;
	
	CGFloat speedDownload;
	
	CGFloat speedUpload;
	
	CGFloat downloadRate;
	
	CGFloat uploadRate;
	
	NSInteger totalPeersSeed;
	
	NSInteger totalPeersLeech;
	
	NSInteger totalPeersDisconnected;
	
	NSString* dataLocation;
}
@property (readwrite, retain) NSString* name;

@property (readwrite, retain) NSString* thash;

@property uint64_t size;

@property TorrentState state;

@property CGFloat speedDownload;

@property CGFloat speedUpload;

@property (retain) NSString* dataLocation;

@property CGFloat downloadRate;

@property CGFloat uploadRate;

@property NSInteger totalPeersSeed;

@property NSInteger totalPeersLeech;

@property NSInteger totalPeersDisconnected;

- (void) update: (Torrent *) anotherItem;
- (double) progress;
- (NSImage*) icon;
- (CGFloat) ratio;
- (NSUInteger)hash;
- (BOOL)isEqual:(id)anObject;
@end