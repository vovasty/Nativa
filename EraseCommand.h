//
//  EraseCommand.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 14.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StartCommand.h"

@interface EraseCommand : StartCommand
+ (id)command:(NSString *)hash response:(VoidResponseBlock) resp;
@end
