//
//  SaveProgressController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 28.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SaveProgressController : NSObject 
{
	IBOutlet NSWindow* _sheet;
	
	IBOutlet NSProgressIndicator *_progressIndicator;
	
	IBOutlet NSTextField* _message;
	
	IBOutlet NSButton* _closeButton;
}

+ (SaveProgressController *)sharedSaveProgressController;

- (IBAction) close: (id) sender;
- (IBAction) open: (NSWindow*) window message:(NSString*) message;
- (void) message: (NSString*) message;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
- (void)start;
- (void)stop;
@end
