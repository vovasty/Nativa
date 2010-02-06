//
//  ListCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "ListCommand.h"
#import "Torrent.h"

@implementation ListCommand

@synthesize response = _response;

- (TorrentState) defineTorrentState:(NSNumber*) state opened:(NSNumber*) opened done:(float) done
{
	switch ([state intValue]) {
		case 1: //started
			if (opened==0)
				return NITorrentStateStopped;
			else
			{
				if (done>=1)
					return NITorrentStateSeeding;
				else
					return NITorrentStateLeeching;
			}
		case 0: //stopped
			return NITorrentStateStopped;
	}
	return NITorrentStateUnknown;
}


- (void) processResponse:(id) data error:(NSString *) error;
{
	NSMutableArray* result = nil;
	if (error == nil)
	{
		result = [[NSMutableArray alloc] init];
		for (NSArray* row in data)
		{
			Torrent* r = [[Torrent alloc] init];
			r.thash = [row objectAtIndex:0];
			r.name = [row objectAtIndex:1];
			NSNumber*  size = [row  objectAtIndex:2];
			NSNumber*  completed = [row  objectAtIndex:3];
			r.size = [size integerValue];
			r.downloadRate = [completed integerValue];
			NSNumber* state = [row  objectAtIndex:4];
			NSNumber* opened = [row  objectAtIndex:5];
			r.state = [self defineTorrentState:state opened:opened done:[r progress]];
			NSNumber*  speedDownload = [row  objectAtIndex:6];
			r.speedDownload = [speedDownload floatValue]/1024;
			NSNumber*  speedUpload = [row  objectAtIndex:7];
			r.speedUpload = [speedUpload floatValue]/1024;
			NSNumber*  uploadRate = [row  objectAtIndex:8];
			r.uploadRate = [uploadRate floatValue];
#warning an odd memory leak here without autorelease
			r.dataLocation = [[row objectAtIndex:9] autorelease];
			NSNumber *conn = [row  objectAtIndex:10];
			NSNumber *notConn = [row  objectAtIndex:11];;
			NSNumber *compl = [row  objectAtIndex:12];;
			r.totalPeersLeech = [conn integerValue] - [compl integerValue];
			r.totalPeersSeed = [compl integerValue];
			r.totalPeersDisconnected = [notConn integerValue];
			[result addObject:r];
		}
		[result autorelease];
	}
	if (_response)
		_response(result, error);
}

- (NSString *) command;
{
	return @"d.multicall";
}
- (NSArray *) arguments;
{
	return [NSArray arrayWithObjects:
			@"main", 
			@"d.get_hash=", 
			@"d.get_name=", 
			@"d.get_size_bytes=",
			@"d.get_completed_bytes=",
			@"d.get_state=",
			@"d.is_open=",
			@"d.get_down_rate=",
			@"d.get_up_rate=",
			@"d.get_up_total=",
			@"d.get_base_path=",
			@"d.get_peers_connected=",
			@"d.get_peers_not_connected=",
			@"d.get_peers_complete=",
			nil];
}

- (void)dealloc
{
	[_response release];
	[super dealloc];
}
@end
