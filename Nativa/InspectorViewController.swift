//
//  TorrentInfoViewController.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/23/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

protocol InspectorViewControllerPanel: class {
    var download: Download? {set get}
}

class InspectorViewController: NSTabViewController {
    var observerId: NSObjectProtocol?
    @IBOutlet var headerView: NSView!
    @IBOutlet weak var downloadName: NSTextField!
    @IBOutlet weak var downloadStatus: NSTextField!
    @IBOutlet weak var downloadIcon: NSImageView!
    var stateView = StateView(frame: CGRectZero)
    
    var downloads: [Download]? {
        didSet {
            if let download = downloads?.first {
                self.title = download.title
                self.downloadName.stringValue = download.title
                self.downloadIcon.image = download.icon
                
                if let flatFileList = download.flatFileList {
                    self.downloadStatus.stringValue = "\(flatFileList.count) files, \(Formatter.stringForSize(download.size))"
                }
                else {
                    self.downloadStatus.stringValue = Formatter.stringForSize(download.size)
                }
                
                self.loading = true
                Datasource.instance.update(download) { (download, error) -> Void in
                    guard let download = download where error == nil else {
                        logger.error("unable to update torrent info: \(error)")
                        return
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.updateTabs(download)
                        self.downloadStatus.stringValue = "\(download.flatFileList!.count) files, \(Formatter.stringForSize(download.size))"
                        self.loading = false
                    })
                }
            }
        }
    }
    
    private var loading: Bool {
        get {
            return !stateView.hidden
        }
        
        set {
            for v in view.subviews {
                v.hidden = v != headerView && (newValue && v != stateView)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stateView.state = .Progress(message: "loading...")
        stateView.hidden = true

        headerView.translatesAutoresizingMaskIntoConstraints = false
        let tabView = view.subviews[0]
        let segmentedControl = view.subviews[1]
        
        view.addSubview(headerView, positioned: NSWindowOrderingMode.Above, relativeTo: nil)
        view.addSubview(stateView, positioned: NSWindowOrderingMode.Above, relativeTo: nil)
        
        headerView.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(view.bounds.size.width)
            make.top.equalTo(3)
        }
        
        segmentedControl.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(headerView.snp_bottom).offset(3)
        }

        stateView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(segmentedControl.snp_bottom)
            make.left.right.bottom.equalTo(0)
        }

        tabView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(segmentedControl.snp_bottom).offset(3)
        }
        
        observerId = NSNotificationCenter.defaultCenter().addObserverForName(SelectedDownloadsNotification, object: nil, queue: nil) { (note) -> Void in
            self.downloads = (note.userInfo?["downloads"] as? [Download])
        }

    }
    
    private func updateTabs(download: Download) {
        for ti in tabViewItems {
            if let vc = ti.viewController as? InspectorViewControllerPanel {
                vc.download = download
            }
        }
    }
    
    deinit {
        if let observerId = observerId {
            NSNotificationCenter.defaultCenter().removeObserver(observerId)
        }
    }
}

