//
//  StatusbarController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 29.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "StatusbarController.h"
#import "DownloadsController.h"
#import "NSDataAdditions.h"

static NSString* GlobalUploadContext = @"GlobalUploadContext";

static NSString* GlobalDownloadContext = @"GlobalDownloadContext";

@implementation StatusbarController
- (void)awakeFromNib
{
	[[DownloadsController sharedDownloadsController] addObserver:self
				forKeyPath:@"globalUploadSpeed"
				options:0
				context:&GlobalUploadContext];
	[[DownloadsController sharedDownloadsController] addObserver:self
				forKeyPath:@"GlobalDownloadContext"
				options:0
				context:&GlobalUploadContext];
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &GlobalDownloadContext || context == &GlobalUploadContext)
    {
		CGFloat up = [DownloadsController sharedDownloadsController].globalUploadSpeed;
		CGFloat down = [DownloadsController sharedDownloadsController].globalDownloadSpeed;
		[_globalSpeedUp setStringValue:[NSString stringForSpeed:up]];
		[_globalSpeedDown setStringValue:[NSString stringForSpeed:down]];
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