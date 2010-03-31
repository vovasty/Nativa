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

#import "ProcessPreferencesController.h"
#import "ProcessesController.h"
#import "SaveProgressController.h"

@interface ProcessPreferencesController(Private)

-(void)updateSelectedProcess;

- (void) downloadsPathClosed: (NSOpenPanel *) openPanel returnCode: (int) code contextInfo: (void *) info;

- (NSInteger) currentProcess;

- (NSString *) emptyString:(NSString *) string;

- (NSString *) zeroInteger:(NSInteger) integer;
@end

@implementation ProcessPreferencesController

@synthesize useSSHTunnel;

- (void) awakeFromNib
{
	pc = [ProcessesController sharedProcessesController];
	[self updateSelectedProcess];
}


- (void) controlTextDidEndEditing: (NSNotification *) notification
{
	NSInteger index = [self currentProcess];
	
    if ([notification object] == _host)
    {
		[pc setHost:[_host stringValue] forIndex:index];
    }
	else if ([notification object] == _port)
	{
		[pc setPort:[_port integerValue] forIndex:index];
	}
	else if ([notification object] == _sshHost)
    {
		[pc setSshHost:[_sshHost stringValue] forIndex:index];
    }
	else if ([notification object] == _sshPort)
    {
		[pc setSshPort:[_sshPort integerValue]  forIndex:index];
    }
	else if ([notification object] == _sshUsername)
    {
		[pc setSshUser:[_sshUsername stringValue] forIndex:index];
    }
	else if ([notification object] == _sshPassword)
    {
		[pc setSshPassword:[_sshPassword stringValue] forIndex:index];
    }
	else if ([notification object] == _sshLocalPort)
    {
		[pc setSshLocalPort:[_sshLocalPort intValue] forIndex:index];
    }
	else if ([notification object] == _groupCustomField)
    {
		[pc setGroupsField:[_groupCustomField intValue] forIndex:index];
    }
	
	else;
}


-(void) toggleSSH:(id) sender
{
	NSInteger index = [self currentProcess];
	[pc setConnectionType:[_useSSH state]==NSOnState?@"SSH":@"Local" forIndex:index];

	[self setUseSSHTunnel:[_useSSH state] == NSOnState];
}

//show folder doalog for downloads path
- (void) downloadsPathShow: (id) sender
{
    NSOpenPanel * panel = [NSOpenPanel openPanel];
	
    [panel setPrompt: NSLocalizedString(@"Select", "Preferences -> Open panel prompt")];
    [panel setAllowsMultipleSelection: NO];
    [panel setCanChooseFiles: NO];
    [panel setCanChooseDirectories: YES];
    [panel setCanCreateDirectories: YES];
	
    [panel beginSheetForDirectory: nil file: nil types: nil
				   modalForWindow: _window modalDelegate: self didEndSelector:
	 @selector(downloadsPathClosed:returnCode:contextInfo:) contextInfo: nil];
	
}

- (void) saveProcess: (id) sender
{
	[_window makeFirstResponder: nil];
	
	[[SaveProgressController sharedSaveProgressController] open: _window message:NSLocalizedString(@"Checking configuration...", "Preferences -> Save process")];

	NSInteger index = [self currentProcess];

	//test connection with only one reconnect
	int maxReconnects = ([pc maxReconnectsForIndex:index] == 0?10:[pc maxReconnectsForIndex:index]);

	[pc setMaxReconnects:0 forIndex:index];

	[pc openProcess:nil forIndex:index];

	ArrayResponseBlock response = [^(NSArray *array, NSString* error) {
		if (error != nil)
		{
			NSLog(@"update download list error: %@", error);
			[[SaveProgressController sharedSaveProgressController] message: error];
			[[SaveProgressController sharedSaveProgressController] stop];
		}
		else
		{
			[[SaveProgressController sharedSaveProgressController] close:nil];
			
			[pc setMaxReconnects:maxReconnects forIndex:index];
			
			//set default number of reconnects
			[[ProcessesController sharedProcessesController] saveProcesses];
		}
		[pc closeProcessForIndex:index];
	} copy];
	[[pc processForIndex:index] list:response];
	[response release];
}
@end

@implementation ProcessPreferencesController(Private)
-(void)updateSelectedProcess
{
    NSInteger index = [self currentProcess];
	
	[_host setStringValue:[self emptyString:[pc hostForIndex:index]]];

	[_port setStringValue:[self zeroInteger:[pc portForIndex:index]]];
	
	[_groupCustomField setIntValue:[pc groupsFieldForIndex:index]];
		
	[_downloadsPathPopUp removeItemAtIndex:0];
	if ([pc localDownloadsFolderForIndex:index] == nil)
		[_downloadsPathPopUp insertItemWithTitle:@"" atIndex:0];
	else
	{
		[_downloadsPathPopUp insertItemWithTitle:[[NSFileManager defaultManager] displayNameAtPath: [pc localDownloadsFolderForIndex:index]] atIndex:0];
		
		NSString * path = [[pc localDownloadsFolderForIndex:index] stringByExpandingTildeInPath];
		NSImage * icon;
		//show a folder icon if the folder doesn't exist
		if ([[path pathExtension] isEqualToString: @""] && ![[NSFileManager defaultManager] fileExistsAtPath: path])
			icon = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode('fldr')];
		else
			icon = [[NSWorkspace sharedWorkspace] iconForFile: path];
		
		[icon setSize: NSMakeSize(16.0, 16.0)];
		NSMenuItem* menuItem = [_downloadsPathPopUp itemAtIndex:0];
		[menuItem setImage:icon];
	}
	[_downloadsPathPopUp selectItemAtIndex: 0];
	
	[_useSSH setState:[[pc connectionTypeForIndex:index] isEqualToString:@"SSH"]? NSOnState: NSOffState];
		
	[_sshHost setStringValue:[self emptyString:[pc sshHostForIndex:index]]];
		
	[_sshPort setStringValue:[self zeroInteger:[pc sshPortForIndex:index]]];

	[_sshUsername setStringValue:[self emptyString:[pc sshUserForIndex:index]]];
		
	[_sshPassword setStringValue:[self emptyString:[pc sshPasswordForIndex:index]]];
	
	[_sshLocalPort setStringValue:[self zeroInteger:[pc sshLocalPortForIndex:index]]];

		//for some reason I need trigger event manually
	[self toggleSSH:_useSSH];
}

- (void) downloadsPathClosed: (NSOpenPanel *) openPanel returnCode: (int) code contextInfo: (void *) info
{
    if (code == NSOKButton)
    {
        NSInteger index = [self currentProcess];
		
		NSString * folder = [[openPanel filenames] objectAtIndex: 0];

		[pc setLocalDownloadsFolder:folder forIndex:index];
		
		[self updateSelectedProcess];
		
    }
}

- (NSInteger) currentProcess;
{
	if ([pc count]>0)
		return [pc indexForRow:0];
	else
		return [pc addProcess];
}

- (NSString *) emptyString:(NSString *) string
{
	return string == nil?@"":string;
}

- (NSString *) zeroInteger:(NSInteger) integer
{
	return integer == 0?@"":[NSString stringWithFormat:@"%d", integer];
}
@end