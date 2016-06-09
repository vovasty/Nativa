//
//  DownloadDropView.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 10/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

protocol DropViewDelegate {
    func completeDragToView(view: DownloadDropView, torrents: [(path: NSURL, download: Download)])
}

private var parseTorrentsLock: OSSpinLock = OS_SPINLOCK_INIT

class DownloadDropView: NSView {
    private var torrentFiles: [NSURL] = []
    var delegate: DropViewDelegate?
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.registerForDraggedTypes([NSFilenamesPboardType])
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.registerForDraggedTypes([NSFilenamesPboardType])
    }
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        let pboard = sender.draggingPasteboard()
        guard let files = pboard.propertyListForType(NSFilenamesPboardType) as? [String] else { return .None }

        torrentFiles = files.filter{
                do {
                    let t = try NSWorkspace.sharedWorkspace().typeOfFile($0)
                    return t ==  "org.bittorrent.torrent"
                    || $0.pathExtension.caseInsensitiveCompare("torrent") == NSComparisonResult.OrderedSame
                }
                catch {
                    return false
                }
            }
            .map{ (path) -> NSURL in
                return NSURL(fileURLWithPath: path)
            }
        
        return self.torrentFiles.count > 0 ? .Copy : .None
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        Datasource.instance.parseTorrents(torrentFiles){ (parsedTorrents, error) -> Void in
            guard let parsedTorrents = parsedTorrents where error == nil else{
                logger.error("unable to parse torrents \(error)")
                return
            }
            
            var nonExisingTorrents: [(path: NSURL, download: Download)] = []
            for torrent in parsedTorrents {
                guard !Datasource.instance.downloads.contains(torrent.download) else{
                    continue
                }
                
                nonExisingTorrents.append(torrent)
            }
            
            dispatch_main {
                self.delegate?.completeDragToView(self, torrents: nonExisingTorrents)
            }
        }

        return true
    }
}