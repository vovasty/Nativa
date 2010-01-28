//
//  AddCommand.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

@interface AddCommand : NSObject<RTorrentCommand>
{
	VoidResponseBlock _response;
	NSString* _error;
	NSURL* _url;
	BOOL _start;
	NSArray* _arguments;
}
@property (assign)BOOL start;
@property (readonly, retain) NSURL * url;
@property (readonly, retain) VoidResponseBlock response;
@property (readwrite, retain) NSString* error;
+ (id)command:(NSString *)hash response:(VoidResponseBlock) resp;
- (id)initWithUrlAndResponse:(NSURL *)url response:(VoidResponseBlock) resp;
@end
