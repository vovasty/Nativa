//
//  GlobalTorrentController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "GlobalTorrentController.h"
#import "RTConnection.h"
#import "RTorrentController.h"
#import "SynthesizeSingleton.h"

@implementation GlobalTorrentController
SYNTHESIZE_SINGLETON_FOR_CLASS(GlobalTorrentController);

@synthesize defaultRTorrent = _rtorrent;

-(id)init;
{
    self = [super init];
    if (self == nil)
        return nil;
	RTConnection *connection = [[[RTConnection alloc] initWithHostPort:@"192.168.1.206" port:5000] autorelease];
	_rtorrent = [[RTorrentController alloc] initWithConnection:connection];
	return self;
}
@end
