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
	
	id<TorrentControllerDelegate> _delegate;
	
	NSAutoreleasePool *pool;
}

- (id)initWithConnection:(RTConnection *) conn;

@property (retain) id<RTorrentCommand> command;

@property (assign) id<TorrentControllerDelegate> delegate;

@property (assign) RTConnection* connection;

@end
