//
//  NativaAppDelegate.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 07.01.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TorrentTableView;

@interface NativaAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
