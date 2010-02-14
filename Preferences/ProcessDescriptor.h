//
//  ProcessDescriptor.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 03.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TorrentDelegate.h"

@class AMSession;

@interface ProcessDescriptor : NSObject <NSCoding>
{
	NSString* _name;
	NSString* _processType;
	BOOL _manualConfig;
	NSString* _host;
	int _port;
	id<TorrentController> _process;
	NSString* _downloadsFolder;
	
	NSString* _connectionType;
	NSString* _sshHost;
	NSString* _sshPort;
	NSString* _sshUsername;
	NSString* _sshPassword;
	NSString* _sshLocalPort;
	AMSession* _proxy;
	
}
@property (retain) NSString* name;
@property (retain) NSString* processType;
@property (assign) BOOL manualConfig;
@property (retain) NSString* host;
@property (retain) NSString* downloadsFolder;
@property (assign) int port;

@property (retain) NSString* connectionType;
@property (retain) NSString* sshHost;
@property (retain) NSString* sshPort;
@property (retain) NSString* sshUsername;
@property (retain) NSString* sshPassword;
@property (retain) NSString* sshLocalPort;

-(id<TorrentController>) process;
-(void) closeProcess;
@end
