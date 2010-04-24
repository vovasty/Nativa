//
//  NSStringRTorrentAdditions.m
//  Nativa
//
//  Created by Vladimir Solomenchuk on 23.04.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import "NSStringRTorrentAdditions.h"


@implementation  NSString (NSStringRTorrentAdditions)
- (NSString *) urlEncode
{
	return (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
														(CFStringRef)self,
														NULL,
														(CFStringRef)@"!*'();:@&=+$,/?%#[]",
														kCFStringEncodingUTF8 );
}
- (NSString *) urlDecode
{
    return (NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault,
                                                           (CFStringRef)self,
                                                           CFSTR(""));
}
@end
