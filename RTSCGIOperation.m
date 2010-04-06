/******************************************************************************
 * Nativa - MacOS X UI for rtorrent
 * http://www.aramzamzam.net
 *
 * Copyright Solomenchuk V. 2010.
 * Solomenchuk Vladimir <vovasty@aramzamzam.net>
 *
 * Licensed under the GPL, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.gnu.org/licenses/gpl-3.0.html
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************/

#import "RTSCGIOperation.h"
#import "RTConnection.h"
#import "XMLRPCEncoder.h"
#import "XMLRPCTreeBasedParser.h"
#import "NSStringSCGIAdditions.h"

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
	
	oStream = nil;
	iStream = nil;
	
	XMLRPCEncoder* xmlrpc_request = [[XMLRPCEncoder alloc] init];
	[xmlrpc_request setMethod:[self command] withParameters:[self arguments]];
	
	NSString* scgi_req = [xmlrpc_request encode];
	
	[xmlrpc_request release];
	_writtenBytesCounter = 0;
//	NSLog(@"request: %@", scgi_req);
	_requestData = [scgi_req encodeSCGI];
	[_requestData retain];
	
	if ([_connection openStreams:&iStream oStream:&oStream delegate:self])
	{
		[iStream retain];
		[oStream retain];
		time_t startTime = time(NULL) * 1000;
		time_t timeout = 1000;
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
			if ((time(NULL) * 1000 - startTime)>timeout)
			{
				[self setError:NSLocalizedString(@"Network timeout", "Network -> error")];
				break;
			}
		} while (_isExecuting);
	
	}
	else
		[self setError:[_connection error]];

	[pool release];
    self.pool = nil;	
}


- (void)dealloc
{
	[_responseData release];
	[_command release];
	[_arguments release];
	[_response release];
	[_connection release];
	[_operation release];
	[_requestData release];
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
				uint8_t *readBytes = (uint8_t *)[_requestData bytes];
				readBytes += _writtenBytesCounter; // instance variable to move pointer
				int data_len = [_requestData length];
				unsigned int len = ((data_len - _writtenBytesCounter >= 1024) ?
									1024 : (data_len-_writtenBytesCounter));
				uint8_t buf[len];
				(void)memcpy(buf, readBytes, len);
				len = [oStream write:(const uint8_t *)buf maxLength:len];
				_writtenBytesCounter += len;
				
				if (_writtenBytesCounter == data_len)
					[self requestDidSent];
			}
            break;
        }
		case NSStreamEventHasBytesAvailable:
        {
			if ([_responseData length]>65536)
			{
				[self setError:@"Response too large to fit into memory"];
				return;
			}
			
			if(!_responseData)
                _responseData = [[NSMutableData data] retain];
            
			uint8_t buf[1024];
            NSInteger len = 0;
			
			len = [(NSInputStream *)stream read:buf maxLength:1024];
			
			if (len>0)
				[_responseData appendBytes:buf length:len];

			break;
		}
			
		case NSStreamEventEndEncountered:
        {
			[self responseDidReceived];
			NSInteger len = [_responseData length];
			NSInteger start = 0;
			uint8_t *buf = (uint8_t *)[_responseData bytes];
			BOOL carriageReturnFound = NO;
			BOOL headerDividerFound = NO;

			//look for \n\n or \r\n\r\n
			if (len)
			{
				for (int i=0;i<len;i++)
				{
					if (buf[i]=='\r') //skip single \r's
						continue;
						
					if (buf[i]=='\n')
					{
						if (carriageReturnFound)
							{
								carriageReturnFound = YES;
								headerDividerFound = YES;
								start = i+1;
								break;
							}
							else
								carriageReturnFound = YES;
						}
						else
							carriageReturnFound = NO;
				}
				if (!headerDividerFound || len <= start)
				{
					[self setError:NSLocalizedString(@"Invalid response", "Network -> error")];
					break;
				}
			}
			else
				[self setError:NSLocalizedString(@"Invalid response", "Network -> error")];
			
			NSData *body = [NSData dataWithBytes:(buf+start) length:(len-start)];
			XMLRPCTreeBasedParser* xmlrpcResponse = [[XMLRPCTreeBasedParser alloc] initWithData: body];
//			NSLog(@"%@", [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]);
			
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
