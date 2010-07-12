/******************************************************************************
 * Nativa - MacOS X UI for rtorrent
 * http://www.aramzamzam.net
 *
 * Copyright Solomenchuk V. 2010.
 * Solomenchuk Vladimir <vovasty@aramzamzam.net>
 *
 * Licensed under the GPL, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.gnu.org/licenses/gpl-3.0.html
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************/

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


- (BOOL) openStreams:(NSInputStream **)iStream oStream:(NSOutputStream **) oStream delegate:(id) delegate error:(NSString **) error
{
	if (!_connected)
    {
		*error = [NSString stringWithString:@"Not connected"];
        return NO;
    }
	NSHost *host = [NSHost hostWithAddress:hostName];
	if (host != nil)
	{
		[NSStream getStreamsToHost:host 
							  port:(_proxy==nil?port:[_proxy localPort]) 
						inputStream:iStream
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
    *error = [NSString stringWithFormat:@"Unable to resolve host: %@",hostName];
	return NO;
}

-(void) closeConnection
{
    if (_proxy == nil) 
    {
        [self willChangeValueForKey:@"connecting"];
        [self willChangeValueForKey:@"connected"];
        _connected = NO;
        _connecting = NO;
        [self didChangeValueForKey:@"connecting"];
        [self didChangeValueForKey:@"connected"];
    }
    else
        [_proxy closeTunnel];
}

-(void) openConnection:(void (^)(RTConnection *sender))handler
{
	if (_proxy == nil)
	{
		[self willChangeValueForKey:@"connecting"];
		[self willChangeValueForKey:@"connected"];
		_connected = YES;
		_connecting = NO;
		[self didChangeValueForKey:@"connecting"];
		[self didChangeValueForKey:@"connected"];
        if (handler != nil) 
            handler(self);
	}
	else
	{
		[self willChangeValueForKey:@"connecting"];
		_connected = NO;
		_connecting = YES;
		[self didChangeValueForKey:@"connecting"];
		[_proxy openTunnel:^(AMSession *sender){
            if (handler != nil) 
                handler(self);
        }];
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
