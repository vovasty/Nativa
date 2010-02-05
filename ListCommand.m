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

- (enum TorrentState) defineTorrentState:(NSNumber*) state opened:(NSNumber*) opened done:(float) done
{
	switch ([state intValue]) {
		case 1: //started
			if (opened==0)
				return stopped;
			else
			{
				if (done>=1)
					return seeding;
				else
					return leeching;
			}
		case 0: //stopped
			return stopped;
	}
	return unknown;
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
			r.dataLocation = [row objectAtIndex:9];
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
			nil];
}

- (void)dealloc
{
	[_response release];
	[super dealloc];
}
@end
