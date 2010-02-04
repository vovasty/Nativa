//
//  AppController.h
//  Filterbar
//
//  Created by Matteo Bertozzi on 11/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FilterButton;

@interface FilterbarController : NSObject 
{
	NSPredicate *_stateFilter;
    
	IBOutlet FilterButton * _allFilterButton, *_downloadFilterButton,
	*_seedFilterButton, *_stopFilterButton;

	IBOutlet NSSearchField *_searchFilterField;

}
+ (FilterbarController *)sharedFilterbarController;

@property (retain) NSPredicate* stateFilter;

- (void) setFilter: (id) sender;
- (void) setSearch: (id) sender;
@end
