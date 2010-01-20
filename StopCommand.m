//
//  StartCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 13.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "StopCommand.h"


@implementation StopCommand
+ (id)command:(NSString *)hash response:(VoidResponseBlock) resp;
{
	StopCommand * operation = [[self alloc] initWithHashAndResponse:hash response:resp];
    return [operation autorelease];
}

- (NSString *) command;
{
	return @"d.stop";
}
@end
