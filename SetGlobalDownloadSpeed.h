//
//  SetGlobalDownloadSpeed.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 28.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RTorrentCommand.h"

@interface SetGlobalDownloadSpeed : NSObject<RTorrentCommand> 
{
	VoidResponseBlock _response;
	int _speed;
}
@property (retain) VoidResponseBlock response;
@property (assign) int speed;

- (id)initWithSpeedAndResponse:(int)speed response:(VoidResponseBlock) resp;

@end
