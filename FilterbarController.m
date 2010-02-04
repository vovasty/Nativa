//
//  AppController.m
//  Filterbar
//
//  Created by Matteo Bertozzi on 11/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FilterbarController.h"
#import "Torrent.h"
#import "SynthesizeSingleton.h"
#import "PreferencesController.h"
#import "FilterButton.h"

static NSString *FILTER_ALL = @"All";
static NSString *FILTER_DOWNLOAD = @"Downloading";
static NSString *FILTER_UPLOAD = @"Uploading";
static NSString *FILTER_STOP = @"Paused";

@interface FilterbarController(Private)
-(void)_updateFilter;
-(NSButton*) _currentButton;
@end

@implementation FilterbarController
SYNTHESIZE_SINGLETON_FOR_CLASS(FilterbarController);

@synthesize stateFilter = _stateFilter;

- (void)awakeFromNib 
{
	[self setFilter:[self _currentButton]];
}

//resets filter and sorts torrents
- (void) setFilter: (id) sender
{
	NSButton * prevFilterButton = [self _currentButton];
    
    if (sender != prevFilterButton)
    {
        [prevFilterButton setState: NSOffState];
        [sender setState: NSOnState];
		
		NSString *filterType;
		
        if (sender == _downloadFilterButton)
            filterType = FILTER_DOWNLOAD;
        else if (sender == _stopFilterButton)
            filterType = FILTER_STOP;
        else if (sender == _seedFilterButton)
            filterType = FILTER_UPLOAD;
        else
            filterType = FILTER_ALL;
		
        [[NSUserDefaults standardUserDefaults] setObject: filterType forKey: NIFilterKey];
    }
    else
        [sender setState: NSOnState];
	
    [self _updateFilter];
}

- (void) setSearch: (id) sender
{
	[self _updateFilter];
}


@end

@implementation FilterbarController(Private)
-(NSButton*) _currentButton
{
    NSString *currentFilterName = [[NSUserDefaults standardUserDefaults] objectForKey: NIFilterKey];

    if ([currentFilterName isEqualToString: FILTER_STOP])
        return _stopFilterButton;
    else if ([currentFilterName isEqualToString: FILTER_UPLOAD])
        return _seedFilterButton;
    else if ([currentFilterName isEqualToString: FILTER_DOWNLOAD])
        return _downloadFilterButton;
    else
        return _allFilterButton;
}

-(void)_updateFilter
{
	NSString *currentFilterName = [[NSUserDefaults standardUserDefaults] objectForKey: NIFilterKey];
	NSString * searchString = [_searchFilterField stringValue];
	NSString* filter;
	
    if ([currentFilterName isEqualToString: FILTER_STOP])
        filter = [NSString stringWithFormat: @"SELF.state == %d",stopped];
    else if ([currentFilterName isEqualToString: FILTER_UPLOAD])
        filter = [NSString stringWithFormat: @"SELF.state == %d",leeching];
    else if ([currentFilterName isEqualToString: FILTER_DOWNLOAD])
        filter = [NSString stringWithFormat: @"SELF.state == %d",seeding];
    else
        filter = nil;
	
	filter = [NSString stringWithFormat: @"%@ SELF.name like[c] \"*%@*\"", filter == nil?@"":[NSString stringWithFormat: @"%@ AND ", filter], searchString];
	
	[FilterbarController sharedFilterbarController].stateFilter = [NSPredicate predicateWithFormat:filter];
}
@end