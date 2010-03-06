//
//  QuickLookController.h
//  Nativa
//
//  Created by Vladimir Solomenchuk on 05.03.10.
//  Copyright 2010 aramzamzam.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "TorrentTableView.h"

@interface QuickLookController : NSObject<QLPreviewPanelDataSource, QLPreviewPanelDelegate> 
{
	QLPreviewPanel* _panel;
	TorrentTableView* _view;
	NSWindow* _window;
}
+(QuickLookController*) sharedQuickLookController;
+(void)show;
-(void) beginPanel:(QLPreviewPanel*) panel window:(NSWindow*)window view:(TorrentTableView*) _downloadsView;
-(void) endPanel;
@end
