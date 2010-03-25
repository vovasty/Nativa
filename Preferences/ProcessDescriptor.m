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
#import "AMSession.h"
#import "AMServer.h"

@implementation ProcessDescriptor

@synthesize name = _name;
@synthesize processType = _processType;
@synthesize host = _host;
@synthesize port = _port;
@synthesize downloadsFolder = _downloadsFolder;

@synthesize connectionType = _connectionType;
@synthesize sshHost = _sshHost;
@synthesize sshPort = _sshPort;
@synthesize sshUsername = _sshUsername;
@synthesize sshPassword = _sshPassword;
@synthesize sshLocalPort = _sshLocalPort;

@synthesize process = _process;
@synthesize connection = _connection;
@synthesize maxReconnects = _maxReconnects;

//NSCoding stuff
- (id)initWithCoder:(NSCoder*)coder
{		
	if (self = [super init])
    {
        self.name = [coder decodeObjectForKey:@"name"];
		self.processType = [coder decodeObjectForKey:@"processType"];
        self.host = [coder decodeObjectForKey:@"host"];
        self.port = [coder decodeIntForKey:@"port"];
		self.downloadsFolder = [coder decodeObjectForKey:@"downloadsFolder"];
		
		self.connectionType = [coder decodeObjectForKey:@"connectionType"];
		self.sshHost = [coder decodeObjectForKey:@"sshHost"];
		self.sshPort = [coder decodeObjectForKey:@"sshPort"];
		self.sshUsername = [coder decodeObjectForKey:@"sshUsername"];
		self.sshPassword = [coder decodeObjectForKey:@"sshPassword"];
		self.sshLocalPort = [coder decodeIntForKey:@"sshLocalPort"];
		self.maxReconnects = [coder decodeIntForKey:@"maxReconnects"];
    }
	
    return self;
	
}

- (void)encodeWithCoder:(NSCoder*)coder
{	
	[coder encodeObject:_name forKey:@"name"];
	[coder encodeObject:_processType forKey:@"processType"];
	[coder encodeObject:_host forKey:@"host"];
	[coder encodeInt:_port forKey:@"port"];
	[coder encodeObject:_downloadsFolder forKey:@"downloadsFolder"];
	
	[coder encodeObject:_connectionType forKey:@"connectionType"];
	[coder encodeObject:_sshHost forKey:@"sshHost"];
	[coder encodeObject:_sshPort forKey:@"sshPort"];
	[coder encodeObject:_sshUsername forKey:@"sshUsername"];
	[coder encodeObject:_sshPassword forKey:@"sshPassword"];
	[coder encodeInt:_sshLocalPort forKey:@"sshLocalPort"];
	[coder encodeInt:_maxReconnects forKey:@"maxReconnects"];
}

-(void) dealloc
{
	[_process release];

	[_name release];
	[_processType release];
	[_host release];
	[_downloadsFolder release];
	
	[_connectionType release];
	[_sshHost release];
	[_sshPort release];
	[_sshUsername release];
	[_sshPassword release];
	
	[super dealloc];
}

-(id<TorrentController>) process;
{
	return _process;
}
-(void) closeProcess
{
	[self.process closeConnection];
	self.process = nil;
	self.connection = nil;
}

-(void) openProcess:(VoidResponseBlock) response
{
	AMSession* proxy = nil;
	if ([_connectionType isEqualToString: @"SSH"])
	{
		proxy = [[AMSession alloc] init];
		proxy.sessionName = _name;
		proxy.remoteHost = _host;
		
		proxy.localPort = _sshLocalPort;
		proxy.remotePort = _port;
		
		AMServer *server = [[AMServer alloc] init];
		server.host = _sshHost;
		server.username = _sshUsername;
		server.password = _sshPassword;
		server.port = _sshPort;
		proxy.currentServer = server;
		proxy.maxAutoReconnectRetries = _maxReconnects;
		proxy.autoReconnect = YES;
		[server release];
	}
	RTConnection* c = [[RTConnection alloc] initWithHostPort:_host port:_port proxy:proxy];
	self.connection = c;
	[c release];
	[proxy release];
	
	RTorrentController *p = [[RTorrentController alloc] initWithConnection:self.connection];
	self.process = p;
	[p release];
	
	[self.process openConnection:response];

}
@end
