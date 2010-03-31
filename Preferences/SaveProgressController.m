/******************************************************************************
 * Nativa - MacOS X UI for rtorrent
 * http://www.aramzamzam.net
 *
 * Copyright Solomenchuk V. 2010.
 * Solomenchuk Vladimir <vovasty@aramzamzam.net>
 *
 * Licensed under the GPL, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.gnu.org/licenses/gpl-3.0.html
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************/

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
