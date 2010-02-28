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

- (NSInteger) currentProcess;
@end

@implementation ProcessPreferencesController

@synthesize useSSHTunnel;

- (void) awakeFromNib
{
	[self updateSelectedProcess];
}


- (void) controlTextDidEndEditing: (NSNotification *) notification
{
	ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex:[self currentProcess]];
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


-(void) toggleSSH:(id) sender
{
	ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex:[self currentProcess]];
	[pd setConnectionType:[_useSSH state]==NSOnState?@"SSH":@"Local"];
	[[ProcessesController sharedProcessesController] saveProcesses];

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
	[[SaveProgressController sharedSaveProgressController] open: _window];
	ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex: [self currentProcess]];
	[pd openProcess];

	ArrayResponseBlock response = [^(NSArray *array, NSString* error) {
		if (error != nil)
		{
			NSLog(@"update download list error: %@", error);
			[[SaveProgressController sharedSaveProgressController] message: error];
		}
		else
			[[SaveProgressController sharedSaveProgressController] close:nil];
		[pd closeProcess];
	} copy];
	[[pd process] list:response];
	[response release];
}
@end

@implementation ProcessPreferencesController(Private)
-(void)updateSelectedProcess
{
    ProcessDescriptor *pd = nil;
	if ([[ProcessesController sharedProcessesController] count]>[self currentProcess])
		pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex: [self currentProcess]];
	if (pd)
	{
		
		[_host setStringValue:[pd host]];

		[_port setIntValue:[pd port]];
		
		[_downloadsPathPopUp removeItemAtIndex:0];
		[_downloadsPathPopUp insertItemWithTitle:pd.downloadsFolder==nil?@"":pd.downloadsFolder atIndex:0];
		[_downloadsPathPopUp selectItemAtIndex: 0];
	
		[_useSSH setState:[pd.connectionType isEqualToString:@"SSH"]? NSOnState: NSOffState];
		
		[_sshHost setStringValue:pd.sshHost];
		
		[_sshPort setStringValue:pd.sshPort];
#warning store in keychain		
		[_sshUsername setStringValue:pd.sshUsername];
		
		[_sshPassword setStringValue:pd.sshPassword];
	
		[_sshLocalPort setStringValue:pd.sshLocalPort];

		//for some reason I need trigger event manually
		[self toggleSSH:_useSSH];
	}
	else
	{
		pd = [[ProcessDescriptor alloc] init];
		[[ProcessesController sharedProcessesController] addProcessDescriptor:pd];
	}
}

- (void) downloadsPathClosed: (NSOpenPanel *) openPanel returnCode: (int) code contextInfo: (void *) info
{
    if (code == NSOKButton)
    {
        ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex: [self currentProcess]];
		
		NSString * folder = [[openPanel filenames] objectAtIndex: 0];

		[_downloadsPathPopUp removeItemAtIndex:0];

		[_downloadsPathPopUp insertItemWithTitle:folder atIndex:0];
		
		[pd setDownloadsFolder:folder];
		
		[[ProcessesController sharedProcessesController] saveProcesses];

    }
    [_downloadsPathPopUp selectItemAtIndex: 0];
}

- (NSInteger) currentProcess
{
	return 0;
}
@end