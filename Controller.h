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

@class TorrentDropView, PreferencesController, StatusBarView, TorrentTableView, DragOverlayWindow, Torrent;

@interface Controller : NSObject<NSMenuDelegate> {
	IBOutlet NSWindow			*_window;
	IBOutlet TorrentTableView	*_downloadsView;
	IBOutlet NSButton			*_turtleButton;
	NSUserDefaults				*_defaults;
	PreferencesController		*_preferencesController;
	DragOverlayWindow			*_overlayWindow;
	IBOutlet NSMenu				*_contextRowMenu;
	IBOutlet NSMenu				*_groupMenu;
	Torrent						*_menuTorrent;
}

-(IBAction)showPreferencePanel:(id)sender;
-(IBAction)toggleTurtleSpeed:(id)sender;
-(IBAction)removeNoDeleteSelectedTorrents:(id)sender;
-(IBAction)removeDeleteSelectedTorrents:(id)sender;
-(IBAction)stopSelectedTorrents:(id)sender;
-(IBAction)resumeSelectedTorrents:(id)sender;

- (void) openSheetClosed: (NSOpenPanel *) panel returnCode: (NSInteger) code contextInfo: (NSNumber *) useOptions;
- (void) openShowSheet: (id) sender;
- (IBAction) toggleQuickLook:(id)sender;
- (IBAction) revealSelectedTorrents:(id)sender;
- (void) setGroup: (id) sender;
- (void) showGroupMenuForTorrent:(Torrent *) torrent atLocation:(NSPoint) location;
- (NSMenu *) contextRowMenu;
- (void) setPriorityForSelectedTorrents: (id) sender;
@end
