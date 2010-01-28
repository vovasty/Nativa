//
//  Controller.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "Controller.h"
#import "TorrentDropView.h"
#import "GlobalTorrentController.h"
#import "RTorrentCommand.h"
#import "PreferenceController.h"

static NSString* FilesDroppedContext = @"FilesDroppedContext";



@implementation Controller
- (void)awakeFromNib
{
	[_dropView addObserver:self
			   forKeyPath:@"fileNames"
				  options:0
				  context:&FilesDroppedContext];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &FilesDroppedContext)
    {
		for(NSString *file in [_dropView fileNames])
		{
			if ([[file pathExtension] isEqualToString:@"torrent"])
			{
				NSURL* url = [NSURL fileURLWithPath:file];
				NSArray* urls = [NSArray arrayWithObjects:url, nil];
				__block Controller *blockSelf = self;
				VoidResponseBlock response = [^{ 
#warning memory leak here (recycleURLs)
					[[NSWorkspace sharedWorkspace] recycleURLs: urls
											 completionHandler:nil];
				} copy];
				[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent add:[url absoluteString] response:response];
				[response release];
			}
		}
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
-(IBAction)showPreferencePanel:(id)sender;
{
	if(_preferenceController == nil)
		_preferenceController = [[PreferenceController alloc] init];
	[_preferenceController showWindow:self];
}
@end
