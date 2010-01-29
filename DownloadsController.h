//
//  DownloadsController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TorrentDelegate.h"

extern NSString* const NINotifyUpdateDownloads;

@class RTorrentController;

@interface DownloadsController : NSObject {
@private
	NSMutableArray* _downloads;
	NSTimer* _timer;
	RTorrentController* _rtorrent;
}

+ (DownloadsController *)sharedDownloadsController;

-(void) startUpdates;

-(void) stopUpdates;

-(NSArray*) downloads;

- (void) start:(NSString *) hash response:(VoidResponseBlock) response;

- (void) stop:(NSString *) hash response:(VoidResponseBlock) response;

- (void) add:(NSString *) torrentUrl response:(VoidResponseBlock) response;

- (void) erase:(NSString *) hash response:(VoidResponseBlock) response;

- (void) setGlobalDownloadSpeed:(int) speed response:(VoidResponseBlock) response;

- (void) getGlobalDownloadSpeed:(NumberResponseBlock) response;

@end

