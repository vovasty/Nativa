
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
    @IBOutlet weak var processesButton: NSPopUpButton!
    private var path: URL?
    @objc var processId: String?
    @objc var hideProcessList: Bool {
        return Datasource.instance.processes.count == 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.outlineView.reloadData()
        self.torrentName.stringValue = self.download!.title
        self.torrentIcon.image = self.download!.icon
        
        processesButton.removeAllItems()
        processesButton.autoenablesItems = false
        for process in Datasource.instance.processes {
            processesButton.addItem(withTitle: process.0)
            
            if case DatasourceConnectionStatus.Established = process.1.state {
                processesButton.itemArray.last?.isEnabled = true
                if processId == nil { //select first available process
                    processId = process.0
                    processesButton.selectItem(withTitle: processId!)
                }
            }
            else {
                processesButton.itemArray.last?.isEnabled = false
            }
        }
    }

    override func viewDidAppear() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setDownload(download: Download, path: URL)
    {
        self.download = download
        self.path = path
        self.torrentName?.stringValue = self.download!.title
        self.torrentIcon?.image = self.download!.icon
        title = download.title
    }
    
    @objc
    @IBAction
    private func add(_ sender: AnyObject) {
        if let processId = processId {
            //to prevent capturing self
            guard let path = self.path else { return }
            let start = UserDefaults.standard.bool(forKey: "downloadStartWhenAdded")
            Datasource.instance.addTorrentFiles(processId: processId, files: [(path: path, download: download!, start: start, group: nil, folder: nil, priorities: flatPriorities)]) {
                if UserDefaults.standard.bool(forKey: "downloadTrashTorrentFile") {
                    do {
                        try FileManager.default.trashPath(path: path)
                    }
                    catch {
                        logger.error("unable to remove torrent file: \(error)")
                    }
                }
            }
        }
        
        if let window = self.view.window {
            window.performClose(sender)
        }
    }
    
    @objc
    @IBAction
    private func cancelAdd(_ sender: AnyObject) {
        if let window = self.view.window {
            window.performClose(sender)
        }
    }
}
