//
//  Controller.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TorrentDropView, PreferenceController, StatusBarView;

@interface Controller : NSObject {
	IBOutlet NSWindow* _window;
	IBOutlet NSTableView* _downloadsView;
	IBOutlet NSButton* _turtleButton;
	NSUserDefaults* _defaults;
	PreferenceController* _preferenceController;
}

-(IBAction)showPreferencePanel:(id)sender;
-(IBAction)toggleTurtleSpeed:(id)sender;
-(IBAction)removeNoDeleteSelectedTorrents:(id)sender;
-(IBAction)stopSelectedTorrents:(id)sender;
-(IBAction)resumeSelectedTorrents:(id)sender;
@end
