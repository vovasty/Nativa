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
@end

@implementation ProcessPreferencesController



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
	else;
	
	[[ProcessesController sharedProcessesController] saveProcesses];
}

@end

@implementation ProcessPreferencesController(Private)
-(void)updateSelectedProcess
{
//    [fAddRemoveControl setEnabled: [fTableView numberOfSelectedRows] > 0 forSegment: REMOVE_TAG];
    if ([_tableView numberOfSelectedRows] == 1)
    {
        ProcessDescriptor *pd = [[ProcessesController sharedProcessesController] processDescriptorAtIndex: [_tableView selectedRow]];
		
		[_processType setStringValue:[pd name]];
		[_processType setEnabled:YES];
		
		[_manualConfig setState: [pd manualConfig]];
		[_manualConfig setEnabled:YES];

		[_host setStringValue:[pd host]];
		[_host setEnabled:YES];

		[_port setIntValue:[pd port]];
		[_port setEnabled:YES];
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
    }
}
@end