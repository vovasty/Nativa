//
//  StartCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "StartCommand.h"


@implementation StartCommand
@synthesize thash = _thash;
@synthesize response = _response;
@synthesize error = _error;

+ (id)command:(NSString *)hash response:(VoidResponseBlock) resp;
{
	StartCommand * operation = [[self alloc] initWithHashAndResponse:hash response:resp];
    return [operation autorelease];
}


- (id)initWithHashAndResponse:(NSString *)hash response:(VoidResponseBlock) resp;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _thash = [hash retain];
    _response = [resp retain];
    return self;
}

- (void) processResponse:(id) data;
{
	_response();
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
	[_error release];
	[super dealloc];
}


-(void) setError:(NSString *)err;
{
	self.error = err;
}
@end
