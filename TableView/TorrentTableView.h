/*
     File: TorrentTableView.h 
 Abstract: An NSTableView subclass that adds delegate extensions for lazily batch loading cell contents, sub-view support, and multi-valued properties.
  
  Version: 1.0 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2009 Apple Inc. All Rights Reserved. 
  
*/

#import <Cocoa/Cocoa.h>

@protocol TorrentTableViewDelegate;

@interface TorrentTableView : NSTableView {
@private
    // The _visibleRows is a cache of the rows that are currently displaying. We inform the delegate when they change
    NSRange _visibleRows;
    // _viewsInVisibleRows is a record of the views that we are currently displaying. The key is an NSNumber with the row index. We only ever keep track of views that are in our _visibleRows, and remove others that aren't seen.
    NSMutableDictionary *_viewsInVisibleRows;
    BOOL _viewsNeedUpdate;
}

@property(assign) id <TorrentTableViewDelegate> delegate;

@end

// We declare some extra protocol messages to let the delegate know when the visible rows are changing.
// It is important to create a delegate signature that will not conflict with standard Cocoa delegate signatures. In short, that means don't use the prefix "tableView:".
@protocol TorrentTableViewDelegate <NSTableViewDelegate>
@optional

// We want to give the delegate a change to pre-load things given a new visible row set. In addition, it could stop loading previous things that have scrolled off screen and weren't fully loaded yet.
- (void)dynamicTableView:(TorrentTableView *)tableView changedVisibleRowsFromRange:(NSRange)oldVisibleRows toRange:(NSRange)newVisibleRows;

// Allows the delegate to give a custom view back for a particular row. The view's frame should be properly set based on the rectOfRow:. This could easily be extended to a row/column matrix.
- (NSView *)dynamicTableView:(TorrentTableView *)tableView viewForRow:(NSInteger)row;

@end
