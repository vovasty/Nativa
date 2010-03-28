//
//  ProcessPreferencesController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 03.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "ProcessPreferencesController.h"
#import "ProcessesController.h"
#import "ProcessDescriptor.h"
#import "SaveProgressController.h"

@interface ProcessPreferencesController(Private)

-(void)updateSelectedProcess;

- (void) downloadsPathClosed: (NSOpenPanel *) openPanel returnCode: (int) code contextInfo: (void *) info;

- (ProcessDescriptor *) currentProcess;
@end

@implementation ProcessPreferencesController

@synthesize useSSHTunnel;

- (void) awakeFromNib
{
	[self updateSelectedProcess];
}


- (void) controlTextDidEndEditing: (NSNotification *) notification
{
	ProcessDescriptor *pd = [self currentProcess];
    if ([notification object] == _host)
    {
		[pd setHost:[_host stringValue]];
    }
	else if ([notification object] == _port)
	{
		[pd setPort:[_port intValue]];
	}
	else if ([notification object] == _sshHost)
    {
		[pd setSshHost:[_sshHost stringValue]];
    }
	else if ([notification object] == _sshPort)
    {
		[pd setSshPort:[_sshPort stringValue]];
    }
	else if ([notification object] == _sshUsername)
    {
		[pd setSshUsername:[_sshUsername stringValue]];
    }
	else if ([notification object] == _sshPassword)
    {
		[pd setSshPassword:[_sshPassword stringValue]];
    }
	else if ([notification object] == _sshLocalPort)
    {
		[pd setSshLocalPort:[_sshLocalPort intValue]];
    }
	else if ([notification object] == _groupCustomField)
    {
		[pd setGroupsField:[_groupCustomField intValue]];
    }
	
	else;
}


-(void) toggleSSH:(id) sender
{
	ProcessDescriptor *pd = [self currentProcess];
	[pd setConnectionType:[_useSSH state]==NSOnState?@"SSH":@"Local"];

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
	ProcessDescriptor *pd = [self currentProcess];
	//test connection with only one reconnect
	int maxReconnects = (pd.maxReconnects == 0?10:pd.maxReconnects);
	pd.maxReconnects = 0;
	[pd openProcess:nil];

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
			
			pd.maxReconnects = maxReconnects;
			
			if (unsavedProcessDescriptor)
				[[ProcessesController sharedProcessesController] addProcessDescriptor:unsavedProcessDescriptor];
			
			[unsavedProcessDescriptor release];
			unsavedProcessDescriptor = nil;
			
			//set default number of reconnects
			[[ProcessesController sharedProcessesController] saveProcesses];
		}
		[pd closeProcess];
	} copy];
	[[pd process] list:response];
	[response release];
}
@end

@implementation ProcessPreferencesController(Private)
-(void)updateSelectedProcess
{
    ProcessDescriptor *pd = [self currentProcess];
	[_host setStringValue:[pd host]];

	[_port setIntValue:[pd port]];
	
	[_groupCustomField setIntValue:[pd groupsField]];
		
	[_downloadsPathPopUp removeItemAtIndex:0];
	if (pd.downloadsFolder == nil)
		[_downloadsPathPopUp insertItemWithTitle:@"" atIndex:0];
	else
	{
		[_downloadsPathPopUp insertItemWithTitle:[[NSFileManager defaultManager] displayNameAtPath: pd.downloadsFolder] atIndex:0];
		
		NSString * path = [pd.downloadsFolder stringByExpandingTildeInPath];
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
	
	[_useSSH setState:[pd.connectionType isEqualToString:@"SSH"]? NSOnState: NSOffState];
		
	[_sshHost setStringValue:pd.sshHost];
		
	[_sshPort setStringValue:pd.sshPort];
#warning store in keychain		
	[_sshUsername setStringValue:pd.sshUsername];
		
	[_sshPassword setStringValue:pd.sshPassword];
	
	[_sshLocalPort setIntValue:pd.sshLocalPort];

		//for some reason I need trigger event manually
	[self toggleSSH:_useSSH];
}

- (void) downloadsPathClosed: (NSOpenPanel *) openPanel returnCode: (int) code contextInfo: (void *) info
{
    if (code == NSOKButton)
    {
        ProcessDescriptor *pd = [self currentProcess];
		
		NSString * folder = [[openPanel filenames] objectAtIndex: 0];

		[pd setDownloadsFolder:folder];
		
		[self updateSelectedProcess];
		
    }
}

- (ProcessDescriptor *) currentProcess;
{
	if ([[ProcessesController sharedProcessesController] count]>0)
		return [[ProcessesController sharedProcessesController] processDescriptorAtIndex:0];
	else if (!unsavedProcessDescriptor)
	{
		unsavedProcessDescriptor = [[ProcessDescriptor alloc] init];
		unsavedProcessDescriptor.host = @"127.0.0.1";
		unsavedProcessDescriptor.port = 5000;
		unsavedProcessDescriptor.connectionType = @"Local";
		unsavedProcessDescriptor.sshHost = @"";
		unsavedProcessDescriptor.sshPort = @"22";
		unsavedProcessDescriptor.sshUsername = @"";
		unsavedProcessDescriptor.sshPassword = @"";
		unsavedProcessDescriptor.sshLocalPort = 5000;
		unsavedProcessDescriptor.groupsField = 1;
	}
	else;
	
	return unsavedProcessDescriptor;
}
@end