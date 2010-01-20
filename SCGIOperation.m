//
//  SCGICommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "SCGIOperation.h"
#import "RTConnection.h"
#import "XMLRPCEncoder.h"
#import "XMLRPCTreeBasedParser.h"
#import "SCGI.h"

@interface SCGIOperation ()
- (void) requestDidSent;

- (void) responseDidReceived;

- (void) setError:(NSString*) error;

- (void)finish;
@end


@implementation SCGIOperation

@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;

@synthesize command = _command;
@synthesize connection = _connection;
@synthesize delegate = _delegate;

- (id)initWithConnection:(RTConnection *) conn;
{
	self = [super init];
	if (self == nil)
		return nil;
	
	_connection = [conn retain];
	_isExecuting = NO;
	_isFinished = NO;
	return self;
}


- (void)start;
{
	//http://www.dribin.org/dave/blog/archives/2009/09/13/snowy_concurrent_operations/
	//run start on main thread
	if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
	NSLog(@"start");
	
	[self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
	
	_carriageReturn = FALSE;
	_headers_not_found = TRUE;

	oStream = nil;
	iStream = nil;
	[_connection openStreams:&iStream oStream:&oStream delegate:self];
	[iStream retain];
	[oStream retain];
//	
//	
//	NSHost *host = [NSHost hostWithAddress:@"127.0.0.1"];
//	if (host != nil)
//	{
//		[NSStream getStreamsToHost:host port:5000 inputStream:&iStream
//					  outputStream:&oStream];
//		
//		[iStream retain];
//		[iStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
//						   forMode:NSDefaultRunLoopMode];
//		iStream.delegate = self;
//		
//		[oStream retain];
//		[oStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
//						   forMode:NSDefaultRunLoopMode];
//		oStream.delegate = self;
//		
//		
//		[iStream open];
//		[oStream open];
//	}
}


- (void)dealloc
{
	[responseData release];
	[_command release];
	[_connection release];
	[super dealloc];
}

 
- (void) requestDidSent;
{
    if (oStream != nil) 
	{
		oStream.delegate = nil;
        [oStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [oStream close];
		[oStream release];
        oStream = nil;
    }
}

- (void) responseDidReceived;
{
    if (iStream != nil) 
	{
		iStream.delegate = nil;
        [iStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [iStream close];
		[iStream release];
        iStream = nil;
    }
}

- (void)finish;
{
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	_isExecuting = NO;
	_isFinished = YES;
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode 
{
	switch(eventCode) {
        case NSStreamEventHasSpaceAvailable:
        {
			if (stream == oStream)
			{
				XMLRPCEncoder* xmlrpc_request = [[XMLRPCEncoder alloc] init];
				[xmlrpc_request setMethod:[_command command] withParameters:[_command arguments]];

				NSString* scgi_req = [xmlrpc_request encode];
				
				[xmlrpc_request release];
				NSData* requestData = SCGIcreateRequest(scgi_req);
				
				NSUInteger len = [requestData length];
				uint8_t buf[len];
				[requestData getBytes:buf];
				NSInteger bytesWritten = [oStream write:buf maxLength:[requestData length]];
				[self requestDidSent];
				if (bytesWritten != len)
					[self setError:@"Network error"];
			}
            break;
        }
		case NSStreamEventHasBytesAvailable:
        {
			if(!responseData)
                responseData = [[NSMutableData data] retain];
            
            uint8_t buf[1024];
            unsigned int len = 0;
			unsigned int start = 0;
            len = [(NSInputStream *)stream read:buf maxLength:1024];
			if (len)
			{
				if (_headers_not_found)
				{
					for (int i=0;i<len;i++)
					{
						if (buf[i]=='\r') //skip single \r's
							continue;
						
						if (buf[i]=='\n')
						{
							if (_carriageReturn)
							{
								_headers_not_found = FALSE;
								_carriageReturn = TRUE;
								start = i+1;
								break;
							}
							else
								_carriageReturn = TRUE;
						}
						else
							_carriageReturn = FALSE;
					}
				}
				if (!_headers_not_found) // if headers are found, keep body only, otherwise skip it all
				{	
					uint8_t* buf2 = &buf[start];
					[responseData appendBytes:buf2 length:(len - start)];
				}
			}
			break;
		}
			
		case NSStreamEventEndEncountered:
        {
			[self responseDidReceived];
			XMLRPCTreeBasedParser* xmlrpcResponse = [[XMLRPCTreeBasedParser alloc] initWithData: responseData];
			id result = [xmlrpcResponse parse];
			if ([xmlrpcResponse isFault])
				[self setError:result];
			else
				[_command processResponse:result];
			[xmlrpcResponse release];
			[self finish];
            break;
        }
		case NSStreamEventErrorOccurred: 
		{
			[self setError:[[stream streamError] localizedDescription]];
			[self finish];
			break;
        }
    }
}

- (void) setError:(NSString*) error;
{
	[self requestDidSent];
	[self responseDidReceived];
	[_command setError:error];
	[_delegate setError:_command];
	[self finish];
}

@end
