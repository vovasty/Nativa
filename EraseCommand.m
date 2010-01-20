//
//  EraseCommand.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 14.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "EraseCommand.h"


@implementation EraseCommand
+ (id)command:(NSString *)hash response:(VoidResponseBlock) resp;
{
	EraseCommand* operation = [[self alloc] initWithHashAndResponse:hash response:resp];
    return [operation autorelease];
}

- (NSString *) command;
{
	return @"d.erase";
}
@end