//
//  RTSetGlobalUploadSpeedLimitCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 25.02.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "RTSetGlobalUploadSpeedLimitCommand.h"


@implementation RTSetGlobalUploadSpeedLimitCommand
- (NSString *) command;
{
	return @"set_upload_rate";
}
@end
