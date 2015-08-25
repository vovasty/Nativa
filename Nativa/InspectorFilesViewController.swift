//
//  TorrentFiles.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/21/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class InspectorFilesViewController: NSViewController, InspectorViewControllerPanel, FileOutlineViewControllerDelegate {
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet var outlineController: FileOutlineViewController!
    
    var download: Download? {
        didSet {
            outlineController.torrent = download
            outlineController.delegate = self
            self.outlineView.reloadData()
        }
    }
    
    func fileOutlineViewController(controller: FileOutlineViewController, didChangeFilePriorities priorities:[FileListNode: Int]) {
        
        Datasource.instance.setFilePriority(download!, priorities: priorities) { (error) -> Void in
            print(error)
        }
        
    }
}