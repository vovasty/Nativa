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

NSString const *AMErrorLoadingSavedState = @"AMErrorLoadingSavedState";
NSString const *AMNewGeneralMessage = @"AMNewGeneralMessage";
NSString const *AMNewErrorMessage = @"AMNewErrorMessage";

@interface AMSession(Private)
-(void) analyzeOutput:(NSData*) data;
@end

@implementation AMSession

@synthesize	sessionName;
@synthesize portsMap;
@synthesize remoteHost;
@synthesize connected;
@synthesize connectionInProgress;
@synthesize currentServer;
@synthesize connectionLink;

#pragma mark Initilizations

- (id) init
{
	self = [super init];
	
	[self setConnected:NO];
	[self setConnectionInProgress:NO];
	autoReconnectTimes = 0;
	

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listernerForSSHTunnelDown:) 
												 name:@"NSTaskDidTerminateNotification" object:self];
	return self;
}

- (id) initWithCoder:(NSCoder *)coder
{
	self = [super init];
	
	self.sessionName			= [coder decodeObjectForKey:@"MVsessionName"];
	self.portsMap			= [coder decodeObjectForKey:@"portsMap"];
	self.remoteHost			= [coder decodeObjectForKey:@"MVremoteHost"];
	self.currentServer		= [coder decodeObjectForKey:@"MVcurrentServer"];
	
	[self setConnected:NO];
	[self setConnectionInProgress:NO];
	autoReconnectTimes = 0;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listernerForSSHTunnelDown:) 
												 name:@"NSTaskDidTerminateNotification" object:self];
	
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder
{	
	[coder encodeObject:sessionName forKey:@"MVsessionName"];
	[coder encodeObject:portsMap forKey:@"portsMap"];
	[coder encodeObject:remoteHost forKey:@"MVremoteHost"];
	[coder encodeObject:currentServer forKey:@"MVcurrentServer"];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[sessionName release];
	[portsMap release];
	[remoteHost release];
	[stdOut release];
	
	if ([sshTask isRunning] == YES)
		[sshTask terminate];
	
	[sshTask  release];
	[outputContent release];
	
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
	
	if ([self currentServer] == nil)
	{
		[self setConnected:NO];
		[self setConnectionInProgress:NO];
		[[NSNotificationCenter defaultCenter] postNotificationName:AMNewErrorMessage  
															object:@"There is no server set for this session."];
		return;
	}
	
	if (([self remoteHost] == nil) ||
		([self portsMap] == nil))
	{
		[self setConnected:NO];
		[self setConnectionInProgress:NO];
		[[NSNotificationCenter defaultCenter] postNotificationName:AMNewErrorMessage   
															object:@"There is no service or remote host set for this session"];
		return;
	}

	stdOut			= [NSPipe pipe];
	sshTask			= [[NSTask alloc] init];
	helperPath		= [[NSBundle mainBundle] pathForResource:@"SSHCommand" ofType:@"sh"];
	
	remotePorts		= [self parsePortsSequence:[portsMap serviceRemotePorts]];
	localPorts		= [self parsePortsSequence:[portsMap serviceLocalPorts]];
	
	argumentsString = [self prepareSSHCommandWithRemotePorts:remotePorts localPorts:localPorts];
	
	[remotePorts release];
	[localPorts release];
	
	args			= [NSArray arrayWithObjects:argumentsString, [currentServer password], nil];

	[outputContent release];
	outputContent	= [[NSMutableString alloc] initWithCapacity:4096];
	[outputContent retain];


	[sshTask setLaunchPath:helperPath];
	[sshTask setArguments:args];

	[sshTask setStandardOutput:stdOut];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(handleProcessusExecution:)
												 name:NSFileHandleReadCompletionNotification
											   object:[[sshTask standardOutput] fileHandleForReading]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(listernerForSSHTunnelDown:) 
												 name:@"NSTaskDidTerminateNotification" 
											   object:sshTask];
	
	[[stdOut fileHandleForReading] readInBackgroundAndNotify];
	[self setConnectionInProgress:YES];
	
	[sshTask launch];

	NSLog(@"Session %@ is now launched.", [self sessionName]);
	[[NSNotificationCenter defaultCenter] postNotificationName:AMNewGeneralMessage
														object:[@"Initializing connection for session "
																stringByAppendingString:[self sessionName]]];
	
	helperPath = nil;
	args = nil;
}

- (void) closeTunnel
{
	NSLog(@"Session %@ is now closed.", [self sessionName]);
	if ([sshTask isRunning])
		[sshTask terminate];
	sshTask = nil;
}



#pragma mark Observers and delegates
- (void) handleProcessusExecution:(NSNotification *) aNotification
{
	if ([sshTask isRunning])
	{
		NSData		*data;
	
		data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	
		[self analyzeOutput:data];
	}
}

