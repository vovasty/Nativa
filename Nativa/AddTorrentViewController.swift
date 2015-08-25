//
//  AddTorrentViewController.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 9/30/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class AddTorrentViewController:NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate
{
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var torrentName: NSTextField!
    @IBOutlet weak var torrentIcon: NSImageView!
    private var outlineController: FileOutlineViewController?
    private var path: String?
    private var torrent: Download!
    
    override func viewDidLoad() {
        outlineController = FileOutlineViewController(outlineView: self.outlineView, torrent: torrent!)
        let fileNameNib = NSNib(nibNamed: "FileName", bundle: nil)
        self.outlineView.registerNib(fileNameNib!, forIdentifier: "FileNameCell")
        let folderNameNib = NSNib(nibNamed: "FolderName", bundle: nil)
        self.outlineView.registerNib(folderNameNib!, forIdentifier: "FolderNameCell")
        self.torrentName.stringValue = self.torrent!.title
        self.torrentIcon.image = self.torrent!.icon
    }
    
    override func viewDidAppear() {
        NSApp.activateIgnoringOtherApps(true)
    }
    
    func setTorrent(torrent: Download, path:String)
    {
        self.torrent = torrent
        self.path = path
        self.title = torrent.title
    }
    
    @IBAction func add(sender: AnyObject) {
        do {
            try Datasource.instance.addTorrentFiles([(path: path!, download: torrent)])
        }
        catch let e {
            print("unable to add files \(e)")
        }
        
        if let window = self.view.window {
            window.performClose(sender)
        }
    }
    
    
    @IBAction func cancelAdd(sender: AnyObject) {
        if let window = self.view.window {
            window.performClose(sender)
        }
    }
}
