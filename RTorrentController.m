//
//  RTorrentController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 30.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RTorrentController.h"
#import "RTConnection.h"
#import "RTSCGIOperation.h"
#import "RTListCommand.h"
#import "RTStartCommand.h"
#import "RTStopCommand.h"
#import "RTAddCommand.h"
#import "RTEraseCommand.h"
#import "RTorrentCommand.h"
#import "RTSetGlobalDownloadSpeedLimitCommand.h"
#import "RTGetGlobalDownloadSpeedLimitCommand.h"
#import "RTSetGlobalUploadSpeedLimitCommand.h"
#import "RTSetPriorityCommand.h"

static NSString * ConnectingContext = @"ConnectingContext";
static NSString * ConnectedContext = @"ConnectingContext";

@interface RTorrentController(Private)
-(void)_runCommand:(id<RTorrentCommand>) command;
@end

@implementation RTorrentController

- (id)initWithConnection:(RTConnection*) conn;
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_connection = [conn retain];

	_queue = [[NSOperationQueue alloc] init];
	[_queue setMaxConcurrentOperationCount:1];
	
	[_queue setSuspended:YES];
	
	[_connection addObserver:self
			 forKeyPath:@"connecting"
				options:0
				context:&ConnectingContext];
	
	[_connection addObserver:self
				  forKeyPath:@"connected"
					 options:0
					 context:&ConnectedContext];
	return self;
}

-(void)dealloc;
{
	[_queue release];
	[_connection removeObserver:self forKeyPath:@"connecting"];
	[_connection removeObserver:self forKeyPath:@"connected"];
	[_connection release];
	[super dealloc];
}

- (void) list:(ArrayResponseBlock) response;
{
	RTListCommand* command = [[RTListCommand alloc] initWithArrayResponse:response];
	[self _runCommand: command];
	[command release];
}

- (void) start:(NSString *)hash response:(VoidResponseBlock) response;
{
	RTStartCommand* command = [[RTStartCommand alloc] initWithHashAndResponse:hash response:response];
	[self _runCommand: command];
	[command release];
}

- (void) stop:(NSString *)hash response:(VoidResponseBlock) response;
{
	RTStopCommand* command = [[RTStopCommand  alloc] initWithHashAndResponse:hash response:response];
	[self _runCommand: command];
	[command release];
}

- (void) add:(NSURL *) torrentUrl start:(BOOL) start response:(VoidResponseBlock) response;
{
	RTAddCommand* command = [[RTAddCommand  alloc] initWithUrlAndResponse:torrentUrl start:start response:response];
	[self _runCommand: command];
	[command release];
}

- (void) erase:(NSString *)hash response:(VoidResponseBlock) response;
{
	RTEraseCommand* command = [[RTEraseCommand  alloc] initWithHashAndResponse:hash response:response];
	[self _runCommand: command];
	[command release];
}

- (void) setGlobalDownloadSpeedLimit:(int) speed response:(VoidResponseBlock) response;
{
	RTSetGlobalDownloadSpeedLimitCommand* command = [[RTSetGlobalDownloadSpeedLimitCommand alloc] initWithSpeedAndResponse:speed response:response];
	[self _runCommand: command];
	[command release];
}

- (void) setGlobalUploadSpeedLimit:(int) speed response:(VoidResponseBlock) response;
{
	RTSetGlobalUploadSpeedLimitCommand* command = [[RTSetGlobalUploadSpeedLimitCommand alloc] initWithSpeedAndResponse:speed response:response];
	[self _runCommand: command];
	[command release];
}

- (void) getGlobalDownloadSpeedLimit:(NumberResponseBlock) response
{
	RTGetGlobalDownloadSpeedLimitCommand* command = [[RTGetGlobalDownloadSpeedLimitCommand alloc] initWithResponse:response];
	[self _runCommand: command];
	[command release];
}


- (void) setPriority:(Torrent *)torrent  priority:(TorrentPriority)priority response:(VoidResponseBlock) response
{
	NSInteger pr;
	switch (priority) {
		case NITorrentPriorityLow:
			pr = 1;
			break;
		case NITorrentPriorityNormal:
			pr = 2;
			break;
		case NITorrentPriorityHigh:
			pr = 3;
			break;
		default:
			NSAssert1(NO, @"Unknown priority: %d", priority);
	}
	
	RTSetPriorityCommand* command = [[RTSetPriorityCommand alloc] initWithHashAnsPriority:torrent.thash priority:pr response:response];
	[self _runCommand: command];
	[command release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	if (context == &ConnectingContext)
    {
		[_queue setSuspended:_connection.connecting];
    }
	else if (context == &ConnectedContext)
    {
		if (_connectionResponse)
		{
			_connectionResponse([_connection error]);
			//we will call response only once
			[_connectionResponse release];
			_connectionResponse = nil;
		}
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

-(BOOL) connected
{
	return [_connection connected];
}

-(void) openConnection:(VoidResponseBlock) response;
{
	if (_connectionResponse != response)
		[_connectionResponse release];
	_connectionResponse = [response retain];
	[_connection openConnection];
}

-(void) closeConnection
{
	[_connection closeConnection];
}
@end

@implementation RTorrentController(Private)
-(void)_runCommand:(id<RTorrentCommand>) command
{
	RTSCGIOperation* operation = [[RTSCGIOperation alloc] initWithConnection:_connection];
	operation.command = command;
	[_queue addOperation:operation];
	[operation release];
}
@end