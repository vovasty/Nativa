//
//  ProcessPreferencesController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 03.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ProcessDescriptor;

@interface ProcessPreferencesController : NSObject
{
	IBOutlet NSTextField *_host;
	
	IBOutlet NSTextField *_port;
	
	IBOutlet NSPopUpButton * _downloadsPathPopUp;
	
	IBOutlet NSWindow *_window;
	
	IBOutlet NSButton * _useSSH;
	
	IBOutlet NSTextField * _sshHost;
	
	IBOutlet NSTextField * _sshPort;
	
	IBOutlet NSTextField * _sshUsername;
	
	IBOutlet NSTextField * _sshPassword;
	
	IBOutlet NSTextField * _sshLocalPort;
	
	IBOutlet NSTextField * _groupCustomField;
	
	BOOL useSSHTunnel;
	
	ProcessDescriptor* unsavedProcessDescriptor;
}

@property BOOL useSSHTunnel;

- (void) downloadsPathShow: (id) sender;

- (void) toggleSSH: (id) sender;

- (void) saveProcess: (id) sender;
@end
