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
#import "AMService.h"
#import "AMServer.h"

@implementation ProcessDescriptor

@synthesize name = _name;
@synthesize processType = _processType;
@synthesize manualConfig = _manualConfig;
@synthesize host = _host;
@synthesize port = _port;
@synthesize downloadsFolder = _downloadsFolder;

@synthesize connectionType = _connectionType;
@synthesize sshHost = _sshHost;
@synthesize sshPort = _sshPort;
@synthesize sshUsername = _sshUsername;
@synthesize sshPassword = _sshPassword;
@synthesize sshLocalPort = _sshLocalPort;

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
		
		self.connectionType = [coder decodeObjectForKey:@"connectionType"];
		self.sshHost = [coder decodeObjectForKey:@"sshHost"];
		self.sshPort = [coder decodeObjectForKey:@"sshPort"];
		self.sshUsername = [coder decodeObjectForKey:@"sshUsername"];
		self.sshPassword = [coder decodeObjectForKey:@"sshPassword"];
		self.sshLocalPort = [coder decodeObjectForKey:@"sshLocalPort"];
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
	
	[coder encodeObject:_connectionType forKey:@"connectionType"];
	[coder encodeObject:_sshHost forKey:@"sshHost"];
	[coder encodeObject:_sshPort forKey:@"sshPort"];
	[coder encodeObject:_sshUsername forKey:@"sshUsername"];
	[coder encodeObject:_sshPassword forKey:@"sshPassword"];
	[coder encodeObject:_sshLocalPort forKey:@"sshLocalPort"];
}

-(void) dealloc
{
	[_process release];
	[_proxy release];

	[_name release];
	[_processType release];
	[_host release];
	[_downloadsFolder release];
	
	[_connectionType release];
	[_sshHost release];
	[_sshPort release];
	[_sshUsername release];
	[_sshPassword release];
	[_sshLocalPort release];
	
	[super dealloc];
}

-(id<TorrentController>) process;
{
	if (_process == nil)
	{
		if ([_connectionType isEqualToString: @"SSH"])
		{
			_proxy = [[AMSession alloc] init];
			_proxy.sessionName = _name;
			_proxy.remoteHost = _host;
			
			AMService* portsMap = [[AMService alloc] initWithPorts:_sshLocalPort remotePorts:[NSString stringWithFormat:@"%d", _port ]];
			
			_proxy.portsMap = portsMap;
			
			AMServer *server = [[AMServer alloc] init];
			server.host = _sshHost;
			server.username = _sshUsername;
			server.password = _sshPassword;
#warning hardcoded ssh port
			server.port = @"22";
			_proxy.currentServer = server;
			_proxy.maxAutoReconnectRetries = 10;
			_proxy.autoReconnect = YES;
			[_proxy openTunnel];

		}
		RTConnection *connection = [[RTConnection alloc] initWithHostPort:_host port:_port proxy:_proxy];
		_process = [[RTorrentController alloc] initWithConnection:connection];
		[_process retain];
		[connection release];
	}
	return _process;
}
-(void) closeProcess
{
	[_proxy closeTunnel];
}
@end
