//
//  GlobalTorrentController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SynthesizeSingleton.h"

@class TorrentController;

@interface GlobalTorrentController : NSObject 
{
	TorrentController* rtorrent;
}

+ (GlobalTorrentController *)sharedGlobalTorrentController;
@property (readonly) TorrentController* defaultRTorrent;
@end