//
//  NativaAppDelegate.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 07.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NativaAppDelegate.h"
#import "DownloadsController.h"

@implementation NativaAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}


- (void) application: (NSApplication *) app openFiles: (NSArray *) fileNames
{
    [[DownloadsController sharedDownloadsController] add:fileNames];
}

- (BOOL) applicationShouldHandleReopen: (NSApplication *) app hasVisibleWindows: (BOOL) visibleWindows
{
	//hide window instead of close
    NSWindow * mainWindow = [NSApp mainWindow];
    if (!mainWindow || ![mainWindow isVisible])
        [window makeKeyAndOrderFront: nil];
    
    return NO;
}

@end
