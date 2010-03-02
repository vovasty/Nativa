//
//  RTorrentController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 30.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TorrentDelegate.h"

@class RTConnection;

@interface RTorrentController : NSObject<TorrentController>
{
	NSOperationQueue* _queue;
	RTConnection* _connection;
}
@property (readonly) NSOperationQueue* queue;
@property (readonly) RTConnection* connection;
- (id)initWithConnection:(RTConnection*) conn;

@end
