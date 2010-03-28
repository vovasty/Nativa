//
//  ListCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "RTListCommand.h"
#import "Torrent.h"

@interface RTListCommand(Private)

- (TorrentState) defineTorrentState:(NSNumber*) state opened:(NSNumber*) opened done:(float) done;

- (TorrentPriority) defineTorrentPriority:(NSNumber*) priority;

@end

@implementation RTListCommand

@synthesize response = _response;
@synthesize groupCommand = _groupCommand;

- (id)initWithArrayResponse:(ArrayResponseBlock) resp;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _response = [resp retain];
    return self;
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
			r.speedDownload = [speedDownload floatValue];
			NSNumber*  speedUpload = [row  objectAtIndex:7];
			r.speedUpload = [speedUpload floatValue];
			NSNumber*  uploadRate = [row  objectAtIndex:8];
			r.uploadRate = [uploadRate integerValue];
			r.dataLocation = [row objectAtIndex:9];
			NSNumber *conn = [row  objectAtIndex:10];
			NSNumber *notConn = [row  objectAtIndex:11];
			NSNumber *compl = [row  objectAtIndex:12];
			r.totalPeersLeech = [conn integerValue] - [compl integerValue];
			r.totalPeersSeed = [compl integerValue];
			r.totalPeersDisconnected = [notConn integerValue];
			r.priority = [self defineTorrentPriority:[row objectAtIndex:13]];
			r.isFolder = [[row  objectAtIndex:14] isEqualToString:r.dataLocation];
			NSString* errorMessage = [row  objectAtIndex:15];
			r.error = [errorMessage isEqualToString:@""]?nil:errorMessage;
			NSString *groupName = [row  objectAtIndex:16];
			
			NSString *decodedGroupName = [groupName isEqualToString:@""]?nil:
									(NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault,
										(CFStringRef)groupName,
										CFSTR(""));
			r.groupName = decodedGroupName;
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
			@"d.get_priority=",
			@"d.get_directory=",
			@"d.get_message=",
			[_groupCommand stringByAppendingString:@"="],
			nil];
}

- (void)dealloc
{
	[_response release];
	[self setGroupCommand:nil];
	[super dealloc];
}
@end

@implementation RTListCommand(Private)

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

- (TorrentPriority) defineTorrentPriority:(NSNumber*) priority
{
	switch ([priority integerValue]) {
		case 0:
			return NITorrentPriorityOff;
		case 1:
			return NITorrentPriorityLow;
		case 2:
			return NITorrentPriorityNormal;
		case 3:
			return NITorrentPriorityHigh;
	}
	return NITorrentPriorityNormal;
}
@end