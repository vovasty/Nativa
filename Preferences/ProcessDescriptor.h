//
//  ProcessDescriptor.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 03.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TorrentDelegate.h"

@interface ProcessDescriptor : NSObject <NSCoding>
{
	NSString* _name;
	NSString* _processType;
	BOOL _manualConfig;
	NSString* _host;
	int _port;
	id<TorrentController> _process;
	
}
@property (retain) NSString* name;
@property (retain) NSString* processType;
@property (assign) BOOL manualConfig;
@property (retain) NSString* host;
@property (assign) int port;

-(id<TorrentController>) process;
@end
