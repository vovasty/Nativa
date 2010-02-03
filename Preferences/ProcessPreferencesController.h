//
//  ProcessPreferencesController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 03.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ProcessDescriptor;

@interface ProcessPreferencesController : NSObject<NSTableViewDataSource, NSTableViewDelegate>
{
	IBOutlet NSTableView *_tableView;
	
	IBOutlet NSTextField *_processType;
	
	IBOutlet NSButton *_manualConfig;
	
	IBOutlet NSTextField *_host;
	
	IBOutlet NSTextField *_port;
}

-(IBAction) toggleManualConfig:(id) sender;
@end
