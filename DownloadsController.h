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
	NSTimer* _updateListTimer;
	NSTimer* _updateGlobalsTimer;
	RTorrentController* _rtorrent;
	NSNumber* _globalUploadSpeed;
	NSNumber* _globalDownloadSpeed;
}
@property (retain)	NSNumber* globalUploadSpeed;
@property (retain)	NSNumber* globalDownloadSpeed;


+ (DownloadsController *)sharedDownloadsController;

-(void) startUpdates;

-(void) stopUpdates;

-(NSArray*) downloads;

- (void) start:(NSString *) hash response:(VoidResponseBlock) response;

- (void) stop:(NSString *) hash response:(VoidResponseBlock) response;

- (void) add:(NSArray *) filesNames;

- (void) erase:(NSString *) hash response:(VoidResponseBlock) response;

- (void) setGlobalDownloadSpeedLimit:(int) speed response:(VoidResponseBlock) response;

- (void) getGlobalDownloadSpeedLimit:(NumberResponseBlock) response;

@end

