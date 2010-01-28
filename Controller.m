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
		NSMutableArray* urls = [[NSMutableArray alloc] init];
		[urls retain];
		for(NSString *file in [_dropView fileNames])
		{
			if ([[file pathExtension] isEqualToString:@"torrent"])
			{
				NSURL* url = [NSURL fileURLWithPath:file];
				[urls addObject:url];
				[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent add:[url absoluteString] response:nil];
			}
		}

		[[NSWorkspace sharedWorkspace] recycleURLs: urls
								 completionHandler:nil];
		[urls release];
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}
@end
