/*
 * Nativa - MacOS X UI for rtorrent
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
 */

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
	NSUInteger _groupsField;
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
@property (assign) NSUInteger groupsField;


-(void) closeProcess;
-(void) openProcess:(VoidResponseBlock) response;
@end
