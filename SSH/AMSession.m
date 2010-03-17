// Copyright (C) 2008  Antoine Mercadal
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#import "AMSession.h"

@interface AMSession(Private)
-(void) analyzeOutput:(NSData*) data;
@end

@implementation AMSession

@synthesize	sessionName;
@synthesize portsMap;
@synthesize remoteHost;
@synthesize connected = _connected;
@synthesize connectionInProgress = _connectionInProgress;
@synthesize currentServer;
@synthesize autoReconnect;
@synthesize maxAutoReconnectRetries;
@dynamic error;

#pragma mark Initilizations

- (id) init
{
	if ((self = [super init]) == nil)
		return nil;
	
	_connected = NO;
	_connectionInProgress = NO;
	autoReconnectTimes = 0;

	outputContent	= [[NSMutableString alloc] init];

	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[sessionName release];
	[portsMap release];
	[remoteHost release];
	
	if ([sshTask isRunning] == YES)
		[sshTask terminate];
	
	[sshTask  release];
	[outputContent release];
	[error release];
	[currentServer release];
	[super dealloc];
}

#pragma mark Helper methods

- (NSMutableArray *) parsePortsSequence:(NSString*)seq
{
	NSArray *units;
	NSMutableArray *ranges = [[NSMutableArray alloc] init];
	NSMutableArray	*ports  = [[NSMutableArray alloc] init];
	NSPredicate *containRange = [NSPredicate predicateWithFormat:@"SELF contains[c] '-' "];
	NSPredicate *validPort = [NSPredicate predicateWithFormat:@"SELF matches '[0-9]+'"];
	
	units = [seq componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ,;"]];
	
	for (NSString* s in units)
	{
		
		if ([containRange evaluateWithObject:s] == YES)
		{
			[ranges addObject:s];
		}
		else if ([validPort evaluateWithObject:s])
		{
			[ports addObject:s];
		}
	}
	
	for (NSString* s in ranges)
	{
		NSInteger	startPort;
		NSInteger	stopPort;
		NSInteger	i;
		NSArray		*bounds;
		
		bounds = [s componentsSeparatedByString:@"-"];
		startPort = [[bounds objectAtIndex:0] intValue];
		stopPort = [[bounds objectAtIndex:1] intValue];
		
		for (i = startPort; i <= stopPort; i++)
			[ports addObject:[NSString stringWithFormat:@"%d", i]];
	}
	
	[ranges release];
	
	return ports;
}

- (NSMutableString *) prepareSSHCommandWithRemotePorts:(NSMutableArray *)remotePorts localPorts:(NSMutableArray *)localPorts  
{
	NSMutableString *argumentsString = [NSMutableString stringWithString: @"ssh "];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"forceSSHVersion2"])
		argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:@" -2 "];
	
	int i;
	for(i = 0; i < [remotePorts count]; i++)
	{
		argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:@"-N -L "];
		argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:[localPorts objectAtIndex:i]];
		argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:@":"];
		argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:remoteHost];
		argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:@":"];
		argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:[remotePorts objectAtIndex:i]];
	}
	
	argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:@" "];
	argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:[currentServer username]];
	argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:@"@"];
	argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:[currentServer host]];
	argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:@" -p "];
	argumentsString = (NSMutableString *)[argumentsString stringByAppendingString:[currentServer port]];

	NSLog(@"Used SSH Command : %@", argumentsString);
	
	return argumentsString;
}




#pragma mark Control methods

- (void) openTunnel
{
	NSString			*helperPath;
	NSArray				*args;
	NSMutableArray		*remotePorts;
	NSMutableArray		*localPorts;
	NSMutableString		*argumentsString;
	
	_connectionInProgress = YES;
	_connected = NO;

	tryReconnect = autoReconnect;

	[self setError: nil];
	
	NSPipe *stdOut			= [NSPipe pipe];
	
	
	[sshTask release];

	sshTask			= [[NSTask alloc] init];
	
	helperPath		= [[NSBundle mainBundle] pathForResource:@"SSHCommand" ofType:@"sh"];
	
	remotePorts		= [self parsePortsSequence:[portsMap serviceRemotePorts]];
	localPorts		= [self parsePortsSequence:[portsMap serviceLocalPorts]];
	
	argumentsString = [self prepareSSHCommandWithRemotePorts:remotePorts localPorts:localPorts];
	
	[remotePorts release];
	[localPorts release];
	
	args			= [NSArray arrayWithObjects:argumentsString, [currentServer password], nil];

	[outputContent setString:@""];

	[sshTask setLaunchPath:helperPath];

	[sshTask setArguments:args];

	[sshTask setStandardOutput:stdOut];
	
	outputHandle = [[sshTask standardOutput] fileHandleForReading];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(handleProcessusExecution:)
												 name:NSFileHandleReadCompletionNotification
											   object:outputHandle];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(listernerForSSHTunnelDown:) 
												 name:NSTaskDidTerminateNotification
											   object:sshTask];
	
	[outputHandle readInBackgroundAndNotify];
	
	[sshTask launch];

	NSLog(@"Session %@ is now launched.", [self sessionName]);
}

