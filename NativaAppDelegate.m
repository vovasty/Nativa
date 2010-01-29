//
//  NativaAppDelegate.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 07.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NativaAppDelegate.h"

@implementation NativaAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}


- (void) application: (NSApplication *) app openFiles: (NSArray *) filenames
{
    NSLog(@"open files %@", filenames);
}
@end
