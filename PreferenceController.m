//
//  PreferenceController.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 28.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "PreferenceController.h"

NSString* const NISpeedLimitDownload = @"SpeedLimitDownload";
NSString* const NISpeedLimitUpload = @"SpeedLimitUpload";

NSString* const NITrashDownloadDescriptorsKey = @"TrashDownloadDescriptorsKey";

@implementation PreferenceController
-(id)init
{
	if (![super initWithWindowNibName:@"Preferences"]) 
		return nil;
	return self;
}

-(void)windowDidLoad
{
}

@end
