//
//  ToolbarController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 29.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Controller.h"

@class Torrent;

@interface Controller(ToolbarControllerAdditions)
-(IBAction)selectedToolbarClicked:(id)sender;
@end
