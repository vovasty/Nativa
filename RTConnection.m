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

@synthesize connected = _connected;
@synthesize connecting = _connecting;

- (id)initWithHostPort:(NSString *)initHost port:(int)initPort proxy:(AMSession*) proxy;
{
	hostName = [[NSString stringWithString:initHost] retain];
	port = initPort;
	_connecting = NO;
	_connected = NO;
	if (proxy)
	{
		_proxy = [proxy retain];
		
		//watch proxy closing
		[_proxy addObserver:self
				forKeyPath:@"connected"
				options:0
				context:&ProxyConnectedContext];
		
	}
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
	[self willChangeValueForKey:@"connecting"];
	[self willChangeValueForKey:@"connected"];
	_connected = NO;
	_connecting = NO;
	[self didChangeValueForKey:@"connecting"];
	[self didChangeValueForKey:@"connected"];
	[_proxy closeTunnel];
}

-(void) openConnection
{
	if (_proxy == nil)
	{
		[self willChangeValueForKey:@"connecting"];
		[self willChangeValueForKey:@"connected"];
		_connected = YES;
		_connecting = NO;
		[self didChangeValueForKey:@"connecting"];
		[self didChangeValueForKey:@"connected"];
	}
	else
	{
		[self willChangeValueForKey:@"connecting"];
		_connected = NO;
		_connecting = YES;
		[self didChangeValueForKey:@"connecting"];
		[_proxy openTunnel];
	}
}

-(NSString*) error
{
	return _proxy == nil?nil:[_proxy error];
}

-(void)dealloc;
{
	[hostName release];
	[_proxy removeObserver:self forKeyPath:@"connected"];
	[_proxy release];
	[super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &ProxyConnectedContext)
    {
		[self willChangeValueForKey:@"connecting"];
		[self willChangeValueForKey:@"connected"];
		_connected = _proxy.connected;
		_connecting =_proxy.connectionInProgress;
		[self didChangeValueForKey:@"connecting"];
		[self didChangeValueForKey:@"connected"];
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
