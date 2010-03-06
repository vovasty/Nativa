//
//  TorrentActions.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"
#import "Torrent.h"

@protocol TorrentController<NSObject>

- (void) list:(ArrayResponseBlock) response;

- (void) start:(NSString *) hash response:(VoidResponseBlock) response;

- (void) stop:(NSString *) hash response:(VoidResponseBlock) response;

- (void) add:(NSURL *) torrentUrl start:(BOOL) start response:(VoidResponseBlock) response;

- (void) erase:(NSString *) hash response:(VoidResponseBlock) response;

- (void) setGlobalDownloadSpeedLimit:(int) speed response:(VoidResponseBlock) response;

- (void) setGlobalUploadSpeedLimit:(int) speed response:(VoidResponseBlock) response;

- (void) getGlobalDownloadSpeedLimit:(NumberResponseBlock) response;

- (void) setPriority:(Torrent *)torrent  priority:(TorrentPriority)priority response:(VoidResponseBlock) response;

-(BOOL) connected;

-(void) openConnection:(VoidResponseBlock) response;

-(void) closeConnection;
@end

