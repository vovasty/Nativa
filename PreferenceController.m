//
//  PreferenceController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 28.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "PreferenceController.h"
NSString* const NITurtleSpeedKey = @"TurtleSpeed";

@implementation PreferenceController
-(id)init
{
	if (![super initWithWindowNibName:@"Preferences"]) 
		return nil;
	return self;
}

-(void)windowDidLoad
{
	[_turtleSpeed setIntValue:[self turtleSpeed]];
}

- (IBAction)changeTurtleSpeed:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:[_turtleSpeed intValue] forKey:NITurtleSpeedKey];
}

- (int) turtleSpeed
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults integerForKey:NITurtleSpeedKey];
}
@end
