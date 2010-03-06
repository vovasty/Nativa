//
//  QuickLookController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 05.03.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "QuickLookController.h"
#include "TorrentTableView.h"
#include "Torrent.h"
#include "DownloadsController.h"
#include "TorrentTableView.h"
#include <QuickLook/QuickLook.h>
#include "SynthesizeSingleton.h"

@interface TorrentTableView (QLPreviewPanelController)
@end

@implementation TorrentTableView (QLPreviewPanelController)
- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
	return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
	[[QuickLookController sharedQuickLookController] beginPanel:panel window:[self window] view:self];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
	[[QuickLookController sharedQuickLookController] endPanel];
}
@end

@interface Torrent (QLPreviewItem) <QLPreviewItem>

@end

@implementation Torrent (QLPreviewItem)
- (NSURL *)previewItemURL
{
    NSString *location = [[DownloadsController sharedDownloadsController] findLocation:self];
	return (location==nil?nil:[NSURL fileURLWithPath: location]);
}

- (NSString *)previewItemTitle
{
    return self.name;
}

@end



@implementation QuickLookController
SYNTHESIZE_SINGLETON_FOR_CLASS(QuickLookController);

+(void) show
{
	[[QLPreviewPanel sharedPreviewPanel] updateController];
	NSLog(@"quicklook controller %@", [[QLPreviewPanel sharedPreviewPanel] currentController]);
	if ([[QLPreviewPanel sharedPreviewPanel] isVisible])
		[[QLPreviewPanel sharedPreviewPanel] orderOut: nil];
	else
		[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront: nil];
}


-(void) beginPanel:(QLPreviewPanel*) panel window:(NSWindow*)window view:(TorrentTableView*) view
{
	_panel = [panel retain];
	_panel.delegate = self;
	_panel.dataSource = self;
	
	_window = window;
	_view = view;
}

-(void) endPanel;
{
	[_panel release];
	_panel = nil;
	
}


// Quick Look panel support


- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
	return YES;
}

// Quick Look panel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
	return [[_view selectedTorrents] count];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return [[_view selectedTorrents] objectAtIndex:index];
}

// Quick Look panel delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
   // redirect all key down events to the table view
    if ([event type] == NSKeyDown) 
	{
        [_view keyDown:event];
        return NO;
    }
    return YES;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
	if (![_window isVisible])
		return NSZeroRect;
	
	const NSInteger row = [_view rowForItem: item];
	if (row == -1)
		return NSZeroRect;
	
	NSRect frame = [_view iconRectForRow: row];
	
	if (!NSIntersectsRect([_view visibleRect], frame))
		return NSZeroRect;
	
	frame.origin = [_view convertPoint: frame.origin toView: nil];
	frame.origin = [_window convertBaseToScreen: frame.origin];
	frame.origin.y -= frame.size.height;
	return frame;
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
    Torrent* torrent = (Torrent *)item;

    return [torrent icon];
}
@end
