//
//  GetGlobalDownloadSpeed.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 29.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "GetGlobalDownloadSpeedLimit.h"


@implementation GetGlobalDownloadSpeedLimit
@synthesize response = _response;

- (id)initWithResponse:(NumberResponseBlock) resp;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _response = [resp retain];
    return self;
}

- (void) processResponse:(id) data error:(NSString *) error;
{
	if (_response)
		_response(data, error);
}

- (NSString *) command;
{
	return @"get_download_rate";
}

- (NSArray *) arguments;
{
	return nil;
}

- (void)dealloc
{
	[_response release];
	[super dealloc];
}
@end
