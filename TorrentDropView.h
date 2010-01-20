//
//  FileDropView.h
//  DragAndDropTest
//
//  Created by Matteo Bertozzi on 2/28/09.
//  Copyright 2009 Matteo Bertozzi. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TorrentDropView : NSView {
	NSArray* fileNames;
}
@property (readonly, retain) NSArray* fileNames;
-(void) setFileNames:(NSArray*) fn;
@end
