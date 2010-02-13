//
//  StartCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "RTStopCommand.h"


@implementation RTStopCommand
- (NSString *) command;
{
	return @"d.stop";
}
@end
