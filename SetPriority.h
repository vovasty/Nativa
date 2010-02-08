//
//  SetPriority.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 08.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

@interface SetPriority : NSObject<RTorrentCommand>
{
	VoidResponseBlock _response;
	NSString* _thash;
	NSInteger _priority;
}
@property (retain) VoidResponseBlock response;
@property (retain) NSString* thash;
@property (assign) NSInteger priority;

- (id)initWithHashAnsPriority:(NSString*) hash priority:(NSInteger)priority response:(VoidResponseBlock) resp;

@end
