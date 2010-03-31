/******************************************************************************
 * Nativa - MacOS X UI for rtorrent
 * http://www.aramzamzam.net
 *
 * Copyright Solomenchuk V. 2010.
 * Solomenchuk Vladimir <vovasty@aramzamzam.net>
 *
 * Licensed under the GPL, Version 3.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.gnu.org/licenses/gpl-3.0.html
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************/

#import "RTAddCommand.h"


@implementation RTAddCommand
@synthesize url = _url;
@synthesize response = _response;
@synthesize start = _start;

- (id)initWithUrlAndResponse:(NSURL *)url start:(BOOL) start response:(VoidResponseBlock) resp;
{
    self = [super init];
    if (self == nil)
        return nil;
    
    _url = [url retain];
    _response = [resp retain];
	_start = start;
    return self;
}


- (void) processResponse:(id) data error:(NSString *) error;
{
	if (_response)
		_response(error);
}

- (NSString *) command;
{
	return _start ? @"load_raw_start" : @"load_raw";
}

- (NSArray *) arguments;
{
	if (_arguments == nil)
	{
		NSURLRequest* request = [NSURLRequest requestWithURL:_url];
		NSURLResponse *returningResponse = nil;
		NSError* connError = nil;
		NSData *content = [NSURLConnection sendSynchronousRequest:request returningResponse:&returningResponse error:&connError];
#warning incorrect error handling
		//	NSLog(@"%Q", returningResponse);
		_arguments = [NSArray arrayWithObjects:content, nil];
		[_arguments retain];
	}
	return _arguments;
}

- (void)dealloc
{
	[_response release];
	[_url release];
	[_arguments release];
	[super dealloc];
}
@end
