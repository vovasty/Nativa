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
#import "RTAddCommand.h"
#import "RTListCommand.h"

static NSString * ConnectingContext = @"ConnectingContext";
static NSString * ConnectedContext = @"ConnectingContext";

@interface RTorrentController(Private)
-(void)_runOperation:(id<RTorrentCommand>) operation;
-(void)_runCommand:(NSString*) command arguments:(NSArray*)arguments response:(SCGIOperationResponseBlock) response;
-(SCGIOperationResponseBlock)_voidResponse:(VoidResponseBlock) response;
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
	[self _runOperation: command];
	[command release];
}

- (void) start:(NSString *)hash response:(VoidResponseBlock) response;
{
	SCGIOperationResponseBlock r = [self _voidResponse:response];
	[self _runCommand:@"d.start"
			 arguments:[NSArray arrayWithObjects:
						hash, 
						nil]
			  response:r];
	[r release];
}

- (void) stop:(NSString *)hash response:(VoidResponseBlock) response;
{
	
	SCGIOperationResponseBlock r = [self _voidResponse:response];
	[self _runCommand:@"d.stop"
			 arguments:[NSArray arrayWithObjects:
						hash, 
						nil]
			  response:r];
	[r release];
}

- (void) add:(NSURL *) torrentUrl start:(BOOL) start response:(VoidResponseBlock) response;
{
	RTAddCommand* command = [[RTAddCommand  alloc] initWithUrlAndResponse:torrentUrl start:start response:response];
	[self _runOperation: command];
	[command release];
}

- (void) erase:(NSString *)hash response:(VoidResponseBlock) response;
{
	SCGIOperationResponseBlock r = [self _voidResponse:response];
	[self _runCommand:@"d.erase"
			arguments:[NSArray arrayWithObjects:
					   hash, 
					   nil]
			 response:r];
	[r release];
}

- (void) setGlobalDownloadSpeedLimit:(int) speed response:(VoidResponseBlock) response;
{
	SCGIOperationResponseBlock r = [self _voidResponse:response];
	[self _runCommand:@"set_download_rate"
			arguments:[NSArray arrayWithObjects:
					   [NSNumber numberWithInt:speed],
					   nil]
			 response:r];
	[r release];
}

- (void) setGlobalUploadSpeedLimit:(int) speed response:(VoidResponseBlock) response;
{
	SCGIOperationResponseBlock r = [self _voidResponse:response];
	[self _runCommand:@"set_upload_rate"
			arguments:[NSArray arrayWithObjects:
					   [NSNumber numberWithInt:speed],
					   nil]
			 response:r];
	[r release];
}

- (void) getGlobalDownloadSpeedLimit:(NumberResponseBlock) response
{
	SCGIOperationResponseBlock r = [^(id data, NSString* error){
		if (response)
			response(data, error);
	}copy];
	[self _runCommand:@"get_download_rate"
			arguments:nil
			 response:r];
	[r release];
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
	
	SCGIOperationResponseBlock r = [self _voidResponse:response];
	[self _runCommand:@"d.set_priority"
			arguments:[NSArray arrayWithObjects:
					   [torrent thash],
					   [NSNumber numberWithInteger:pr], 
					   nil]
			 response:r];
	[r release];
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
-(void)_runOperation:(id<RTorrentCommand>) operation
{
	RTSCGIOperation* scgiOperation = [[RTSCGIOperation alloc] initWithOperation:_connection operation:operation];
	[_queue addOperation:scgiOperation];
	[scgiOperation release];
}

-(void)_runCommand:(NSString*) command arguments:(NSArray*)arguments response:(SCGIOperationResponseBlock) response
{
	RTSCGIOperation* scgiOperation = [[RTSCGIOperation alloc] initWithCommand:_connection command:command arguments:arguments response:response];
	[_queue addOperation:scgiOperation];
	[scgiOperation release];
}

-(SCGIOperationResponseBlock)_voidResponse:(VoidResponseBlock) response
{
	return [^(id data, NSString* error){
		if (response)
			response(error);
	}copy];
}
@end