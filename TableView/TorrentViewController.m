/*
     File: ATContentController.m
 Abstract: The basic controller for the demo app. An instance exists inside the MainMenu.xib file.
 
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

#import "TorrentViewController.h"
#import "TorrentCell.h"
#import "TorrentTableView.h"
#import "Torrent.h";
#import "DownloadsController.h"
#import "FilterbarController.h"

static NSString* FilterTorrents = @"FilterTorrents";

@interface TorrentViewController(Private)

- (void)updateList:(NSNotification*) notification;

@end


@implementation TorrentViewController

- (void)dealloc {
    [_tableContents release];
    [super dealloc];
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateList:) name: NINotifyUpdateDownloads object: nil];
	_tableContents = [[[NSArray alloc] init] retain]; 
	[[DownloadsController sharedDownloadsController] startUpdates];
	[[FilterbarController sharedFilterbarController] addObserver:self
													 forKeyPath:@"filter"
													  options:0
													  context:&FilterTorrents];
	
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &FilterTorrents)
    {
		[self updateList:nil];
		
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)updateList:(NSNotification*) notification;
{
	NSPredicate* filter = [FilterbarController sharedFilterbarController].filter;
	NSMutableArray* arr = [NSMutableArray arrayWithArray:[[DownloadsController sharedDownloadsController] downloads]];
	[_tableContents release];

	if (filter != nil)
		[arr filterUsingPredicate:filter];

	NSSortDescriptor *nameSorter = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	[arr sortUsingDescriptors:[NSArray arrayWithObject:nameSorter]];
	[nameSorter release];

	_tableContents = [arr retain];

	[_outlineView reloadData];
}


- (NSInteger) outlineView: (NSOutlineView *) outlineView numberOfChildrenOfItem: (id) item
{
	return [_tableContents count];
}

- (id) outlineView: (NSOutlineView *) outlineView child: (NSInteger) index ofItem: (id) item
{
	return [_tableContents objectAtIndex: index];
}

- (BOOL) outlineView: (NSOutlineView *) outlineView isItemExpandable: (id) item
{
    return ![item isKindOfClass: [Torrent class]];
}

- (id) outlineView: (NSOutlineView *) outlineView objectValueForTableColumn: (NSTableColumn *) tableColumn byItem: (id) item
{
    if ([item isKindOfClass: [Torrent class]])
        return ((Torrent*)item).thash;
//    else
//    {
//        NSString * ident = [tableColumn identifier];
//        if ([ident isEqualToString: @"Group"])
//        {
//            NSInteger group = [item groupIndex];
//            return group != -1 ? [[GroupsController groups] nameForIndex: group]
//			: NSLocalizedString(@"No Group", "Group table row");
//        }
//        else if ([ident isEqualToString: @"Color"])
//        {
//            NSInteger group = [item groupIndex];
//            return [[GroupsController groups] imageForIndex: group];
//        }
//        else if ([ident isEqualToString: @"DL Image"])
//            return [NSImage imageNamed: @"DownArrowGroupTemplate.png"];
//        else if ([ident isEqualToString: @"UL Image"])
//            return [NSImage imageNamed: [fDefaults boolForKey: @"DisplayGroupRowRatio"]
//					? @"YingYangGroupTemplate.png" : @"UpArrowGroupTemplate.png"];
//        else
//        {
//            TorrentGroup * group = (TorrentGroup *)item;
//            
//            if ([fDefaults boolForKey: @"DisplayGroupRowRatio"])
//                return [NSString stringForRatio: [group ratio]];
//            else
//            {
//                CGFloat rate = [ident isEqualToString: @"UL"] ? [group uploadRate] : [group downloadRate];
//                return [NSString stringForSpeed: rate];
//            }
//        }
//    }
}

@end
