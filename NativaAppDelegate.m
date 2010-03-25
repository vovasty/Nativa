//
//  NativaAppDelegate.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 07.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NativaAppDelegate.h"
#import "DownloadsController.h"
#import "ProcessesController.h"
#import "PreferencesController.h"

@implementation NativaAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	if ([[ProcessesController sharedProcessesController] count]==0)
	{
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"Bring me on"];
		[alert setMessageText:@"Configuration"];
		[alert setInformativeText:@"Before using Nativa you should configure it."];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(configSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

- (void)configSheetDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{
	[[PreferencesController sharedPreferencesController] openPreferences:NIPReferencesViewProcesses];
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


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[[DownloadsController sharedDownloadsController] stopUpdates]; 
}
@end