- (void) listernerForSSHTunnelDown:(NSNotification *)notification
{	
	NSData *data = [[stdOut fileHandleForReading] readDataToEndOfFile];
	
	[self analyzeOutput:data];
	
	[[stdOut fileHandleForReading] closeFile];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:sshTask];
	[self setConnected:NO];
	[self setConnectionInProgress:NO];
	[self setConnectionLink:@""];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:AMNewGeneralMessage
														object:[@"Connection close for session "
																stringByAppendingString:[self sessionName]]];
}


@end

@implementation AMSession(Private)
-(void) analyzeOutput:(NSData*) data
{
	if ([data length])
	{
		NSPredicate *checkError		= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'CONNECTION_ERROR'"];
		NSPredicate *checkWrongPass	= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'WRONG_PASSWORD'"];
		NSPredicate *checkConnected	= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'CONNECTED'"];
		NSPredicate *checkRefused	= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'CONNECTION_REFUSED'"];
		NSPredicate *checkPort		= [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] 'Could not request local forwarding'"];
		
		NSString* stmp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		[outputContent appendString:stmp];
		
		NSLog(@"out:%@", stmp);
		
		[stmp release];
		
		if ([checkError evaluateWithObject:outputContent] == YES)
		{
			[[NSNotificationCenter defaultCenter]  removeObserver:self name:NSFileHandleReadCompletionNotification object:[stdOut fileHandleForReading]];
			
			[self setConnected:NO];
			[self setConnectionInProgress:NO];
			[self setConnectionLink:@""];
			[sshTask terminate];
			[[NSNotificationCenter defaultCenter] postNotificationName:AMNewErrorMessage 
																object:[@"Unknown error for session " 
																		stringByAppendingString:[self sessionName]]];
			NSRunAlertPanel(@"Error while connecting", @"Unknown error as occured while connecting." , @"Ok", nil, nil);
		}
		else if ([checkWrongPass evaluateWithObject:outputContent] == YES)
		{
			[[NSNotificationCenter defaultCenter]  removeObserver:self name:NSFileHandleReadCompletionNotification object:[stdOut fileHandleForReading]];
			[self setConnected:NO];
			[self setConnectionInProgress:NO];
			[self setConnectionLink:@""];
			[sshTask terminate];
			[[NSNotificationCenter defaultCenter] postNotificationName:AMNewErrorMessage
																object:[@"Wrong server password for session "
																		stringByAppendingString:[self sessionName]]];
			NSRunAlertPanel(@"Error while connecting", @"The password or username set for the server are wrong" , @"Ok", nil, nil);
		}
		else if ([checkRefused evaluateWithObject:outputContent] == YES)
		{
			[[NSNotificationCenter defaultCenter]  removeObserver:self name:NSFileHandleReadCompletionNotification  object:[stdOut fileHandleForReading]];
			
			[self setConnected:NO];
			[self setConnectionInProgress:NO];
			[self setConnectionLink:@""];
			[sshTask terminate];
			[[NSNotificationCenter defaultCenter] postNotificationName:AMNewErrorMessage
																object:[@"Connection has been refused by server for session "
																		stringByAppendingString:[self sessionName]]];
			NSRunAlertPanel(@"Error while connecting", @"Connection has been rejected by the server." , @"Ok", nil, nil);
		}		
		else if ([checkPort evaluateWithObject:outputContent] == YES)
		{
			[[NSNotificationCenter defaultCenter]  removeObserver:self name:NSFileHandleReadCompletionNotification object:[stdOut fileHandleForReading]];
			
			[self setConnected:NO];
			[self setConnectionInProgress:NO];
			[self setConnectionLink:@""];
			[sshTask terminate];
			[[NSNotificationCenter defaultCenter] postNotificationName:AMNewErrorMessage
																object:[@"Wrong server port for session " 
																		stringByAppendingString:[self sessionName]]];
			NSRunAlertPanel(@"Error while connecting", @"The port is already in used on server." , @"Ok", nil, nil);
		}
		else if ([checkConnected evaluateWithObject:outputContent] == YES)
		{
			[[NSNotificationCenter defaultCenter]  removeObserver:self name:NSFileHandleReadCompletionNotification  object:[stdOut fileHandleForReading]];
			
			[self setConnected:YES];
			[self setConnectionInProgress:NO];
			[[NSNotificationCenter defaultCenter] postNotificationName:AMNewGeneralMessage
																object:[@"Sucessfully connects session "
																		stringByAppendingString:[self sessionName]]];
			
			[self setConnectionLink:[@"127.0.0.1:" stringByAppendingString:[portsMap serviceLocalPorts]]];
			
		}
		else
			[[stdOut fileHandleForReading] readInBackgroundAndNotify];
	}
}
@end
