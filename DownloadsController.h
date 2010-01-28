//
//  DownloadsController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 27.01.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

static NSString* NOTIFY_UPDATE_DOWNLOADS = @"NativaUpdateDownloads";
@interface DownloadsController : NSObject {
@private
	NSMutableArray* _downloads;
	NSTimer* _timer;
}
+ (DownloadsController *)sharedDownloadsController;
-(void) start;
-(void) stop;
-(NSArray*) downloads;
@end

