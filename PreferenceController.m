//
//  PreferenceController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 28.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "PreferenceController.h"


@implementation PreferenceController
-(id)init
{
	if (![super initWithWindowNibName:@"Preferences"]) 
		return nil;
	return self;
}

-(void)windowDidLoad
{
//init here
}

- (IBAction)changeTurtleSpeed:(id)sender
{
	NSLog(@"turtleSpeed: %d", [_turtleSpeed intValue]);
}
@end
