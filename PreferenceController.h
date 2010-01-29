//
//  PreferenceController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 28.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
extern NSString* const NITurtleSpeedKey;
extern NSString* const NITrashDownloadDescriptorsKey;

@interface PreferenceController : NSWindowController 
{
	IBOutlet NSTextField* _turtleSpeed;
}
- (IBAction)changeTurtleSpeed:(id)sender;
- (int) turtleSpeed;
@end