- (void) closeTunnel
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:sshTask];

	tryReconnect = NO;

	NSLog(@"Session %@ is now closed.", [self sessionName]);
	if ([sshTask isRunning])
		[sshTask terminate];
	[sshTask release];
	sshTask = nil;
	autoReconnectTimes = 0;
}



#pragma mark Observers and delegates
- (void) handleProcessusExecution:(NSNotification *) aNotification
{
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	[self analyzeOutput:data];
}

- (void) listernerForSSHTunnelDown:(NSNotification *)notification
{	
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
    [[NSRunLoop currentRunLoop] runUntilDate: future];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:sshTask];
	[[NSNotificationCenter defaultCenter]  removeObserver:self name:NSFileHandleReadCompletionNotification  object:outputHandle];

	if (tryReconnect && autoReconnectTimes<maxAutoReconnectRetries)
	{
		NSLog(@"reconnecting ssh tunnel ...");
		autoReconnectTimes++;
		[self openTunnel];
	}
	else 
	{
		autoReconnectTimes = 0;
		if (error == nil)
			[self setError:@"SSH: unknown error"];
		[self willChangeValueForKey:@"connectionInProgress"];
		[self willChangeValueForKey:@"connected"];
		_connectionInProgress = NO;
		_connected = NO;
		[self didChangeValueForKey:@"connectionInProgress"];
		[self didChangeValueForKey:@"connected"];
	}

}
-(NSString*) error
{
	return error;
}

-(void)setError:(NSString *)newValue {
    if (error != newValue) {
        [error release];
        error = [newValue retain];
    }
	if (error)
		NSLog(@"ssh tunnel error: %@", error);
}
@end

@implementation AMSession(Private)
-(void) analyzeOutput:(NSData*) data
{
	if ([data length])
	{
		NSPredicate *checkError			= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'CONNECTION_ERROR'"];
		NSPredicate *checkWrongPass		= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'WRONG_PASSWORD'"];
		NSPredicate *checkConnected		= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'CONNECTED'"];
		NSPredicate *checkRefused		= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'CONNECTION_REFUSED'"];
		NSPredicate *checkTimeout		= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'CONNECTION_TIMEOUT'"];
		NSPredicate *checkWrongHostname	= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'WRONG_HOSTNAME'"];
		NSPredicate *checkPort			= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'Could not request local forwarding'"];
		
		NSString* stmp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		[outputContent appendString:stmp];
		
		NSLog(@"ssh out:%@", stmp);
		
		[stmp release];
		
		if ([checkError evaluateWithObject:outputContent] == YES)
		{
			[self setError: @"SSH: Unknown error as occured while connecting."];
			[sshTask terminate];
			
		}
		else if ([checkWrongPass evaluateWithObject:outputContent] == YES)
		{
			[self setError: @"SSH: The password or username set for the server are wrong"];
			[sshTask terminate];
		}
		else if ([checkRefused evaluateWithObject:outputContent] == YES)
		{
			[self setError: @"SSH: Connection has been rejected by the server."];
			[sshTask terminate];
		}		
		else if ([checkWrongHostname evaluateWithObject:outputContent] == YES)
		{
			[self setError: @"SSH: Wrong hostname."];
			[sshTask terminate];
		}		
		else if ([checkTimeout evaluateWithObject:outputContent] == YES)
		{
			[self setError: @"SSH: Connection timeout."];
			[sshTask terminate];
		}		
		else if ([checkPort evaluateWithObject:outputContent] == YES)
		{
			[self setError: @"SSH: The port is already used on server."];
			[sshTask terminate];
		}
		else if ([checkConnected evaluateWithObject:outputContent] == YES)
		{
			[[NSNotificationCenter defaultCenter]  removeObserver:self name:NSFileHandleReadCompletionNotification  object:outputHandle];
			
			[self willChangeValueForKey:@"connectionInProgress"];
			[self willChangeValueForKey:@"connected"];
			_connectionInProgress = NO;
			_connected = YES;
			[self didChangeValueForKey:@"connectionInProgress"];
			[self didChangeValueForKey:@"connected"];
			//reset autoreconnect counter
			autoReconnectTimes = 0;
		}
		else
			[outputHandle readInBackgroundAndNotify];
	}
}
@end
