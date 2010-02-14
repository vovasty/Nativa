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
	
	IBOutlet NSPopUpButton * _downloadsPathPopUp;
	
	IBOutlet NSWindow *_window;
	
	IBOutlet NSView *_sshConfig;
	
	IBOutlet NSPopUpButton * _connectionType;
	
	IBOutlet NSTextField * _sshHost;
	
	IBOutlet NSTextField * _sshPort;
	
	IBOutlet NSTextField * _sshUsername;
	
	IBOutlet NSTextField * _sshPassword;
	
	IBOutlet NSView *_sshAdvancedConfig;

	IBOutlet NSTextField * _sshLocalPort;
}

- (void) toggleManualConfig:(id) sender;

- (void) downloadsPathShow: (id) sender;

- (void) toggleConnectionDetails: (id) sender;

@end
