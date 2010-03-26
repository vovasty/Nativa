/*
 * Nativa - MacOS X UI for rtorrent
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
 */

#import <Cocoa/Cocoa.h>
#import "TorrentController.h"
#import "Torrent.h"

extern NSString* const NINotifyUpdateDownloads;

@class RTorrentController, Torrent;

@interface DownloadsController : NSObject 
{
@private
	NSMutableArray	* _downloads;
	NSTimer			* _updateListTimer;
	NSTimer			* _updateGlobalsTimer;
	CGFloat			  _globalUploadSpeed;
	CGFloat			  _globalDownloadSpeed;
	CGFloat			  _spaceLeft;
	CGFloat			  _globalUploadSize;
	CGFloat			  _globalDownloadSize;
	CGFloat			  _globalRatio;
	NSUserDefaults	* _defaults;
	int			      openedProcesses;
	NSString		* lastOpenProcessError;
}
@property (assign)	CGFloat globalUploadSpeed;
@property (assign)	CGFloat globalDownloadSpeed;
@property (assign)	CGFloat spaceLeft;
@property (assign)	CGFloat globalDownloadSize;
@property (assign)	CGFloat globalUploadSize;
@property (assign)	CGFloat globalRatio;


+ (DownloadsController *)sharedDownloadsController;

-(void) startUpdates:(VoidResponseBlock) response;

-(void) stopUpdates;

-(NSArray*) downloads;

- (void) start:(NSString *) hash response:(VoidResponseBlock) response;

- (void) stop:(NSString *) hash response:(VoidResponseBlock) response;

- (void) add:(NSArray *) filesNames;

- (void) erase:(Torrent *) torrent response:(VoidResponseBlock) response;

- (void) setGlobalDownloadSpeedLimit:(int) speed response:(VoidResponseBlock) response;

- (void) getGlobalDownloadSpeedLimit:(NumberResponseBlock) response;

- (void) setGlobalUploadSpeedLimit:(int) speed response:(VoidResponseBlock) response;

- (void) reveal:(Torrent*) torrent;

- (void) setPriority:(Torrent *)torrent  priority:(TorrentPriority)priority response:(VoidResponseBlock) response;

- (void) setGroup:(Torrent *)torrent group:(NSString *) group response:(VoidResponseBlock) response;

-(NSString*) findLocation:(Torrent *)torrent;
@end

