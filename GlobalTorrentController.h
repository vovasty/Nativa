//
//  GlobalTorrentController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TorrentDelegate.h"

@interface GlobalTorrentController : NSObject 
{
	id<TorrentController> rtorrent;
}

+ (GlobalTorrentController *)sharedGlobalTorrentController;

@property (readonly) id<TorrentController> defaultRTorrent;

@end