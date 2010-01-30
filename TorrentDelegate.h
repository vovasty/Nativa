//
//  TorrentActions.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

@protocol TorrentControllerDelegate

- (void) setError:(id<RTorrentCommand>) _error;

@end

@protocol TorrentController

- (void) list:(ArrayResponseBlock) response;

- (void) start:(NSString *) hash response:(VoidResponseBlock) response;

- (void) stop:(NSString *) hash response:(VoidResponseBlock) response;

- (void) add:(NSURL *) torrentUrl response:(VoidResponseBlock) response;

- (void) erase:(NSString *) hash response:(VoidResponseBlock) response;

- (void) setGlobalDownloadSpeedLimit:(int) speed response:(VoidResponseBlock) response;

- (void) getGlobalDownloadSpeedLimit:(NumberResponseBlock) response;

- (void) getGlobalDownloadSpeed:(NumberResponseBlock) response;

- (void) getGlobalUploadSpeed:(NumberResponseBlock) response;

- (id<RTorrentCommand>) errorCommand;
@end

