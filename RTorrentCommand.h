//
//  RTorrentCommand.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void(^VoidResponseBlock)(void);
typedef void(^ArrayResponseBlock)(NSArray *);

@protocol RTorrentCommand<NSObject>

- (void) processResponse:(id) data;

- (NSString *) command;

- (NSArray *) arguments;

- (void) setError: (NSString*) error;

- (NSString*) error;
@end