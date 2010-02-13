//
//  GetGlobalDownloadSpeed.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 29.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

@interface RTGetGlobalDownloadSpeedLimitCommand : NSObject<RTorrentCommand> 
{
	NumberResponseBlock _response;
}
@property (retain) NumberResponseBlock response;

- (id)initWithResponse:(NumberResponseBlock) resp;

@end