//Copyright (C) 2008  Antoine Mercadal
//
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#import <Foundation/Foundation.h>
#import <SecurityFoundation/SFAuthorization.h>

#import "AMServer.h";
#import "AMService.h";

extern	NSString const *AMErrorLoadingSavedState;
extern	NSString const *AMNewGeneralMessage;
extern	NSString const *AMNewErrorMessage;



@interface AMSession : NSObject <NSCoding> 
{
	AMServer 		*currentServer;
	AMService		*portsMap;	
	NSUInteger		autoReconnectTimes;
	BOOL			connected;
	BOOL			connectionInProgress;
	NSPipe 			*stdOut;
	NSString 		*connectionLink;
	NSMutableString *outputContent;
	NSString 		*zzz;
	NSString 		*remoteHost;
	NSString 		*sessionName;
	NSTask			*sshTask;
	
	SFAuthorization *auth;


}
@property(readwrite)			BOOL				connected;
@property(readwrite)			BOOL				connectionInProgress;
@property(readwrite, retain)	AMServer 			*currentServer;
@property(readwrite, retain)	AMService 			*portsMap;
@property(readwrite, retain)	NSString 			*connectionLink;
@property(readwrite, retain)	NSString 			*remoteHost;
@property(readwrite, retain)	NSString 			*sessionName;


- (void) prepareAuthorization;

#pragma mark -
#pragma mark Control methods
- (void) closeTunnel;
- (void) openTunnel;

#pragma mark -
#pragma mark Observers and delegates
- (void) handleProcessusExecution:(NSNotification *) notification;
- (void) listernerForSSHTunnelDown:(NSNotification *)notification;

#pragma mark -
#pragma mark Helper methods
- (NSMutableArray *) parsePortsSequence:(NSString*)seq;
- (NSMutableString *) prepareSSHCommandWithRemotePorts:(NSMutableArray *)remotePorts localPorts:(NSMutableArray *)localPorts;


@end