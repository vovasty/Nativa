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

- (IBAction) open: (NSWindow*)window
{
	if (!_sheet)
		//Check the _progressSheet instance variable to make sure the custom sheet does not already exist.
        [NSBundle loadNibNamed: @"SaveProgress" owner: self];

	[self message:@""];
	[_progressIndicator startAnimation:nil];
	[_closeButton setHidden:YES];
	
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
	[_progressIndicator stopAnimation:nil];
	[_message setStringValue: message];
	[_closeButton setHidden:NO];
}
@end
