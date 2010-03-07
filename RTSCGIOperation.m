//
//  SCGICommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "RTSCGIOperation.h"
#import "RTConnection.h"
#import "XMLRPCEncoder.h"
#import "XMLRPCTreeBasedParser.h"
#import "SCGI.h"

@interface RTSCGIOperation ()
- (void) requestDidSent;

- (void) responseDidReceived;

- (void) setError:(NSString*) error;

- (void) finish;

- (void) runResponse:(NSData*) data error:(NSString*) error;

- (NSArray*) arguments;

- (NSString*) command;

@property (nonatomic, assign) NSAutoreleasePool *pool;
@end


@implementation RTSCGIOperation

@synthesize pool;

- (id)initWithCommand:(RTConnection *) conn command:(NSString*)command arguments:(NSArray*)arguments response:(SCGIOperationResponseBlock) response
{
	if (self = [super init])
	{
		_connection = [conn retain];
		   _command = [command retain];
		 _arguments = [arguments retain];
		  _response = [response retain];
	}
	return self;
	
}

- (id)initWithOperation:(RTConnection *) conn operation:(id<RTorrentCommand>) operation;
{
	if (self = [super init])
	{
		_connection = [conn retain];
		_operation  = [operation retain];
	}
	return self;
}

- (void)main;
{
	self.pool = [[NSAutoreleasePool alloc] init];
    _isExecuting = YES;
	
	_carriageReturn = FALSE;
	_headers_not_found = TRUE;

	oStream = nil;
	iStream = nil;
	if ([_connection openStreams:&iStream oStream:&oStream delegate:self])
	{
		[iStream retain];
		[oStream retain];
	
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		} while (_isExecuting);
	
	}
	else
		[self setError:[_connection error]];

	[pool release];
    self.pool = nil;	
}


- (void)dealloc
{
	[responseData release];
	[_command release];
	[_arguments release];
	[_response release];
	[_connection release];
	[_operation release];
	
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
	_isExecuting = NO;
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode 
{
	switch(eventCode) {
        case NSStreamEventHasSpaceAvailable:
        {
			if (stream == oStream)
			{
				XMLRPCEncoder* xmlrpc_request = [[XMLRPCEncoder alloc] init];
				[xmlrpc_request setMethod:[self command] withParameters:[self arguments]];

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
            NSInteger len = 0;
			NSInteger start = 0;
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
				if (_headers_not_found || len <= start)
				{
					[self setError:NSLocalizedString(@"Invalid response", "Network -> error")];
					break;
				}
				 //headers are found, keep body only, otherwise skip it all
				uint8_t* buf2 = &buf[start];
				[responseData appendBytes:buf2 length:(len - start)];
			}
			break;
		}
			
		case NSStreamEventEndEncountered:
        {
			[self responseDidReceived];
			XMLRPCTreeBasedParser* xmlrpcResponse = [[XMLRPCTreeBasedParser alloc] initWithData: responseData];
//			NSLog(@"%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
			
			id result = [xmlrpcResponse parse];
			
			if (result == nil)//empty response, occured with bad xml. network error?
			{
				[self setError:NSLocalizedString(@"Invalid response", "Network -> error")];
				return;
			}
			
			if ([xmlrpcResponse isFault])
				[self setError:result];
			else
				[self runResponse:result error:nil];
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
	[self runResponse:nil error:error];
	[self finish];
}

- (void) runResponse:(NSData*) data error:(NSString*) error
{
	if (_operation == nil && _response)
		_response(data, error);
	else
		[_operation processResponse:data error:error];
}

- (NSArray*) arguments
{
	return _operation==nil?_arguments:[_operation arguments];
}

- (NSString*) command
{
	return _operation==nil?_command:[_operation command];
}

@end
