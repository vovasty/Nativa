//
//  AppController.h
//  Filterbar
//
//  Created by Matteo Bertozzi on 11/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Filterbar.h"

@interface FilterbarController : NSObject {
@private
	IBOutlet NSTextField *bodyText;
	IBOutlet Filterbar *filterBar;
	NSPredicate *_filter;
}
+ (FilterbarController *)sharedFilterbarController;
@property (retain) NSPredicate* filter;
@end
