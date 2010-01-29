//
//  AddCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "AddCommand.h"


@implementation AddCommand
@synthesize url = _url;
@synthesize response = _response;
@synthesize start = _start;

- (id)initWithUrlAndResponse:(NSURL *)url response:(VoidResponseBlock) resp;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _url = [url copy];
    _response = [resp copy];
    return self;
}


- (void) processResponse:(id) data error:(NSString *) error;
{
	if (_response)
		_response(error);
}

- (NSString *) command;
{
	return _start ? @"load_raw_start" : @"load_raw";
}

- (NSArray *) arguments;
{
	if (_arguments == nil)
	{
		NSURLRequest* request = [NSURLRequest requestWithURL:_url];
		NSURLResponse *returningResponse = nil;
		NSError* connError = nil;
		NSData *content = [NSURLConnection sendSynchronousRequest:request returningResponse:&returningResponse error:&connError];
		NSLog(@"oops! %@", connError);
		//	NSLog(@"%Q", returningResponse);
		_arguments = [NSArray arrayWithObjects:content, nil];
		[_arguments retain];
	}
	return _arguments;
}

- (void)dealloc
{
	[_response release];
	[_url release];
	[_arguments release];
	[super dealloc];
}
@end
