//
//  RTConnection.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "RTConnection.h"
#import "AMSession.h"

static NSString* ProxyConnectedContext = @"ProxyConnectedContext";


@implementation RTConnection

- (id)initWithHostPort:(NSString *)initHost port:(int)initPort proxy:(AMSession*) proxy;
{
	hostName = [[NSString stringWithString:initHost] retain];
	port = initPort;
	if (proxy)
	{
		_connected = NO;

		_proxy = [proxy retain];
		
		//watch proxy closing
		[_proxy addObserver:self
				forKeyPath:@"connected"
				options:0
				context:&ProxyConnectedContext];
		
	}
	else 
		_connected = YES;

	return self;
}


- (BOOL) openStreams:(NSInputStream **)iStream oStream:(NSOutputStream **) oStream delegate:(id) delegate;
{
	if (!_connected)
		return NO;
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
		return YES;
	}
	return NO;
}

-(void) closeConnection
{
	_connected = NO;
	[_proxy closeTunnel];
}

-(void)dealloc;
{
	[hostName release];
	[_proxy removeObserver:self forKeyPath:ProxyConnectedContext];
	[super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &ProxyConnectedContext)
    {
		_connected = _proxy.connected;
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
@end
