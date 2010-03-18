//
//  ProcessDescriptor.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 03.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TorrentController.h"

@class AMSession, RTConnection;

@interface ProcessDescriptor : NSObject <NSCoding>
{
	NSString* _name;
	NSString* _processType;
	NSString* _host;
	NSUInteger _port;
	id<TorrentController> _process;
	RTConnection* _connection;
	NSString* _downloadsFolder;
	
	NSString* _connectionType;
	NSString* _sshHost;
	NSString* _sshPort;
	NSString* _sshUsername;
	NSString* _sshPassword;
	NSUInteger _sshLocalPort;
	VoidResponseBlock openProcessResponse;
	NSUInteger _maxReconnects;
}
@property (retain) NSString* name;
@property (retain) NSString* processType;
@property (retain) NSString* host;
@property (retain) NSString* downloadsFolder;
@property (assign) NSUInteger port;

@property (retain) NSString* connectionType;
@property (retain) NSString* sshHost;
@property (retain) NSString* sshPort;
@property (retain) NSString* sshUsername;
@property (retain) NSString* sshPassword;
@property (assign) NSUInteger sshLocalPort;

@property (retain) id<TorrentController> process;
@property (retain) RTConnection* connection;
@property (assign) NSUInteger maxReconnects;


-(void) closeProcess;
-(void) openProcess:(VoidResponseBlock) response;
@end
