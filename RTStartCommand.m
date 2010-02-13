//
//  StartCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "RTStartCommand.h"


@implementation RTStartCommand
@synthesize thash = _thash;
@synthesize response = _response;

- (id)initWithHashAndResponse:(NSString *)hash response:(VoidResponseBlock) resp;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _thash = [hash retain];
    _response = [resp retain];
    return self;
}

- (void) processResponse:(id) data error:(NSString *) error
{
	if (_response)
		_response(error);
}

- (NSString *) command;
{
	return @"d.start";
}

- (NSArray *) arguments;
{
	return [NSArray arrayWithObjects:
			_thash, 
			nil];
}

- (void)dealloc
{
	[_response release];
	[_thash release];
	[super dealloc];
}

@end
