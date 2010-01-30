//
//  SetGlobalDownloadSpeed.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 28.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "SetGlobalDownloadSpeedLimit.h"


@implementation SetGlobalDownloadSpeedLimit
@synthesize speed = _speed;
@synthesize response = _response;

- (id)initWithSpeedAndResponse:(int)speed response:(VoidResponseBlock) resp;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _speed = speed;
    _response = [resp retain];
    return self;
}

- (void) processResponse:(id) data error:(NSString *) error;
{
	if (_response)
		_response(error);
}

- (NSString *) command;
{
	return @"set_download_rate";
}

- (NSArray *) arguments;
{
	return [NSArray arrayWithObjects:
			[NSNumber numberWithInt:_speed], 
			nil];
}

- (void)dealloc
{
	[_response release];
	[super dealloc];
}
@end
