/******************************************************************************
 * $Id: TorrentTableView.h 9844 2010-01-01 21:12:04Z livings124 $
 *
 * Copyright (c) 2005-2010 Transmission authors and contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *****************************************************************************/

#import <Cocoa/Cocoa.h>

@class Controller;
@class Torrent;
@class TorrentCell;

#define GROUP_SEPARATOR_HEIGHT 18.0

@class Controller;

@interface TorrentTableView : NSOutlineView
{
    IBOutlet Controller *_controller;
    
    TorrentCell * fTorrentCell;
    
    NSUserDefaults * fDefaults;
    
    NSMutableIndexSet * fCollapsedGroups;
    
    NSInteger fMouseControlRow, fMouseRevealRow, fMouseGroupRow, fMouseActionRow, fActionPushedRow, fGroupPushedRow;
    NSArray * fSelectedValues;
    
    Torrent * fMenuTorrent;
    
    CGFloat fPiecesBarPercent;
    NSAnimation * fPiecesBarAnimation;
}

- (BOOL) isGroupCollapsed: (NSInteger) value;
- (void) removeCollapsedGroup: (NSInteger) value;
- (void) removeAllCollapsedGroups;
- (void) saveCollapsedGroups;

- (void) removeButtonTrackingAreas;
- (void) setGroupButtonHover: (NSInteger) row;
- (void) setControlButtonHover: (NSInteger) row;
- (void) setRevealButtonHover: (NSInteger) row;
- (void) setActionButtonHover: (NSInteger) row;

- (void) selectValues: (NSArray *) values;
- (NSArray *) selectedValues;
- (NSArray *) selectedTorrents;

- (NSRect) iconRectForRow: (NSInteger) row;

- (void) toggleControlForTorrent: (Torrent *) torrent;

- (void) displayGroupMenuForEvent: (NSEvent *) event;

- (CGFloat) piecesBarPercent;
@end
