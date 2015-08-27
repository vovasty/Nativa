//
//  TorrentInfoViewController.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/23/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa
import Common

protocol InspectorViewControllerPanel: class {
    var download: Download? {set get}
}

class InspectorViewController: NSTabViewController {
    var observerId: NSObjectProtocol?
    
    var downloads: [Download]? {
        didSet {
            if let download = downloads?.first {
                self.title = download.title
                Datasource.instance.update(download) { (download, error) -> Void in
                    guard let download = download where error == nil else {
                        logger.error("unable to update torrent info: \(error)")
                        return
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.updateTabs(download)
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

