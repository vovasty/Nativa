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

#import <Cocoa/Cocoa.h>

typedef void (^SaveProgressHandler)(void);

@interface SaveProgressController : NSObject 
{
	IBOutlet NSWindow* _sheet;
	
	IBOutlet NSProgressIndicator *_progressIndicator;
	
	IBOutlet NSTextField* _message;
	
	IBOutlet NSButton* _closeButton;
	
	SaveProgressHandler handler;
}

+ (SaveProgressController *)sharedSaveProgressController;

@property (copy) SaveProgressHandler handler;

- (IBAction) close: (id) sender;
- (IBAction) open: (NSWindow*) window message:(NSString*) message handler:(SaveProgressHandler)handler;
- (void) message: (NSString*) message;
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode  contextInfo:(void  *)contextInfo;
- (void)start;
- (void)stop;
@end
