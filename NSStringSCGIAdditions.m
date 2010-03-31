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

#import "NSStringSCGIAdditions.h"

@implementation NSString (NSStringSCGIAdditions)
- (NSData *) encodeSCGI
{
	NSString* header = [[NSString alloc] initWithFormat:@"CONTENT_LENGTH\0%d\0SCGI\01\0", [self length]];
	
	NSString* data = [[NSString alloc] initWithFormat:@"%i:%@,%@", [header length], header, self];
	
	NSData* result = [data dataUsingEncoding: NSUTF8StringEncoding];
	
	[header release];
	
	[data release];
	
	return result;
	
}
@end