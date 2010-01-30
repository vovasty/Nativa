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
	
	unsigned long int size;

	unsigned long int downloaded;
	
	unsigned long int uploaded;
	
	enum TorrentState state;
	
	NSImage* _icon;
	
	unsigned int speedDownload;
	
	unsigned int speedUpload;
}
@property (readwrite, retain) NSString* name;
@property (readwrite, retain) NSString* thash;

@property unsigned long int downloaded;

@property unsigned long int uploaded;

@property unsigned long int size;

@property enum TorrentState state;

@property unsigned int speedDownload;

@property unsigned int speedUpload;

- (void) update: (Torrent *) anotherItem;
- (double) progress;
- (NSImage*) icon;
@end