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
#import "GlobalTorrentController.h"
#import "TorrentDelegate.h"

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
	return self;
}

-(void)dealloc
{
	[_downloads release];
	[super dealloc];
}

-(void) start;
{
	[_timer invalidate];
	_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_update) userInfo:nil repeats:YES];
	[_timer retain];
	[[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];	
}
-(void) stop;
{
	[_timer invalidate];
}

-(NSArray*) downloads;
{
	return _downloads;
}

- (void)_update
{
	__block DownloadsController *blockSelf = self;
	ArrayResponseBlock response = [^(NSArray * lst) {
		NSUInteger idx;
#warning multiple objects?
		Torrent* stored_obj;
		for (Torrent *obj in lst)
		{
			idx = [blockSelf->_downloads indexOfObject:obj];
			if (idx ==  NSNotFound)
				[blockSelf->_downloads addObject:obj];
			else 
			{
				stored_obj = [blockSelf->_downloads objectAtIndex:idx];
				[stored_obj update:obj];
			}
		}
		[[NSNotificationCenter defaultCenter] postNotificationName: NOTIFY_UPDATE_DOWNLOADS object: blockSelf];
		
	} copy];
	[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent list:response];
	[response release];
}
@end
