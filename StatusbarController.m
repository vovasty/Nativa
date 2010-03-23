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
#import "NSStringAdditions.h"

static NSString* GlobalUploadContext = @"GlobalUploadContext";

static NSString* GlobalDownloadContext = @"GlobalDownloadContext";

static NSString* SpaceLeftContext = @"SpaceLeftContext";

static NSString* GlobalUploadSizeContext = @"GlobalUploadSizeContext";

typedef enum
{
    STATUS_RATIO_TOTAL_TAG = 0,
    STATUS_TRANSFER_TOTAL_TAG = 1,
    STATUS_SPACE_LEFT_TAG = 2
} statusTag;


#define STATUS_RATIO_TOTAL      @"RatioTotal"
#define STATUS_TRANSFER_TOTAL   @"TransferTotal"
#define STATUS_SPACE_LEFT		@"SpaceLeft"


@interface StatusbarController(Private)
- (void) resizeStatusButton;
- (void) changeStatusLabel;
@end

@implementation StatusbarController
- (void)awakeFromNib
{
	[[DownloadsController sharedDownloadsController] addObserver:self
				forKeyPath:@"globalUploadSpeed"
				options:0
				context:&GlobalUploadContext];
	[[DownloadsController sharedDownloadsController] addObserver:self
				forKeyPath:@"globalDownloadContext"
				options:0
				context:&GlobalUploadContext];

	[self changeStatusLabel];
	
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
	else if (context == &SpaceLeftContext)
    {
		[_statusButton setTitle:[NSString stringWithFormat: @"Space left: %@", [NSString stringForFileSize:[DownloadsController sharedDownloadsController].spaceLeft]]];
		[self resizeStatusButton];
    }
	else if (context == &GlobalUploadSizeContext)
    {
		[_statusButton setTitle:[NSString stringWithFormat: @"DL: %@ UL: %@", 
								 [NSString stringForFileSize:[DownloadsController sharedDownloadsController].globalDownloadSize],
								 [NSString stringForFileSize:[DownloadsController sharedDownloadsController].globalUploadSize]]];
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void) setStatusLabel: (id) sender
{
    NSString * statusLabel;
    switch ([sender tag])
    {
        case STATUS_RATIO_TOTAL_TAG:
            statusLabel = STATUS_RATIO_TOTAL;
            break;
        case STATUS_TRANSFER_TOTAL_TAG:
            statusLabel = STATUS_TRANSFER_TOTAL;
            break;
        case STATUS_SPACE_LEFT_TAG:
            statusLabel = STATUS_SPACE_LEFT;
            break;
        default:
            NSAssert1(NO, @"Unknown status label tag received: %d", [sender tag]);
            return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject: statusLabel forKey: @"StatusLabel"];
	[self changeStatusLabel];
}
@end

@implementation StatusbarController(Private)
- (void) resizeStatusButton
{
    [_statusButton sizeToFit];
    
    //width ends up being too long
    NSRect statusFrame = [_statusButton frame];
    statusFrame.size.width -= 25.0;
    
    CGFloat difference = NSMaxX(statusFrame) + 5.0 - [_totalDLImageView frame].origin.x;
    if (difference > 0)
        statusFrame.size.width -= difference;
    
    [_statusButton setFrame: statusFrame];
}
- (void) changeStatusLabel;
{
	NSString *statusLabel = [[NSUserDefaults standardUserDefaults] objectForKey:@"StatusLabel"];

	if (_currentObserver != nil)
		[[DownloadsController sharedDownloadsController] removeObserver:self forKeyPath:_currentObserver];
	
	if ([statusLabel isEqualToString:STATUS_TRANSFER_TOTAL])
	{
		_currentObserver = @"globalUploadSize";
		[[DownloadsController sharedDownloadsController] addObserver:self
														  forKeyPath:_currentObserver
															 options:0
															 context:&GlobalUploadSizeContext];
		[_statusButton setTitle:[NSString stringWithFormat: @"DL: %@ UL: %@", 
								 [NSString stringForFileSize:[DownloadsController sharedDownloadsController].globalDownloadSize],
								 [NSString stringForFileSize:[DownloadsController sharedDownloadsController].globalUploadSize]]];
		[self resizeStatusButton];
	}
	else
	{
		_currentObserver = @"spaceLeft";
		[[DownloadsController sharedDownloadsController] addObserver:self
													  forKeyPath:_currentObserver
														 options:0
														 context:&SpaceLeftContext];
		[_statusButton setTitle:[NSString stringWithFormat: @"Space left: %@", [NSString stringForFileSize:[DownloadsController sharedDownloadsController].spaceLeft]]];
		[self resizeStatusButton];
	}
	
}
@end
