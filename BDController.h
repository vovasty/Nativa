//
//  BDController.h
//  ProgressInNSTableView
//
//  Created by Brian Dunagan on 12/6/08.
//  Copyright 2008 bdunagan.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TorrentDropView;

@class RTorrentController, RTConnection;

@interface BDController : NSObject
{
	IBOutlet NSTableView *list;
	IBOutlet NSProgressIndicator *busy;
	IBOutlet NSTextField *status;
	IBOutlet TorrentDropView *dropView;
	NSTimer* timer;
	NSArray *objects;
	NSMutableArray *allObjects;
	NSPredicate* torrentListFilter;
	int runs;
}

- (IBAction)refresh:(id)sender;

- (IBAction)start:(id)sender;

- (IBAction)stop:(id)sender;

- (IBAction)runTimer:(id)sender;
@end
