//
//  downloadsViewController.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

struct SelectedDownloadsNotification: Notification {
    let downloads: [Download]
}

class DownloadsViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, DropViewDelegate
{
    @IBOutlet weak var outlineView: NSOutlineView!
    var torrents: IndexingGenerator<Array<(path: NSURL, download: Download)>>?
    private var downloadsObserver: String?

    var selectedDownloads: [Download] {
        
        
        return self.outlineView.selectedRowIndexes
            .map{ (e) -> Download? in
                return outlineView.itemAtRow(e) as? Download
                }
            .filter{ (e) -> Bool in
                    e != nil
            }
            .map{ (e) -> Download in
                e!
            }
    }
    
    
    override func awakeFromNib() {
        if let view = self.view as? DownloadDropView {
            view.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadsObserver = Datasource.instance.downloads.addObserver({ (downloadChanges: [(object: Download, index: Int, type: ChangeType)]) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.outlineView.beginUpdates()
                for downloadChange in downloadChanges {
                    let indexes = NSIndexSet(index: downloadChange.index)
                    switch downloadChange.type {
                    case .Delete:
                        self.outlineView.removeItemsAtIndexes(indexes, inParent: nil, withAnimation: NSTableViewAnimationOptions.SlideUp)
                    case .Insert:
                        self.outlineView.insertItemsAtIndexes(indexes, inParent: nil, withAnimation: NSTableViewAnimationOptions.SlideDown)
                    case .Update:
                        //cause reloadItem is not working...
                        let row = self.outlineView.rowForItem(downloadChange.object)
                        self.outlineView.setNeedsDisplayInRect(self.outlineView.rectOfRow(row))
                        break
                    }
                }
                self.outlineView.endUpdates()
            })
        })
        
        notificationCenter.add(self) { [weak self] (note: DownloadFilesAddedNotification) -> Void in
            self?.addTorrents(note.downloads)
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        //to unify toolbar and titlebar
        self.view.window?.titleVisibility = .Hidden
    }

    @IBAction func controlAction(sender: AnyObject) {
        let row = self.outlineView.rowForView(sender as! NSView)
        let download = self.outlineView.itemAtRow(row) as! Download

        switch (download.state)
        {
        case .Stopped, .Paused:
            download.state = .Downloading(dl: 0, ul: 0)
            Datasource.instance.startDownload(download)
        default:
            Datasource.instance.stopDownload(download)
        }
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int
    {
        if let group = item as? Group {
            return group.downloads.count
        }
        else
        {
            return Datasource.instance.downloads.count
        }
    }
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool
    {
        return item is Group
    }

    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject
    {
        if let group = item as? Group {
            return group.downloads[index]
        }
        else {
            return Datasource.instance.downloads[index]
        }
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView?
    {
        if let group = item as? Group {
            let result: GroupCell! = outlineView.makeViewWithIdentifier("GroupCell", owner:self) as? GroupCell;
            result.group = group
            return result;
        }
        else if let download = item as? Download{
            let result: DownloadCell! = outlineView.makeViewWithIdentifier("DownloadCell", owner:self) as? DownloadCell;
            result.download = download
            return result;
        }

        return nil
    }
    
    func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat
    {
        if item is Group {
            return 20
        }
        else {
            return DownloadCell.height
        }
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        notificationCenter.post(SelectedDownloadsNotification(downloads: self.selectedDownloads))
    }
    
    //NSSeguePerforming
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier!{
        case "showAddTorrent":
            if  let torrent = torrents?.next(),
                let vc = segue.destinationController as? AddTorrentViewController {
                    vc.setDownload(torrent.download, path: torrent.path)
            }
        default:
            break
        }
    }
    
    private func addTorrents(torrents: [(path: NSURL, download: Download)]) {
        self.torrents = torrents.generate()
        for _ in 0 ... torrents.count - 1 {
            self.performSegueWithIdentifier("showAddTorrent", sender: nil)
        }
    }
    
    //DropViewDelegate
    func completeDragToView(view: DownloadDropView, torrents: [(path: NSURL, download: Download)]) {
        addTorrents(torrents)
    }
    
    @IBAction func removeDownload(sender: AnyObject) {
        for index in outlineView.selectedRowIndexes {
            if let download = outlineView.itemAtRow(index) as? Download {
                Datasource.instance.removeTorrent(download, removeData: false, response: { (error) -> Void in
                    logger.error("unable to remove torrent: \(error)")
                })
            }
        }
    }
    
    @IBAction func removeDownloadWithData(sender: AnyObject) {
        for index in outlineView.selectedRowIndexes {
            if let download = outlineView.itemAtRow(index) as? Download {
                Datasource.instance.removeTorrent(download, removeData: true, response: { (error) -> Void in
                    logger.error("unable to remove torrent: \(error)")
                })
            }
        }
    }

    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        return outlineView.selectedRowIndexes.count > 0
    }
    
    
    override func validateToolbarItem(theItem: NSToolbarItem) -> Bool {
        return outlineView.selectedRowIndexes.count > 0
    }
    
    deinit {
        if let downloadsObserver = downloadsObserver {
            Datasource.instance.downloads.removeObserver(downloadsObserver)
        }
    }
}
