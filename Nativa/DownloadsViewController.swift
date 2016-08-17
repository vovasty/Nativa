//
//  downloadsViewController.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

struct SelectedDownloadsNotification: NotificationProtocol {
    let downloads: [Download]
}

private enum FilterValue: Int {
    case All = 1001, Downloading = 1002, Seeding = 1003, Paused = 1004
}

class DownloadsViewController: NSViewController
{
    @IBOutlet weak var filterBar: ScopeBar!
    @IBOutlet weak var outlineView: NSOutlineView!
    var torrents: IndexingIterator<Array<(path: URL, download: Download)>>?
    private var datasourceObserver: String?
    private var downloadsObserver: String?
    private var downloads: SyncableArray<DownloadsViewController>!
    @IBOutlet weak var downloadSpeed: NSButton!
    @IBOutlet weak var uploadSpeed: NSButton!
    
    
    var selectedDownloads: [Download] {
        
        
        return self.outlineView.selectedRowIndexes
            .map{ (e) -> Download? in
                return outlineView.item(atRow: e) as? Download
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
        
        downloads.update(Datasource.instance.downloads.orderedArray, strategy: .replace)
        updateStatistics()
        
        //FIXME: statistics won't be updated when no downloads
        downloadsObserver = downloads.addObserver{ (downloadChanges: [(object: Download, index: Int, type: ChangeType)]) -> Void in
            self.updateStatistics()
//FIXME: progressindicaton plays not well with animation
//            self.outlineView.beginUpdates()
//            for downloadChange in downloadChanges {
//                let indexes = IndexSet(integer: downloadChange.index)
//                switch downloadChange.type {
//                case .delete:
//                    self.outlineView.removeItems(at: indexes, inParent: nil, withAnimation: .slideUp)
//                case .insert:
//                    self.outlineView.insertItems(at: indexes, inParent: nil, withAnimation: .slideDown)
//                case .update:
//                    //cause reloadItem is not working...
//                    let row = self.outlineView.row(forItem: downloadChange.object)
//                    self.outlineView.setNeedsDisplay(self.outlineView.rect(ofRow: row))
//                }
//            }
//            self.outlineView.endUpdates()
            self.outlineView.reloadData()
        }
        
        datasourceObserver = Datasource.instance.downloads.addObserver{ (downloadChanges: [(object: Download, index: Int, type: ChangeType)]) -> Void in
            dispatch_main {
                for downloadChange in downloadChanges {
                    switch downloadChange.type {
                    case .delete:
                        self.downloads.remove(downloadChange.object)
                    case .insert, .update:
                        self.downloads.update(downloadChange.object)
                    }
                }
            }
        }
        
        notificationCenter.add(owner: self) { [weak self] (note: DownloadFilesAddedNotification) -> Void in
            self?.add(torrents: note.downloads)
        }
        
        updateStatistics()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        downloadSpeed.toolTip = downloadSpeed.toolTip
        uploadSpeed.toolTip = uploadSpeed.toolTip
    }
    
    @objc
    @IBAction
    private func controlAction(_ sender: AnyObject) {
        let row = self.outlineView.row(for: sender as! NSView)
        let download = self.outlineView.item(atRow: row) as! Download

        switch (download.state)
        {
        case .Stopped, .Paused:
            download.state = .Downloading(dl: 0, ul: 0)
            Datasource.instance.startDownload(download: download)
        default:
            Datasource.instance.stopDownload(download: download)
        }
    }
    
    //MARK: NSSeguePerforming
    override func prepare(for segue: NSStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        
        switch identifier{
        case "showAddTorrent":
            if  let torrent = torrents?.next(),
                let vc = segue.destinationController as? AddTorrentViewController {
                    vc.setDownload(download: torrent.download, path: torrent.path)
            }
        default:
            break
        }
    }
    
    private func add(torrents: [(path: URL, download: Download)]) {
        guard torrents.count > 0 else { return }
        
        self.torrents = torrents.makeIterator()
        for _ in 0 ... torrents.count - 1 {
            self.performSegue(withIdentifier: "showAddTorrent", sender: nil)
        }
    }
    
    @objc
    @IBAction
    private func remove(_ sender: AnyObject) {
        for index in outlineView.selectedRowIndexes {
            if let download = outlineView.item(atRow: index) as? Download {
                Datasource.instance.remove(download: download, removeData: false, response: { (error) -> Void in
                    if let error = error {
                        logger.error("unable to remove torrent: \(error)")
                    }
                })
            }
        }
    }
    
    @objc
    @IBAction
    private func removeDownloadWithData(_ sender: AnyObject) {
        
        let selectedDownloads: [Download] = outlineView.selectedRowIndexes.map { outlineView.item(atRow: $0) as! Download }
        
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Delete the selected downloads?"
        alert.informativeText = "This operation can not be undone."
        alert.alertStyle = NSAlertStyle.warning
        alert.beginSheetModal(for: self.view.window!) {
            guard $0 == NSAlertFirstButtonReturn else {
                return
            }
            
            for download in selectedDownloads {
                Datasource.instance.remove(download: download, removeData: true, response: { (error) -> Void in
                    if let error = error {
                        logger.error("unable to remove torrent: \(error)")
                    }
                })
            }
        }
    }
    
    private func apply(filter: FilterValue) {
        switch filter {
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
        
        downloads.update(Datasource.instance.downloads.orderedArray, strategy: .replace)
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
        
        self.downloadSpeed.title = Formatter.string(fromSpeed: stats.downloadSpeed)
        self.downloadSpeed.toolTip = stats.downloadLimited ? "Global download limit: \(Formatter.string(fromSpeed: stats.maxDownloadSpeed)) (Speed Limit)" : "Download is unlimited"
        self.uploadSpeed.title = Formatter.string(fromSpeed: stats.uploadSpeed)
        self.uploadSpeed.toolTip = stats.uploadLimited ? "Global upload limit: \(Formatter.string(fromSpeed: stats.maxUploadSpeed)) (Speed Limit)" : "Upload is unlimited"
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return outlineView.selectedRowIndexes.count > 0
    }
    
    
    override func validateToolbarItem(_ theItem: NSToolbarItem) -> Bool {
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
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int
    {
        if let group = item as? Group {
            return group.downloads.count
        }
        else
        {
            return downloads.count
        }
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool
    {
        return item is Group
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject
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
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: AnyObject) -> NSView?
    {
        if let group = item as? Group {
            let result: GroupCell! = outlineView.make(withIdentifier: "GroupCell", owner:self) as? GroupCell;
            result.group = group
            return result;
        }
        else if let download = item as? Download{
            let result: DownloadCell! = outlineView.make(withIdentifier: "DownloadCell", owner:self) as? DownloadCell;
            result.download = download
            return result;
        }
        
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat
    {
        if item is Group {
            return 20
        }
        else {
            return DownloadCell.height
        }
    }
    
    func outlineViewSelectionDidChange(_ notification: Foundation.Notification) {
        notificationCenter.post(SelectedDownloadsNotification(downloads: self.selectedDownloads))
    }
}

//MARK: SyncableArrayDelegate
extension DownloadsViewController: SyncableArrayDelegate {
    func id(fromRaw raw: Download) -> String? {
        return raw.id
    }
    
    func id(fromObject object: Download) -> String {
        return object.id
    }
    
    func update(fromRaw raw: Download, object: Download) -> Download {
        return object
    }
    
    func create(fromRaw raw: Download) -> Download? {
        return raw
    }
}

//MARK: DropViewDelegate
extension DownloadsViewController: DropViewDelegate {
    func completeDrag(toView view: DownloadDropView, torrents: [(path: URL, download: Download)]) {
        add(torrents: torrents)
    }
}

//MARK: ScopeBarDelegate
extension DownloadsViewController: ScopeBarDelegate {
    func scopeBar(scopeBar: ScopeBar, buttonClicked button: NSButton) {
        let button = filterBar.selectedButton!
        let value = FilterValue(rawValue: button.tag)!
        apply(filter: value)
    }
}
