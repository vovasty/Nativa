//
//  AddCommand.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

@interface RTAddCommand : NSObject<RTorrentCommand>
{
	VoidResponseBlock _response;
	NSURL* _url;
	BOOL _start;
	NSArray* _arguments;
}
@property (assign)BOOL start;
@property (readonly, retain) NSURL * url;
@property (readonly, retain) VoidResponseBlock response;
- (id)initWithUrlAndResponse:(NSURL *)url response:(VoidResponseBlock) resp;
@end
