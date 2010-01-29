//
//  RTorrentController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 30.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "RTorrentController.h"
#import "RTConnection.h"
#import "SCGIOperation.h"
#import "ListCommand.h"
#import "StartCommand.h"
#import "StopCommand.h"
#import "AddCommand.h"
#import "EraseCommand.h"
#import "RTorrentCommand.h"
#import "TorrentDelegate.h"
#import "SetGlobalDownloadSpeed.h"


static NSString * OperationsChangedContext = @"OperationsChangedContext";

@implementation RTorrentController

@synthesize connection = _connection;
@synthesize queue = _queue;
@synthesize working = _working;

- (id)initWithConnection:(RTConnection*) conn;
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_connection = conn;
	[_connection retain];
	_queue = [[NSOperationQueue alloc] init];
	[_queue retain];
	[_queue setMaxConcurrentOperationCount:1];
	
	[_queue addObserver:self
			forKeyPath:@"operations"
			options:0
			context:&OperationsChangedContext];
	
	return self;
}

-(void)dealloc;
{
	[_connection release];
	[_queue release];
	[_errorCommand release];
	[super dealloc];
}

- (void) list:(ArrayResponseBlock) response;
{
	SCGIOperation* operation = [[SCGIOperation alloc] initWithConnection:_connection];
	ListCommand* command = [[ListCommand alloc] init];
	operation.command = command;
	operation.delegate = self;
	command.response = response;
	[_queue addOperation:operation];
	[command release];
	[operation release];
}

- (void) start:(NSString *)hash response:(VoidResponseBlock) response;
{
	SCGIOperation* operation = [[SCGIOperation alloc] initWithConnection:_connection];
	StartCommand* command = [[StartCommand alloc] initWithHashAndResponse:hash response:response];
	operation.command = command;
	operation.delegate = self;
	[_queue addOperation:operation];
	[command release];
	[operation release];
}

- (void) stop:(NSString *)hash response:(VoidResponseBlock) response;
{
	SCGIOperation* operation = [[SCGIOperation alloc] initWithConnection:_connection];
	StopCommand* command = [[StopCommand  alloc] initWithHashAndResponse:hash response:response];
	operation.command = command;
	operation.delegate = self;
	[_queue addOperation:operation];
	[command release];
	[operation release];
}

- (void) add:(NSString *) torrentUrl response:(VoidResponseBlock) response;
{
	SCGIOperation* operation = [[SCGIOperation alloc] initWithConnection:_connection];
	AddCommand* command = [[AddCommand  alloc] initWithHashAndResponse:torrentUrl response:response];
	[command retain];
	operation.command = command;
	operation.delegate = self;
	[_queue addOperation:operation];
	[command release];
	[operation release];
}

- (void) erase:(NSString *)hash response:(VoidResponseBlock) response;
{
	SCGIOperation* operation = [[SCGIOperation alloc] initWithConnection:_connection];
	EraseCommand* command = [[EraseCommand  alloc] initWithHashAndResponse:hash response:response];
	operation.command = command;
	operation.delegate = self;
	[_queue addOperation:operation];
	[command release];
	[operation release];
}
- (void) setGlobalDownloadSpeed:(int) speed response:(VoidResponseBlock) response;
{
	SCGIOperation* operation = [[SCGIOperation alloc] initWithConnection:_connection];
	SetGlobalDownloadSpeed* command = [[SetGlobalDownloadSpeed alloc] initWithSpeedAndResponse:speed response:response];
	operation.command = command;
	operation.delegate = self;
	[_queue addOperation:operation];
	[command release];
	[operation release];
	
}

- (void) setError:(id<RTorrentCommand>) ec;
{
	if (ec != _errorCommand)
	{
		[_errorCommand release];
		_errorCommand = [ec retain];
	}
}

- (id<RTorrentCommand>) errorCommand;
{
	return _errorCommand;
}

-(void)setWorking:(BOOL) flag;
{
	_working = flag;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &OperationsChangedContext)
    {
        [self setWorking:[[_queue operations] count]>0];
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
@end

