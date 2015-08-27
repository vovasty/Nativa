//
//  DownloadDropView.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 10/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa
import Common

protocol DropViewDelegate {
    func completeDragToView(view: DownloadDropView, torrents: [(path: String, download: Download)])
}

class DownloadDropView: NSView {
    var torrents: [(path: String, download: Download)] = []
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
        torrents = []
        
        if let types = pboard.types {
            if types.indexOf(NSFilenamesPboardType) != nil {
                if let files = pboard.propertyListForType(NSFilenamesPboardType) as? [String] {
                    let torrentFiles = files.filter{
                        
                        do {
                            let t = try NSWorkspace.sharedWorkspace().typeOfFile($0)
                            return t ==  "org.bittorrent.torrent"
                                || $0.pathExtension.caseInsensitiveCompare("torrent") == NSComparisonResult.OrderedSame
                        }
                        catch {
                            return false
                        }
                    }
                    
                    if torrentFiles.count > 0 {
                        
                        do {
                            if let parsedTorrents = try Datasource.instance.parseTorrents(torrentFiles) {
                                for i in 0 ... parsedTorrents.count - 1 {
                                    let key = torrentFiles[i]
                                    let value = parsedTorrents[i]
                                    torrents.append((path: key, download: value))
                                }
                                return .Copy
                            }
                        }
                        catch let e {
                            logger.error("unable to add files \(e)")
                        }
                    }
                }
            }
        }

        return .None
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        delegate?.completeDragToView(self, torrents: torrents)
        return true
    }
}