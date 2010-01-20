//
//  BDController.m
//  ProgressInNSTableView
//
//  Created by Brian Dunagan on 12/6/08.
//  Copyright 2008 bdunagan.com. All rights reserved.
//

#import "BDController.h"
#import "BDDiscreteProgressCell.h"
#import "TorrentItem.h"

#import "GlobalTorrentController.h"
#import "TorrentDelegate.h"

#import "TorrentDropView.h"

static NSString* FilesDroppedContext = @"FilesDroppedContext";
static NSString* RTorrentErrorContext = @"RTorrentErrorContext";
static NSString* RTorrentWorkingContext = @"RTorrentWorkingContext";

@interface BDController ()
- (void) processList:(NSArray *) lst;
- (void)updateList;
- (VoidResponseBlock) refreshReponse;
-(void) applyFilter;
@end


@implementation BDController

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		allObjects = [[NSMutableArray alloc] init];
		[allObjects retain];
		torrentListFilter = nil;
	}
	return self;
}



- (void)awakeFromNib
{
	runs = 0;
	[dropView addObserver:self
		forKeyPath:@"fileNames"
		options:0
		context:&FilesDroppedContext];
	[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent addObserver:self
			   forKeyPath:@"error"
				  options:0
				  context:&RTorrentErrorContext];
	[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent addObserver:self
				forKeyPath:@"working"
				options:0
				context:&RTorrentWorkingContext];
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self selector: @selector(filterTorrents:) name: @"FilterTorrents" object: nil];


	timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateList) userInfo:nil repeats:YES];
	[timer retain];
	[[NSRunLoop currentRunLoop] addTimer: timer forMode: NSModalPanelRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer: timer forMode: NSEventTrackingRunLoopMode];
	
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &FilesDroppedContext)
    {
		for(NSString *file in [dropView fileNames])
		{
			[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent add:[NSString stringWithFormat:@"file://%@",file] response:[self refreshReponse]];
		}
		
    }
	else if (context == &RTorrentErrorContext)
    {
		[status setStringValue:[[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent errorCommand] error]];
    }
	else if (context == &RTorrentWorkingContext)
    {
		BOOL working = [[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent working];
		if (working)
			[busy startAnimation:nil];
		else
			[busy stopAnimation:nil];
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

-(void)filterTorrents:(NSNotification*) notification;
{
	NSPredicate* f = [notification object];
	if (torrentListFilter != f)
		[torrentListFilter release];
	torrentListFilter = f;
	[torrentListFilter retain];
	[self applyFilter];
}

-(void) applyFilter;
{
	if (objects != allObjects)
		[objects release];

	if (torrentListFilter == nil)
		objects = allObjects;
	else
	{
		objects = [allObjects filteredArrayUsingPredicate:torrentListFilter];
		[objects retain];
	}
	[list reloadData];
}

- (void)updateList
{
	__block BDController *blockSelf = self;
	ArrayResponseBlock response = [[^(NSArray * lst) {
		[blockSelf processList:lst];
		runs++;
		[blockSelf->status setIntValue:blockSelf->runs];
	} copy] autorelease];
	[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent list:response];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [objects count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	TorrentItem *obj = [objects objectAtIndex:rowIndex];
	NSString *cid = [aTableColumn identifier];
	if ([@"Name" isEqual:cid])
		return [NSString stringWithFormat:@"%@", [obj name]];
	else if ([@"Size" isEqual:cid])
		return [NSString stringWithFormat:@"%d", [obj size]];
	else if ([@"Done" isEqual:cid])
		return [NSString stringWithFormat:@"%d", [obj downloaded]];
	else if ([@"State" isEqual:cid])
	{
		switch ([obj state]) {
			case seed:
				return @"seed";
			case stop:
				return @"stop";
			case leech:
				return @"leech";
		}
	}
	
	return @"";
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	TorrentItem *obj = [objects objectAtIndex:rowIndex];
	if ([aCell isKindOfClass:[BDDiscreteProgressCell class]])
	{
		[aCell setProgress:[obj progress]];
		[aTableView addSubview:[obj progress]];
	}
}

- (void) processList:(NSArray *) lst;
{
	NSUInteger idx;
	TorrentItem* stored_obj;
	for (TorrentItem *obj in lst)
	{
		idx = [allObjects indexOfObject:obj];
		if (idx ==  NSNotFound)
			[allObjects addObject:obj];
		else 
		{
			stored_obj = [allObjects objectAtIndex:idx];
			[stored_obj update:obj];
		}
		
	}
	[self applyFilter];
}

- (IBAction)refresh:(id)sender
{
	[self updateList];
}


- (VoidResponseBlock) refreshReponse;
{
	__block BDController *blockSelf = self;
	return [[^{ 
		[blockSelf refresh:nil]; 
	} copy] autorelease];
}


- (IBAction)start:(id)sender
{
	NSIndexSet * indexes = [list selectedRowIndexes];
    for (NSUInteger i = [indexes firstIndex]; i != NSNotFound; i = [indexes indexGreaterThanIndex: i])
    {
        TorrentItem* item = [objects objectAtIndex:i];
		[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent start:[item thash] response:[self refreshReponse]];
    }
}


- (IBAction)stop:(id)sender
{
	NSIndexSet * indexes = [list selectedRowIndexes];
    for (NSUInteger i = [indexes firstIndex]; i != NSNotFound; i = [indexes indexGreaterThanIndex: i])
    {
        TorrentItem* item = [objects objectAtIndex:i];
		[[GlobalTorrentController sharedGlobalTorrentController].defaultRTorrent stop:[item thash] response:[self refreshReponse]];
    }
}

@end
