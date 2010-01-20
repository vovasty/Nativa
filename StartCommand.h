//
//  StartCommand.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

@interface StartCommand : NSObject<RTorrentCommand>
{
	VoidResponseBlock _response;
	NSString* _thash;
	NSString* _error;
}

@property (retain) VoidResponseBlock response;
@property (retain) NSString* thash;
@property (retain) NSString* error;
+ (id)command:(NSString *)hash response:(VoidResponseBlock) resp;
- (id)initWithHashAndResponse:(NSString *)hash response:(VoidResponseBlock) resp;
@end
