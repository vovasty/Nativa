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

@class ProcessesController;

@interface ProcessPreferencesController : NSObject
{
	IBOutlet NSTextField	*_host;
	
	IBOutlet NSTextField	*_port;
	
	IBOutlet NSPopUpButton	*_downloadsPathPopUp;
	
	IBOutlet NSWindow		*_window;
	
	IBOutlet NSButton		*_useSSH;
	
	IBOutlet NSTextField	*_sshHost;
	
	IBOutlet NSTextField	*_sshPort;
	
	IBOutlet NSTextField	*_sshUsername;
	
	IBOutlet NSTextField	*_sshPassword;
	
	IBOutlet NSTextField	*_sshLocalPort;
	
	IBOutlet NSTextField	*_groupCustomField;
	
	IBOutlet NSButton		*_useSSHKeyLogin;
	
	BOOL					useSSHTunnel;
	
	ProcessesController		*pc;
	
	BOOL					useSSHKeyLogin;
}

@property BOOL useSSHTunnel;

@property BOOL useSSHKeyLogin;

- (void) downloadsPathShow: (id) sender;

- (void) toggleSSH: (id) sender;

- (void) toggleSSHUseKeyLogin: (id) sender;

- (void) saveProcess: (id) sender;
@end
