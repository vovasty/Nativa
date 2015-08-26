//
//  AddTorrentViewController.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 9/30/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class AddTorrentViewController: FileOutlineViewController {
    @IBOutlet weak var torrentName: NSTextField!
    @IBOutlet weak var torrentIcon: NSImageView!
    private var path: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.outlineView.reloadData()
        self.torrentName.stringValue = self.download!.title
        self.torrentIcon.image = self.download!.icon
    }

    override func viewDidAppear() {
        NSApp.activateIgnoringOtherApps(true)
    }
    
    func setDownload(download: Download, path: String)
    {
        self.download = download
        self.path = path
        self.torrentName?.stringValue = self.download!.title
        self.torrentIcon?.image = self.download!.icon
        title = download.title
    }
    
    @IBAction func add(sender: AnyObject) {
        do {
            try Datasource.instance.addTorrentFiles([(path: path!, download: download!)])
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
