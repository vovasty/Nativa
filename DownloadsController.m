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
	[_timer invalidate];
	_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_update) userInfo:nil repeats:YES];
	[_timer retain];
	[[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];	
}
-(void) stopUpdates;
{
	[_timer invalidate];
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

- (void) add:(NSString *) torrentUrl response:(VoidResponseBlock) response
{
	[_rtorrent add:torrentUrl response:response];
}

- (void) erase:(NSString *) hash response:(VoidResponseBlock) response
{
	[_rtorrent erase:hash response:response];
}

#pragma mark -
#pragma mark global state methods

- (void) setGlobalDownloadSpeed:(int) speed response:(VoidResponseBlock) response
{
	[_rtorrent setGlobalDownloadSpeed:speed response:response];
}

- (void) getGlobalDownloadSpeed:(NumberResponseBlock) response
{
	[_rtorrent getGlobalDownloadSpeed:response];
}


- (void)_update
{
	__block DownloadsController *blockSelf = self;
	ArrayResponseBlock response = [^(NSArray *array, NSString* error) {
		if (error != nil)
			return;
		NSUInteger idx;
#warning multiple objects?
		Torrent* stored_obj;
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
		}
		[[NSNotificationCenter defaultCenter] postNotificationName: NINotifyUpdateDownloads object: blockSelf];
		
	} copy];
	[_rtorrent list:response];
	[response release];
}
@end
