//
//  ProcessDescriptor.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 03.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "ProcessDescriptor.h"
#import "RTConnection.h"
#import "RTorrentController.h"

@implementation ProcessDescriptor

@synthesize name = _name;
@synthesize processType = _processType;
@synthesize manualConfig = _manualConfig;
@synthesize host = _host;
@synthesize port = _port;
@synthesize downloadsFolder = _downloadsFolder;

//NSCoding stuff
- (id)initWithCoder:(NSCoder*)coder
{		
	if (self = [super init])
    {
        self.name = [coder decodeObjectForKey:@"name"];
		self.processType = [coder decodeObjectForKey:@"processType"];
        self.manualConfig = [coder decodeBoolForKey:@"manualConfig"];
        self.host = [coder decodeObjectForKey:@"host"];
        self.port = [coder decodeIntForKey:@"port"];
		self.downloadsFolder = [coder decodeObjectForKey:@"downloadsFolder"];
    }
	
    return self;
	
}

- (void)encodeWithCoder:(NSCoder*)coder
{	
	[coder encodeObject:_name forKey:@"name"];
	[coder encodeObject:_processType forKey:@"processType"];
    [coder encodeBool:_manualConfig forKey:@"manualConfig"];
	[coder encodeObject:_host forKey:@"host"];
	[coder encodeInt:_port forKey:@"port"];
	[coder encodeObject:_downloadsFolder forKey:@"downloadsFolder"];
}

-(void) dealloc
{
	[_process release];
	[_name release];
	[_processType release];
	[_host release];
	[_downloadsFolder release];
	[super dealloc];
}

-(id<TorrentController>) process;
{
	if (_process == nil)
	{
		RTConnection *connection = [[RTConnection alloc] initWithHostPort:_host port:_port];
		_process = [[RTorrentController alloc] initWithConnection:connection];
		[_process retain];
		[connection release];
	}
	return _process;
}
@end
