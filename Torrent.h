//
//  TorrentData.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 06.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum TorrentState { stopped = 0, seeding = 1, leeching = 2, checking = 3, unknown = 4 };


@interface Torrent : NSObject 
{
	NSString* name;
	
	NSString* thash;
	
	uint64_t size;

	enum TorrentState state;
	
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

@property enum TorrentState state;

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