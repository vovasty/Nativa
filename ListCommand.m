//
//  ListCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "ListCommand.h"
#import "TorrentItem.h"

@implementation ListCommand

@synthesize response = _response;
@synthesize error = _error;

- (enum TorrentState) defineTorrentState:(NSNumber*) state opened:(NSNumber*) opened done:(float) done
{
	switch ([state intValue]) {
		case 1: //started
			if (opened==0)
				return stop;
			else
			{
				if (done>=100)
					return seed;
				else
					return leech;
			}
		case 0: //stopped
			return stop;
	}
	return unknown;
}


- (void) processResponse:(id) data;
{
	NSMutableArray* result = [[NSMutableArray alloc] init];
	for (NSArray* row in data)
	{
		TorrentItem* r = [[TorrentItem alloc] init];
		r.thash = [row objectAtIndex:0];
		r.name = [row objectAtIndex:1];
		NSNumber*  chunk_size = [row  objectAtIndex:2];
		NSNumber*  size_chunks = [row  objectAtIndex:3];
		NSNumber*  completed_chunks = [row  objectAtIndex:4];
		r.size = [size_chunks longValue] * [chunk_size longValue];
		r.downloaded = [completed_chunks longValue] * [chunk_size longValue];
		NSNumber* state = [row  objectAtIndex:5];
		NSNumber* opened = [row  objectAtIndex:6];
		r.state = [self defineTorrentState:state opened:opened done:[r donePercent]];
		[result addObject:r];
		[r autorelease];
	}
	[result autorelease];
	if (_response)
		_response(result);
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
	[_error release];
	[super dealloc];
}

-(void) setError:(NSString *)err;
{
	_error = err;
}
@end
