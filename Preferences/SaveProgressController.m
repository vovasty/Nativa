//
//  SaveProgressController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 28.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "SaveProgressController.h"
#import "SynthesizeSingleton.h"

@implementation SaveProgressController
SYNTHESIZE_SINGLETON_FOR_CLASS(SaveProgressController);

- (IBAction) open: (NSWindow*) window message:(NSString*) message;
{
	if (!_sheet)
		//Check the _progressSheet instance variable to make sure the custom sheet does not already exist.
        [NSBundle loadNibNamed: @"SaveProgress" owner: self];

	[self message:message];
	[self start];
    [NSApp beginSheet: _sheet
	   modalForWindow: window
		modalDelegate: self
	   didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo
{
	[_progressIndicator stopAnimation:nil];
	[sheet orderOut:self];	
}

- (IBAction)close: (id)sender
{
    [NSApp endSheet:_sheet];
}

- (void) message: (NSString*) message
{
	[_message setStringValue: message];
}

- (void)start
{
	[_progressIndicator startAnimation:nil];
	[_closeButton setHidden:YES];
}

- (void)stop
{
	[_progressIndicator stopAnimation:nil];
	[_closeButton setHidden:NO];

}
@end
