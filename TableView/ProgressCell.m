//
//  NIProgressCell.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 26.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ProgressCell.h"
#import "ProgressGradients.h"
#import "Torrent.h"


@implementation ProgressCell

- (id)init {
    self = [super init];
    [self setUsesSingleLineMode:YES];
    [self setLineBreakMode:NSLineBreakByTruncatingTail];
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void) drawRegularBar: (NSRect) barRect
{
    Torrent * torrent = [self representedObject];
    
    NSRect haveRect, missingRect;
    NSDivideRect(barRect, &haveRect, &missingRect, round([torrent donePercent]/100 * NSWidth(barRect)), NSMinXEdge);
    if (!NSIsEmptyRect(haveRect))
    {

		switch ([torrent state]) {
			case seed:
				[[ProgressGradients progressGreenGradient] drawInRect: haveRect angle: 90];
				break;
			case leech:
				[[ProgressGradients progressBlueGradient] drawInRect: haveRect angle: 90];
				break;
			case stop:
				[[ProgressGradients progressGrayGradient] drawInRect: haveRect angle: 90];
				NSLog(@"%@", [torrent name]);
				break;
			default:
				break;
		}
	}
    if (!NSIsEmptyRect(missingRect))
		[[ProgressGradients progressRedGradient] drawInRect: missingRect angle: 90];
}

- (void)drawInteriorWithFrame:(NSRect)frame inView:(NSView *)controlView {
	NSRect progressRect = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
	//	progressRect.origin.x += 20;
	//	progressRect.origin.y += 4;
	//progressRect.size.width -= 24;
	progressRect.size.height = 5;
	
	[self drawRegularBar:progressRect];
	
    //[super drawInteriorWithFrame:progressRect inView:controlView];
}

@end
