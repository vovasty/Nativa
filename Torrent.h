//
//  TorrentData.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 06.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum 
{ 
	NITorrentStateStopped = 0,
	NITorrentStateSeeding = 1,
	NITorrentStateLeeching = 2,
	NITorrentStateChecking = 3,
	NITorrentStateUnknown = 4
} TorrentState;

typedef enum 
{ 
	NITorrentPriorityOff = 0,
	NITorrentPriorityLow = 1,
	NITorrentPriorityNormal = 2,
	NITorrentPriorityHigh = 3,
} TorrentPriority;



@interface Torrent : NSObject 
{
	NSString* name;
	
	NSString* thash;
	
	uint64_t size;

	TorrentState state;
	
	NSImage* _icon;
	
	CGFloat speedDownload;
	
	CGFloat speedUpload;
	
	uint64_t downloadRate;
	
	uint64_t uploadRate;
	
	NSInteger totalPeersSeed;
	
	NSInteger totalPeersLeech;
	
	NSInteger totalPeersDisconnected;
	
	NSString* dataLocation;
	
	TorrentPriority priority;
	
	NSString* error;
	
	BOOL isFolder;
	
	NSString *groupName;
}
@property (readwrite, retain) NSString* name;

@property (readwrite, retain) NSString* thash;

@property uint64_t size;

@property TorrentState state;

@property CGFloat speedDownload;

@property CGFloat speedUpload;

@property (retain) NSString* dataLocation;

@property uint64_t downloadRate;

@property uint64_t uploadRate;

@property NSInteger totalPeersSeed;

@property NSInteger totalPeersLeech;

@property NSInteger totalPeersDisconnected;

@property TorrentPriority priority;

@property BOOL isFolder;

@property (retain) NSString* error;

@property (retain) NSString* groupName;

- (void) update: (Torrent *) anotherItem;
- (double) progress;
- (NSImage*) icon;
- (CGFloat) ratio;
- (NSUInteger)hash;
- (BOOL)isEqual:(id)anObject;
@end