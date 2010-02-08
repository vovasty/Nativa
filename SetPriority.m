//
//  SetPriority.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 08.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "SetPriority.h"


@implementation SetPriority

@synthesize priority = _priority;
@synthesize response = _response;
@synthesize thash = _thash;

- (id)initWithHashAnsPriority:(NSString*) hash priority:(NSInteger)priority response:(VoidResponseBlock) resp;
{
    self = [super init];
    if (self == nil)
        return nil;
    self.thash = hash;
    _priority = priority;
    self.response = resp;
    return self;
}

- (void) processResponse:(id) data error:(NSString *) error;
{
	if (_response)
		_response(error);
}

- (NSString *) command;
{
	return @"d.set_priority";
}

- (NSArray *) arguments;
{
	return [NSArray arrayWithObjects:
			_thash,
			[NSNumber numberWithInteger:_priority], 
			nil];
}

- (void)dealloc
{
	[_response release];
	[_thash release];
	[super dealloc];
}
@end
