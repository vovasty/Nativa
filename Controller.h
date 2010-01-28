//
//  Controller.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TorrentDropView;
@interface Controller : NSObject {
	IBOutlet TorrentDropView* _dropView;
}

@end
