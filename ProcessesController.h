//
//  ProcessesController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 03.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TorrentController.h"

@class ProcessDescriptor;

@interface ProcessesController : NSObject 
{
	NSMutableArray *_processes;
}
+ (ProcessesController *)sharedProcessesController;


-(NSInteger) count;

-(void) setName:(NSString *)name forIndex:(NSInteger) index;
-(NSString *) nameForIndex:(NSInteger) index;

-(void) setProcessType:(NSString *)type forIndex:(NSInteger) index;
-(NSString *) processTypeForIndex:(NSInteger) index;

-(void) setConnectionType:(NSString *)type forIndex:(NSInteger) index;
-(NSString *) connectionTypeForIndex:(NSInteger) index;

-(void) setHost:(NSString *)host forIndex:(NSInteger) index;
-(NSString *) hostForIndex:(NSInteger) index;

-(void) setPort:(NSInteger)port forIndex:(NSInteger) index;
-(NSInteger) portForIndex:(NSInteger) index;

-(void) setLocalDownloadsFolder:(NSString *)folder forIndex:(NSInteger) index;
-(NSString *) localDownloadsFolderForIndex:(NSInteger) index;

-(void) setSshHost:(NSString *)host forIndex:(NSInteger) index;
-(NSString *) sshHostForIndex:(NSInteger) index;

-(void) setSshPort:(NSInteger)port forIndex:(NSInteger) index;
-(NSInteger) sshPortForIndex:(NSInteger) index;

-(void) setSshLocalPort:(NSInteger)port forIndex:(NSInteger) index;
-(NSInteger) sshLocalPortForIndex:(NSInteger) index;

-(void) setSshUser:(NSString *)user forIndex:(NSInteger) index;
-(NSString *) sshUserForIndex:(NSInteger) index;

-(void) setSshPassword:(NSString *)password forIndex:(NSInteger) index;
-(NSString *) sshPasswordForIndex:(NSInteger) index;

-(void) setMaxReconnects:(NSInteger)maxReconnects forIndex:(NSInteger) index;
-(NSInteger) maxReconnectsForIndex:(NSInteger) index;

-(void) setGroupsField:(NSUInteger)groupsField forIndex:(NSInteger) index;
-(NSUInteger) groupsFieldForIndex:(NSInteger) index;

- (NSInteger) indexForRow: (NSInteger) row;

-(NSInteger) addProcess;

-(void)saveProcesses;

-(void) openProcess:(void (^)(NSString *error)) handler forIndex:(NSInteger) index;

-(void) closeProcessForIndex:(NSInteger) index;

-(id<TorrentController>) processForIndex:(NSInteger) index;
@end
