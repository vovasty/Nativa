//
//  StatusbarController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 29.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StatusbarController : NSObject 
{
	IBOutlet NSTextField	* _globalSpeedDown;
	IBOutlet NSTextField	* _globalSpeedUp;
	IBOutlet NSButton		* _statusButton;
	IBOutlet NSImageView    * _totalDLImageView;
	NSString				*_currentObserver;
}
- (void) setStatusLabel: (id) sender;
@end
