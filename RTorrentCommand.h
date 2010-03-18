//
//  RTorrentCommand.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void(^VoidResponseBlock)(NSString* error);
typedef void(^ArrayResponseBlock)(NSArray *array, NSString* error);
typedef void(^NumberResponseBlock)(NSNumber *number, NSString* error);

@protocol RTorrentCommand<NSObject>

- (void) processResponse:(id) data error:(NSString *) error;

- (NSString *) command;

- (NSArray *) arguments;

@end