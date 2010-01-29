//
//  Controller.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TorrentDropView, PreferenceController;
@interface Controller : NSObject {
	IBOutlet TorrentDropView* _dropView;
	IBOutlet NSTextField* _message;
	NSUserDefaults* _defaults;
	PreferenceController* _preferenceController;
}

-(IBAction)showPreferencePanel:(id)sender;
-(IBAction)toggleTurtleSpeed:(id)sender;
@end
