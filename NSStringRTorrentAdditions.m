//
//  NSStringRTorrentAdditions.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 23.04.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "NSStringRTorrentAdditions.h"


@implementation  NSString (NSStringRTorrentAdditions)
- (NSString *) pathEncode
{
    return [NSString stringWithFormat:@"\"%@\"",self];
}

- (NSString *) urlEncode
{
    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                           (CFStringRef)self,
                                                                           NULL,
                                                                           (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                           kCFStringEncodingUTF8 );
	return [result autorelease];
}
- (NSString *) urlDecode
{
    return (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault,
                                                           (CFStringRef)self,
                                                           CFSTR(""));
}
@end
