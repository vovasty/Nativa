//
//  RTConnection.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "RTConnection.h"


@implementation RTConnection

- (id)initWithHostPort:(NSString *)initHost port:(int)initPort;
{
	hostName = [[NSString stringWithString:initHost] retain];
	port = initPort;
	return self;
}


- (void) openStreams:(NSInputStream **)iStream oStream:(NSOutputStream **) oStream delegate:(id) delegate;
{
	NSHost *host = [NSHost hostWithAddress:hostName];
	if (host != nil)
	{
		[NSStream getStreamsToHost:host port:port inputStream:iStream
					  outputStream:oStream];
		
		[(*iStream) scheduleInRunLoop:[NSRunLoop currentRunLoop]
						   forMode:NSDefaultRunLoopMode];
		(*iStream).delegate = delegate;
		
		[(*oStream) scheduleInRunLoop:[NSRunLoop currentRunLoop]
						   forMode:NSDefaultRunLoopMode];
		(*oStream).delegate = delegate;
		
		[(*oStream) open];
		[(*iStream) open];
	}
}

-(void)dealloc;
{
	[hostName release];
	[super dealloc];
}
@end
