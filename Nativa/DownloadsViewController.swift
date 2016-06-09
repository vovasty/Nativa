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

private enum FilterValue: Int {
    case All = 1001, Downloading = 1002, Seeding = 1003, Paused = 1004
}

class DownloadsViewController: NSViewController
{
    @IBOutlet weak var filterBar: ScopeBar!
    @IBOutlet weak var outlineView: NSOutlineView!
    var torrents: IndexingGenerator<Array<(path: NSURL, download: Download)>>?
    private var datasourceObserver: String?
    private var downloadsObserver: String?
    private var downloads: SyncableArray<DownloadsViewController>!
    @IBOutlet weak var downloadSpeed: NSButton!
    @IBOutlet weak var uploadSpeed: NSButton!
    
    
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
        filterBar.scopeBarDelegate = self

        downloads = SyncableArray(delegate: self)
        
        downloads.sorter { (d1, d2) -> Bool in
            return d1.title < d2.title
        }
        
        downloads.update(Datasource.instance.downloads.orderedArray, strategy: .Replace)
        updateStatistics()
        
        downloadsObserver = downloads.addObserver{ (downloadChanges: [(object: Download, index: Int, type: ChangeType)]) -> Void in
            self.updateStatistics()
            
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
                }
            }
            self.outlineView.endUpdates()
        }
        
        datasourceObserver = Datasource.instance.downloads.addObserver{ (downloadChanges: [(object: Download, index: Int, type: ChangeType)]) -> Void in
            dispatch_main {
                for downloadChange in downloadChanges {
                    switch downloadChange.type {
                    case .Delete:
                        self.downloads.remove(downloadChange.object)
                    case .Insert, .Update:
                        self.downloads.update(downloadChange.object)
                    }
                }
            }
        }
        
        notificationCenter.add(self) { [weak self] (note: DownloadFilesAddedNotification) -> Void in
            self?.addTorrents(note.downloads)
        }
        
        updateStatistics()
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
    
    //MARK: NSSeguePerforming
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier{
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
        guard torrents.count > 0 else { return }
        
        self.torrents = torrents.generate()
        for _ in 0 ... torrents.count - 1 {
            self.performSegueWithIdentifier("showAddTorrent", sender: nil)
        }
    }
    
    @IBAction func remove(sender: AnyObject) {
        for index in outlineView.selectedRowIndexes {
            if let download = outlineView.itemAtRow(index) as? Download {
                Datasource.instance.removeTorrent(download, removeData: false, response: { (error) -> Void in
                    if let error = error {
                        logger.error("unable to remove torrent: \(error)")
                    }
                })
            }
        }
    }
    
    @IBAction func removeDownloadWithData(sender: AnyObject) {
        
        let selectedDownloads: [Download] = outlineView.selectedRowIndexes.map { outlineView.itemAtRow($0) as! Download }
        
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.addButtonWithTitle("Cancel")
        alert.messageText = "Delete the selected downloads?"
        alert.informativeText = "This operation can not be undone."
        alert.alertStyle = NSAlertStyle.WarningAlertStyle
        alert.beginSheetModalForWindow(self.view.window!) {
            guard $0 == NSAlertFirstButtonReturn else {
                return
            }
            
            for download in selectedDownloads {
                Datasource.instance.removeTorrent(download, removeData: true, response: { (error) -> Void in
                    if let error = error {
                        logger.error("unable to remove torrent: \(error)")
                    }
                })
            }
        }
    }
    
    private func applyFilter(value: FilterValue) {
        switch value {
        case .All:
            downloads.filterHandler(nil)
        case .Seeding:
            downloads.filterHandler{ (d) -> Bool in
                switch d.state {
                case .Seeding(ul: _):
                    return true
                default:
                    return false
                }
            }
        case .Downloading:
            downloads.filterHandler{ (d) -> Bool in
                switch d.state {
                case .Downloading(dl: _, ul: _):
                    return true
                default:
                    return false
                }
            }
        case .Paused:
            downloads.filterHandler{ (d) -> Bool in
                switch d.state {
                case .Stopped:
                    return true
                default:
                    return false
                }
            }
        }
        
        downloads.update(Datasource.instance.downloads.orderedArray, strategy: SyncStrategy.Replace)
    }
    
    private func updateStatistics() {
        let stats = Datasource.instance.statistics.values
            .reduce(Statistics(id: "")) { (res, stat) -> Statistics in
                res.downloadSpeed += stat.downloadSpeed
                res.maxDownloadSpeed += stat.maxDownloadSpeed
                res.uploadSpeed += stat.uploadSpeed
                res.maxUploadSpeed += stat.maxUploadSpeed
                return res
        }
        
        self.downloadSpeed.title = Formatter.stringForSpeed(stats.downloadSpeed)
        self.downloadSpeed.toolTip = stats.downloadLimited ? "Global download limit: \(Formatter.stringForSpeed(stats.maxDownloadSpeed)) (Speed Limit)" : "Download is unlimited"
        self.uploadSpeed.title = Formatter.stringForSpeed(stats.uploadSpeed)
        self.uploadSpeed.toolTip = stats.uploadLimited ? "Global upload limit: \(Formatter.stringForSpeed(stats.maxUploadSpeed)) (Speed Limit)" : "Upload is unlimited"
    }

    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        return outlineView.selectedRowIndexes.count > 0
    }
    
    
    override func validateToolbarItem(theItem: NSToolbarItem) -> Bool {
        return outlineView.selectedRowIndexes.count > 0
    }
    
    deinit {
        if let datasourceObserver = datasourceObserver {
            Datasource.instance.downloads.removeObserver(datasourceObserver)
        }

        if let downloadsObserver = downloadsObserver {
            downloads.removeObserver(downloadsObserver)
        }
    }
}

//MARK: NSOutlineViewDataSource
extension DownloadsViewController: NSOutlineViewDataSource {
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int
    {
        if let group = item as? Group {
            return group.downloads.count
        }
        else
        {
            return downloads.count
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
            return downloads[index]
        }
    }
}

//MARK: NSOutlineViewDelegate
extension DownloadsViewController: NSOutlineViewDelegate {
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
}

//MARK: SyncableArrayDelegate
extension DownloadsViewController: SyncableArrayDelegate {
    func idFromRaw(object: Download) -> String? {
        return object.id
    }
    
    func idFromObject(object: Download) -> String {
        return object.id
    }
    
    func updateObject(source: Download, object: Download) -> Download {
        return object
    }
    
    func createObject(object: Download) -> Download? {
        return object
    }
}

//MARK: DropViewDelegate
extension DownloadsViewController: DropViewDelegate {
    func completeDragToView(view: DownloadDropView, torrents: [(path: NSURL, download: Download)]) {
        addTorrents(torrents)
    }
}

//MARK: ScopeBarDelegate
extension DownloadsViewController: ScopeBarDelegate {
    func scopeBar(scopeBar: ScopeBar, buttonClicked button: NSButton) {
        let button = filterBar.selectedButton!
        let value = FilterValue(rawValue: button.tag)!
        applyFilter(value)
    }
}