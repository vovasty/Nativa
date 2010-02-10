//
//  Controller.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TorrentDropView, PreferencesController, StatusBarView;

@interface Controller : NSObject {
	IBOutlet NSWindow* _window;
	IBOutlet NSTableView* _downloadsView;
	IBOutlet NSButton* _turtleButton;
	NSUserDefaults* _defaults;
	PreferencesController* _preferencesController;
}

-(IBAction)showPreferencePanel:(id)sender;
-(IBAction)toggleTurtleSpeed:(id)sender;
-(IBAction)removeNoDeleteSelectedTorrents:(id)sender;
-(IBAction)stopSelectedTorrents:(id)sender;
-(IBAction)resumeSelectedTorrents:(id)sender;

- (void) openSheetClosed: (NSOpenPanel *) panel returnCode: (NSInteger) code contextInfo: (NSNumber *) useOptions;
- (void) openShowSheet: (id) sender;
@end
