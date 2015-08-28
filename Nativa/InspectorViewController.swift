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
    
    var downloads: [Download]? {
        didSet {
            if let download = downloads?.first {
                self.title = download.title
                self.downloadName.stringValue = download.title
                self.downloadIcon.image = download.icon
                self.downloadStatus.stringValue = Formatter.stringForSize(download.size)
                
                Datasource.instance.update(download) { (download, error) -> Void in
                    guard let download = download where error == nil else {
                        logger.error("unable to update torrent info: \(error)")
                        return
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.updateTabs(download)
                        self.downloadStatus.stringValue = "\(download.flatFileList!.count) files, \(Formatter.stringForSize(download.size))"
                    })
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let observerId = observerId {
            NSNotificationCenter.defaultCenter().removeObserver(observerId)
        }
        
        observerId = NSNotificationCenter.defaultCenter().addObserverForName(SelectedDownloadsNotification, object: nil, queue: nil) { (note) -> Void in
            self.downloads = (note.userInfo?["downloads"] as? [Download])
        }
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        let tabView = view.subviews[0]
        let segmentedControl = view.subviews[1]
        
        view.addSubview(headerView, positioned: NSWindowOrderingMode.Above, relativeTo: tabView)
        
        let hConstraints =  NSLayoutConstraint.constraintsWithVisualFormat("H:|[headerView(width)]|", options: NSLayoutFormatOptions.AlignAllBaseline, metrics: ["width": CGRectGetWidth(view.bounds)], views: ["headerView": headerView])
        view.addConstraints(hConstraints)
        
        let vConstraints =  NSLayoutConstraint.constraintsWithVisualFormat("V:|[headerView][segmentedControl][tabView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["segmentedControl": segmentedControl, "headerView": headerView, "tabView": tabView])
        view.addConstraints(vConstraints)
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

