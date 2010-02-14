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

@interface ProcessPreferencesController(Private)

-(void)updateSelectedProcess;

- (void) downloadsPathClosed: (NSOpenPanel *) openPanel returnCode: (int) code contextInfo: (void *) info;

@end

@implementation ProcessPreferencesController


- (void) awakeFromNib
{
//	[_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[self updateSelectedProcess];
}

//NSTableViewDataSource stuff
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	ProcessDescriptor* pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex:rowIndex];
	return [pd name];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[ProcessesController sharedProcessesController] count];
}

- (void) tableViewSelectionDidChange: (NSNotification *) notification
{
    [self updateSelectedProcess];
}


- (void) controlTextDidEndEditing: (NSNotification *) notification
{
	ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex:[_tableView selectedRow]];
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
		[pd setSshLocalPort:[_sshLocalPort stringValue]];
    }
	else;
	
	[[ProcessesController sharedProcessesController] saveProcesses];
}


-(void) toggleManualConfig:(id) sender
{
	BOOL s = [_manualConfig state];
	[_host setEnabled:s];
	[_port setEnabled:s];
	ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex:[_tableView selectedRow]];
	[pd setManualConfig:s];
	[[ProcessesController sharedProcessesController] saveProcesses];
}

-(void) toggleConnectionDetails:(id) sender
{
	NSString* connType = [_connectionType titleOfSelectedItem];
	if ([connType isEqualToString:@"SSH"])
	{
		[_sshConfig setHidden:NO];
		[_sshAdvancedConfig setHidden:NO];
	}
	else
	{
		[_sshConfig setHidden:YES];
		[_sshAdvancedConfig setHidden:YES];
	}
	
	ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex:[_tableView selectedRow]];
	[pd setConnectionType:connType];
	[[ProcessesController sharedProcessesController] saveProcesses];
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
@end

@implementation ProcessPreferencesController(Private)
-(void)updateSelectedProcess
{
//    [fAddRemoveControl setEnabled: [fTableView numberOfSelectedRows] > 0 forSegment: REMOVE_TAG];
    if ([_tableView numberOfSelectedRows] == 1)
    {
        ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex: [_tableView selectedRow]];
		
		[_processType setStringValue:[pd processType]];
		[_processType setEnabled:YES];
		
		[_manualConfig setState: [pd manualConfig]];
		[_manualConfig setEnabled:YES];

		[_host setStringValue:[pd host]];
		[_host setEnabled:YES];

		[_port setIntValue:[pd port]];
		[_port setEnabled:YES];
		
		[_downloadsPathPopUp removeItemAtIndex:0];
		[_downloadsPathPopUp insertItemWithTitle:pd.downloadsFolder==nil?@"":pd.downloadsFolder atIndex:0];
		[_downloadsPathPopUp selectItemAtIndex: 0];
		[_downloadsPathPopUp setEnabled:YES];
		
		[_connectionType selectItemAtIndex: [pd.connectionType isEqualToString:@"SSH"]?1:0];
		[_connectionType setEnabled:YES];
		//for some reason it do not want call automatically
		[self toggleConnectionDetails:_connectionType];
		
		[_sshHost setStringValue:pd.sshHost];
		[_sshHost setEnabled:YES];
		
		[_sshPort setStringValue:pd.sshPort];
		[_sshPort setEnabled:YES];
#warning store in keychain		
		[_sshUsername setStringValue:pd.sshUsername];
		[_sshUsername setEnabled:YES];
		
		[_sshPassword setStringValue:pd.sshPassword];
		[_sshPassword setEnabled:YES];
		
		[_sshLocalPort setStringValue:pd.sshLocalPort];
		[_sshLocalPort setEnabled:YES];

    }
    else
    {
		[_processType setStringValue:@""];
		[_processType setEnabled:NO];
		
		[_manualConfig setEnabled:NO];
		
		[_host setStringValue:@""];
		[_host setEnabled:NO];
		
		[_port setIntValue:0];
		[_port setEnabled:NO];
		
		[_downloadsPathPopUp removeItemAtIndex:0];
		[_downloadsPathPopUp insertItemWithTitle:@" " atIndex:0];
		[_downloadsPathPopUp selectItemAtIndex: 0];
		[_downloadsPathPopUp setEnabled:NO];

		[_connectionType selectItemAtIndex: 0];
		[_connectionType setEnabled:NO];
    }
}

- (void) downloadsPathClosed: (NSOpenPanel *) openPanel returnCode: (int) code contextInfo: (void *) info
{
    if (code == NSOKButton)
    {
        ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex: [_tableView selectedRow]];
		
		NSString * folder = [[openPanel filenames] objectAtIndex: 0];

		[_downloadsPathPopUp removeItemAtIndex:0];

		[_downloadsPathPopUp insertItemWithTitle:folder atIndex:0];
		
		[pd setDownloadsFolder:folder];
		
		[[ProcessesController sharedProcessesController] saveProcesses];

    }
    [_downloadsPathPopUp selectItemAtIndex: 0];
}
@end