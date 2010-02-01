//
//  DownloadsController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "DownloadsController.h"
#import "SynthesizeSingleton.h"
#import "Torrent.h"
#import "TorrentDelegate.h"
#import "RTConnection.h"
#import "RTorrentController.h"

NSString* const NINotifyUpdateDownloads = @"NINotifyUpdateDownloads";

@interface DownloadsController(Private)

- (void)_update;
@end

@implementation DownloadsController

SYNTHESIZE_SINGLETON_FOR_CLASS(DownloadsController);

@synthesize	globalUploadSpeed = _globalUploadSpeed;
@synthesize globalDownloadSpeed = _globalDownloadSpeed;


-(id)init;
{
    self = [super init];
    if (self == nil)
        return nil;
	_downloads = [[[NSMutableArray alloc] init] retain];
	RTConnection *connection = [[[RTConnection alloc] initWithHostPort:@"192.168.1.206" port:5000] autorelease];
	_rtorrent = [[RTorrentController alloc] initWithConnection:connection];
	[_rtorrent retain];
	return self;
}

-(void)dealloc
{
	[_downloads release];
	[_rtorrent release];
	[super dealloc];
}

#pragma mark -
#pragma mark public methods

-(void) startUpdates;
{
	[_updateListTimer invalidate];
	_updateListTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_updateList) userInfo:nil repeats:YES];
	[_updateListTimer retain];
	[[NSRunLoop currentRunLoop] addTimer:_updateListTimer forMode:NSDefaultRunLoopMode];	
	
//	[_updateGlobalsTimer invalidate];
//	_updateGlobalsTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(_updateGlobals) userInfo:nil repeats:YES];
//	[_updateGlobalsTimer retain];
//	[[NSRunLoop currentRunLoop] addTimer:_updateGlobalsTimer forMode:NSDefaultRunLoopMode];
}
-(void) stopUpdates;
{
	[_updateListTimer invalidate];
}

-(NSArray*) downloads;
{
	return _downloads;
}

#pragma mark -
#pragma mark concrete torrent methods

- (void) start:(NSString *) hash response:(VoidResponseBlock) response
{
	[_rtorrent start:hash response:response];
}

- (void) stop:(NSString *) hash response:(VoidResponseBlock) response
{
	[_rtorrent stop:hash response:response];
}

- (void) add:(NSArray *) filesNames
{
	for(NSString *file in filesNames)
	{
		NSURL* url = [NSURL fileURLWithPath:file];
		NSArray* urls = [NSArray arrayWithObjects:url, nil];
		__block DownloadsController *blockSelf = self;
		VoidResponseBlock response = [^{ 
#warning memory leak here (recycleURLs)
				[[NSWorkspace sharedWorkspace] recycleURLs: urls
							completionHandler:nil];
		} copy];
		[_rtorrent add:url response:response];
		[response release];
	}
}

- (void) erase:(NSString *) hash response:(VoidResponseBlock) response
{
	[_rtorrent erase:hash response:response];
}

#pragma mark -
#pragma mark global state methods

- (void) setGlobalDownloadSpeedLimit:(int) speed response:(VoidResponseBlock) response
{
	[_rtorrent setGlobalDownloadSpeedLimit:speed response:response];
}

- (void) getGlobalDownloadSpeedLimit:(NumberResponseBlock) response
{
	[_rtorrent getGlobalDownloadSpeedLimit:response];
}


- (void)_updateList
{
	__block DownloadsController *blockSelf = self;
	ArrayResponseBlock response = [^(NSArray *array, NSString* error) {
		if (error != nil)
			return;
		NSUInteger idx;
#warning multiple objects?
		Torrent* stored_obj;
		CGFloat globalUploadRate = 0.0;
		CGFloat globalDownloadRate = 0.0;
		for (Torrent *obj in array)
		{
			idx = [blockSelf->_downloads indexOfObject:obj];
			if (idx ==  NSNotFound)
				[blockSelf->_downloads addObject:obj];
			else 
			{
				stored_obj = [blockSelf->_downloads objectAtIndex:idx];
				[stored_obj update:obj];
				[obj release];
			}
			globalUploadRate += [obj speedUpload];
			globalDownloadRate += [obj speedDownload];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName: NINotifyUpdateDownloads object: blockSelf];
		blockSelf.globalDownloadSpeed = globalDownloadRate;
		blockSelf.globalUploadSpeed = globalUploadRate;
	} copy];
	[_rtorrent list:response];
	[response release];
}

@end
