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
			NSNumber*  chunk_size = [row  objectAtIndex:2];
			NSNumber*  size_chunks = [row  objectAtIndex:3];
			NSNumber*  completed_chunks = [row  objectAtIndex:4];
			r.size = [size_chunks longValue] * [chunk_size longValue];
			r.downloaded = [completed_chunks longValue] * [chunk_size longValue];
			NSNumber* state = [row  objectAtIndex:5];
			NSNumber* opened = [row  objectAtIndex:6];
			r.state = [self defineTorrentState:state opened:opened done:[r progress]];
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
			@"d.get_chunk_size=",
			@"d.get_size_chunks=",
			@"d.get_completed_chunks=",
			@"d.get_state=",
			@"d.is_open=",
			@"d.get_down_rate=",
			@"d.get_up_rate=",
			nil];
}

- (void)dealloc
{
	[_response release];
	[super dealloc];
}
@end
