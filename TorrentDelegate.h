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

- (void) add:(NSString *) torrentUrl response:(VoidResponseBlock) response;

- (void) erase:(NSString *) hash response:(VoidResponseBlock) response;

- (id<RTorrentCommand>) errorCommand;
@end

