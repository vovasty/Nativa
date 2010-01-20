//
//  ListCommand.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

@interface ListCommand : NSObject<RTorrentCommand>
{
	ArrayResponseBlock _response;
	NSString *_error;
}
@property (retain) ArrayResponseBlock response;
@property (retain) NSString *error;
@end
