//
//  RTConnection.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 12.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RTConnection : NSObject 
{
	NSString* hostName;
	int port;
}
- (id)initWithHostPort:(NSString *)initHost port:(int)initPort;

- (void) openStreams:(NSInputStream **)iStream oStream:(NSOutputStream **) oStream delegate:(id) delegate;
@end
