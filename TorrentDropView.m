//
//  FileDropView.m
//  DragAndDropTest
//
//  Created by Matteo Bertozzi on 2/28/09.
//  Copyright 2009 Matteo Bertozzi. All rights reserved.
//

#import "TorrentDropView.h"

@implementation TorrentDropView

@synthesize fileNames = _fileNames;

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
		[self registerForDraggedTypes:[NSArray arrayWithObjects:
										NSFilenamesPboardType, nil]];
    }
    return self;
}

// I'm DND Destination
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
 
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
 
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
 
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
 
	if ([[pboard types] containsObject:NSFilenamesPboardType]) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		[self setFileNames:files];
    }
    return YES;
}
-(void) setFileNames:(NSArray*) fn;
{
	_fileNames = fn;
}
@end
