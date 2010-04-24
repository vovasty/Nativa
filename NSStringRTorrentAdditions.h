//
//  NSStringRTorrentAdditions.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 23.04.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface  NSString (NSStringRTorrentAdditions)
- (NSString *) pathEncode;
- (NSString *) urlEncode;
- (NSString *) urlDecode;
@end
