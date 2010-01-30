//
//  StatusbarController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 29.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "StatusbarController.h"
#import "DownloadsController.h"

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
		CGFloat up = [[DownloadsController sharedDownloadsController].globalUploadSpeed floatValue];
		CGFloat down = [[DownloadsController sharedDownloadsController].globalDownloadSpeed floatValue];
		[_globalSpeedUp setStringValue:[NSString stringForSpeed:up]];
		[_globalSpeedDown setStringValue:[NSString stringForSpeed:down]];
		NSLog(@"%@", [NSString stringForSpeed:up]);
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
