//
//  DownloadsController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TorrentController.h"
#import "Torrent.h"

extern NSString* const NINotifyUpdateDownloads;

@class RTorrentController, Torrent;

@interface DownloadsController : NSObject 
{
@private
	NSMutableArray	* _downloads;
	NSTimer			* _updateListTimer;
	NSTimer			* _updateGlobalsTimer;
	CGFloat			  _globalUploadSpeed;
	CGFloat			  _globalDownloadSpeed;
	CGFloat			  _spaceLeft;
	NSUserDefaults	* _defaults;
	int				openedProcesses;
	NSString		* lastOpenProcessError;
}
@property (assign)	CGFloat globalUploadSpeed;
@property (assign)	CGFloat globalDownloadSpeed;
@property (assign)	CGFloat spaceLeft;


+ (DownloadsController *)sharedDownloadsController;

-(void) startUpdates:(VoidResponseBlock) response;

-(void) stopUpdates;

-(NSArray*) downloads;

- (void) start:(NSString *) hash response:(VoidResponseBlock) response;

- (void) stop:(NSString *) hash response:(VoidResponseBlock) response;

- (void) add:(NSArray *) filesNames;

- (void) erase:(Torrent *) torrent response:(VoidResponseBlock) response;

- (void) setGlobalDownloadSpeedLimit:(int) speed response:(VoidResponseBlock) response;

- (void) getGlobalDownloadSpeedLimit:(NumberResponseBlock) response;

- (void) setGlobalUploadSpeedLimit:(int) speed response:(VoidResponseBlock) response;

- (void) reveal:(Torrent*) torrent;

-(void) setPriority:(Torrent *)torrent  priority:(TorrentPriority)priority response:(VoidResponseBlock) response;

-(NSString*) findLocation:(Torrent *)torrent;
@end

