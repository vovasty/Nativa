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
	int _port;
	id<TorrentController> _process;
	RTConnection* _connection;
	NSString* _downloadsFolder;
	
	NSString* _connectionType;
	NSString* _sshHost;
	NSString* _sshPort;
	NSString* _sshUsername;
	NSString* _sshPassword;
	NSString* _sshLocalPort;
	VoidResponseBlock openProcessResponse;
	int _maxReconnects;
}
@property (retain) NSString* name;
@property (retain) NSString* processType;
@property (retain) NSString* host;
@property (retain) NSString* downloadsFolder;
@property (assign) int port;

@property (retain) NSString* connectionType;
@property (retain) NSString* sshHost;
@property (retain) NSString* sshPort;
@property (retain) NSString* sshUsername;
@property (retain) NSString* sshPassword;
@property (retain) NSString* sshLocalPort;

@property (retain) id<TorrentController> process;
@property (retain) RTConnection* connection;
@property (assign) int maxReconnects;


-(void) closeProcess;
-(void) openProcess:(VoidResponseBlock) response;
@end
