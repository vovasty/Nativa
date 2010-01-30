//
//  GetGlobalDownloadSpeed.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 29.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "GetGlobalDownloadSpeed.h"


@implementation GetGlobalDownloadSpeed
- (NSString *) command;
{
	return @"get_down_rate";
}
@end
