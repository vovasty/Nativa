//
//  SCGICommand.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"
#import "TorrentDelegate.h"

@class RTConnection;

@interface SCGIOperation : NSOperation<NSStreamDelegate> 
{
	RTConnection* _connection;

	NSOutputStream* oStream;
	NSInputStream* iStream;

	NSMutableData* responseData;
	
	BOOL _carriageReturn;
	BOOL _headers_not_found;
	
	id<RTorrentCommand> _command;
	
    BOOL _isExecuting;
    BOOL _isFinished;
	
	id<TorrentControllerDelegate> _delegate;
	
	NSAutoreleasePool *pool;
}

- (id)initWithConnection:(RTConnection *) conn;

- (void)start;

@property (retain) id<RTorrentCommand> command;

@property (retain) id<TorrentControllerDelegate> delegate;

@property (retain) RTConnection* connection;

@property (readonly) BOOL isExecuting;
@property (readonly) BOOL isFinished;

@end
