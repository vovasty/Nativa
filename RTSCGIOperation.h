//
//  SCGICommand.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

typedef void(^SCGIOperationResponseBlock)(id data, NSString* error);

@class RTConnection;

@interface RTSCGIOperation : NSOperation<NSStreamDelegate> 
{
	RTConnection*				_connection;

	NSOutputStream*				oStream;
	
	NSInputStream*				iStream;

	NSMutableData*				responseData;
	
	BOOL						_carriageReturn;
	
	BOOL						_headers_not_found;
	
	NSString					*_command;
	
	NSArray						*_arguments;
	
	SCGIOperationResponseBlock	_response;
	
    BOOL						_isExecuting;
	
	NSAutoreleasePool			*pool;
	
	id<RTorrentCommand>         _operation;
}

- (id)initWithCommand:(RTConnection *) conn command:(NSString*)command arguments:(NSArray*)arguments response:(SCGIOperationResponseBlock) response;

- (id)initWithOperation:(RTConnection *) conn operation:(id<RTorrentCommand>) operation;

@end
