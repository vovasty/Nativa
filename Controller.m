//
//  Controller.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "Controller.h"
#import "DownloadsController.h"
#import "PreferenceController.h"
#include "TorrentViewController.h"
#include "Torrent.h"
#include "TorrentDelegate.h"

@implementation Controller
+(void) initialize
{
	//Create dictionary
	NSMutableDictionary* defaultValues = [NSMutableDictionary dictionary];
	
	//Put defaults into dictionary
	[defaultValues setObject:[NSNumber numberWithInt:65536]
					  forKey:NITurtleSpeedKey];
	
	[defaultValues setObject:[NSNumber numberWithBool:YES]
					  forKey:NITrashDownloadDescriptorsKey];

	
	//Register the dictionary of defaults
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (id)init
{
    if (self = [super init]) 
	{
		_defaults = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

-(void)checkSpeedLimit
{
	//check speed limit
	__block Controller *blockSelf = self;
	NumberResponseBlock response = [^(NSNumber* speed, NSString* error) {
		if (error == nil)
		{
			if ([speed intValue]>0)
				[blockSelf->_turtleButton setState: NSOnState];
			else 
				[blockSelf->_turtleButton setState: NSOffState];
		}
	} copy];
	[[DownloadsController sharedDownloadsController] getGlobalDownloadSpeedLimit:response];
	[response release];
}


- (void)awakeFromNib
{
	[self setupToolbar];

	[self checkSpeedLimit];
	
}

-(IBAction)showPreferencePanel:(id)sender;
{
	if(_preferenceController == nil)
		_preferenceController = [[PreferenceController alloc] init];
	[_preferenceController showWindow:self];
}

-(IBAction)toggleTurtleSpeed:(id)sender
{
	__block Controller *blockSelf = self;
	VoidResponseBlock response = [^(NSString* error){
		[blockSelf checkSpeedLimit];
	}copy];
	int speed = [_turtleButton state] == NSOnState?[_defaults integerForKey:NITurtleSpeedKey]:0;
	[[DownloadsController sharedDownloadsController] setGlobalDownloadSpeedLimit:speed response:response];
	[response release];
}


- (NSArray *) selectedTorrents
{
	NSIndexSet * selectedIndexes = [_downloadsView selectedRowIndexes];
    NSMutableArray * torrents = [NSMutableArray arrayWithCapacity: [selectedIndexes count]]; //take a shot at guessing capacity
    
	TorrentViewController* dataSource = [_downloadsView dataSource];
	
    for (NSUInteger i = [selectedIndexes firstIndex]; i != NSNotFound; i = [selectedIndexes indexGreaterThanIndex: i])
    {
        id item = [dataSource itemAtRow: i];
        if ([item isKindOfClass: [Torrent class]])
            [torrents addObject: item];
    }
    
    return torrents;
}


-(IBAction)removeNoDeleteSelectedTorrents:(id)sender
{
	NSArray * torrents = [self selectedTorrents];
	for (Torrent *t in torrents)
		[[DownloadsController sharedDownloadsController] erase:t.thash response:nil];
}
-(IBAction)stopSelectedTorrents:(id)sender
{
	NSArray * torrents = [self selectedTorrents];
	for (Torrent *t in torrents)
		[[DownloadsController sharedDownloadsController] stop:t.thash response:nil];
}
-(IBAction)resumeSelectedTorrents:(id)sender
{
	NSArray * torrents = [self selectedTorrents];
	for (Torrent *t in torrents)
		[[DownloadsController sharedDownloadsController] start:t.thash response:nil];
}
@end
