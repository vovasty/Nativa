/*
 File: ATImageTextCell.m
 Abstract: A complex image and text cell that also draws a fill color. The cell uses sub-cells to delegate the real work to other cells.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2009 Apple Inc. All Rights Reserved.
 
 */

#import "TorrentCell.h"
#import "TorrentTableView.h"
#import "ProgressCell.h"
#import "Torrent.h"

#define IMAGE_INSET 8.0
#define ASPECT_RATIO 1.6
#define TITLE_HEIGHT 17.0
#define FILL_COLOR_RECT_SIZE 25.0
#define INSET_FROM_IMAGE_TO_TEXT 4.0

@implementation TorrentCell

- (id)copyWithZone:(NSZone *)zone {
    TorrentCell *result = [super copyWithZone:zone];
    if (result != nil) {
        // Retain or copy all our ivars
        result->_imageCell = [_imageCell copyWithZone:zone];
		result->_progressCell = [_progressCell copyWithZone:zone];
    }
    return result;
}

- (void)dealloc {
    [_imageCell release];
	[_progressCell release];
    [super dealloc];
}

- (void)setRepresentedObject:(id)anObject
{
	if (_imageCell == nil)
	{
		_imageCell = [[NSImageCell alloc] init];
		[_imageCell setControlView:self.controlView];
		[_imageCell setBackgroundStyle:self.backgroundStyle];
		
	}
	if (_progressCell == nil)
	{
		_progressCell = [[ProgressCell alloc] init];
		[_progressCell setControlView:self.controlView];
		[_progressCell setBackgroundStyle:self.backgroundStyle];
		[_progressCell setTextColor:[NSColor grayColor]];
	}
	Torrent* t=[self representedObject];
	_imageCell.image=t.icon;
	[_progressCell setRepresentedObject:anObject];
	[super setRepresentedObject:anObject];
}

- (void)setControlView:(NSView *)controlView {
    [super setControlView:controlView];
    [_imageCell setControlView:controlView];
	[_progressCell setControlView:controlView];
}

- (void)setBackgroundStyle:(NSBackgroundStyle)style {
    [super setBackgroundStyle:style];
    [_imageCell setBackgroundStyle:style];
	[_progressCell setBackgroundStyle:style];
}

- (NSRect)_imageFrameForInteriorFrame:(NSRect)frame {
//    NSRect result = frame;
//    // Inset the top
//    result.origin.y += IMAGE_INSET;
//    result.size.height -= 2*IMAGE_INSET;
//    // Inset the left
//    result.origin.x += IMAGE_INSET;
//    // Make the width match the aspect ratio based on the height
//    result.size.width = ceil(result.size.height * ASPECT_RATIO);
    NSRect result = frame;
    // Inset the top
    result.origin.y += IMAGE_INSET;
    result.size.height = 32;
    // Inset the left
    result.origin.x += IMAGE_INSET;
    // Make the width match the aspect ratio based on the height
    result.size.width = 32;
	
    return result;
}

- (NSRect)imageRectForBounds:(NSRect)frame {
    // We would apply any inset that here that drawWithFrame did before calling drawInteriorWithFrame:. It does none, so we don't do anything.
    return [self _imageFrameForInteriorFrame:frame];
}

- (NSRect)_titleFrameForInteriorFrame:(NSRect)frame {
    NSRect imageFrame = [self _imageFrameForInteriorFrame:frame];
    NSRect result = frame;
    // Move our inset to the left of the image frame
    result.origin.x = NSMaxX(imageFrame) + INSET_FROM_IMAGE_TO_TEXT;
    // Go as wide as we can
    result.size.width = NSMaxX(frame) - NSMinX(result);
    // Move the title above the Y centerline of the image. 
    NSSize naturalSize = [super cellSize];
    result.origin.y = floor(NSMidY(imageFrame) - naturalSize.height - INSET_FROM_IMAGE_TO_TEXT);
    result.size.height = naturalSize.height;
    return result;
}

- (NSRect)_fillColorFrameForInteriorFrame:(NSRect)frame {
    NSRect imageFrame = [self _imageFrameForInteriorFrame:frame];
    NSRect result = frame;
	
    // Move our inset to the left of the image frame
    result.origin.x = NSMaxX(imageFrame) + INSET_FROM_IMAGE_TO_TEXT;
    result.size.width = NSMaxX(frame) - NSMinX(result);
    result.size.height = FILL_COLOR_RECT_SIZE;
    result.origin.y = floor(NSMidY(imageFrame));
    return result;
}

- (NSRect)_progressFrameForInteriorFrame:(NSRect)frame {
    NSRect imageFrame = [self _imageFrameForInteriorFrame:frame];
    NSRect result = frame;
	
    // Move our inset to the left of the image frame
    result.origin.x = NSMaxX(imageFrame) + INSET_FROM_IMAGE_TO_TEXT;
    result.size.width = NSMaxX(frame) - NSMinX(result);
    result.size.height = FILL_COLOR_RECT_SIZE;
    result.origin.y = floor(NSMidY(imageFrame));
    return result;	
}


- (NSRect)_subtitleFrameForInteriorFrame:(NSRect)frame {
    NSRect fillColorFrame = [self _fillColorFrameForInteriorFrame:frame];
    NSRect result = fillColorFrame;
    result.origin.x = NSMaxX(fillColorFrame) + INSET_FROM_IMAGE_TO_TEXT;
    result.size.width = NSMaxX(frame) - NSMinX(result);    
    return result;    
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)controlView {
    if (_imageCell) {
        NSRect imageFrame = [self _imageFrameForInteriorFrame:frame];
        [_imageCell drawWithFrame:imageFrame inView:controlView];
    }
	if (_progressCell)
	{
		NSRect progressFrame = [self _progressFrameForInteriorFrame:frame];
        [_progressCell drawWithFrame:progressFrame inView:controlView];
	}
    NSRect titleFrame = [self _titleFrameForInteriorFrame:frame];
    [super drawInteriorWithFrame:titleFrame inView:controlView];
}
@end
