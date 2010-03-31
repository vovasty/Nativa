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

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

typedef void(^SCGIOperationResponseBlock)(id data, NSString* error);

@class RTConnection;

@interface RTSCGIOperation : NSOperation<NSStreamDelegate> 
{
	RTConnection*				_connection;

	NSOutputStream*				oStream;
	
	NSInputStream*				iStream;

	NSMutableData*				_responseData;
	
	NSString					*_command;
	
	NSArray						*_arguments;
	
	SCGIOperationResponseBlock	_response;
	
    BOOL						_isExecuting;
	
	NSAutoreleasePool			*pool;
	
	id<RTorrentCommand>         _operation;
	
	NSData						*_requestData;

	NSInteger					_writtenBytesCounter;
}

- (id)initWithCommand:(RTConnection *) conn command:(NSString*)command arguments:(NSArray*)arguments response:(SCGIOperationResponseBlock) response;

- (id)initWithOperation:(RTConnection *) conn operation:(id<RTorrentCommand>) operation;

@end
