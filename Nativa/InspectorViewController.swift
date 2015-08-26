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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let observerId = observerId {
            NSNotificationCenter.defaultCenter().removeObserver(observerId)
        }
        
        observerId = NSNotificationCenter.defaultCenter().addObserverForName(SelectedDownloadsNotification, object: nil, queue: nil) { (note) -> Void in
            if let download = (note.userInfo?["downloads"] as? [Download])?.first {
                Datasource.instance.update(download) { (download, error) -> Void in
                    guard let download = download where error == nil else {
                        print("unable to update torrent info: \(error)")
                        return
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.title = download.title
                        self.updateTabs(download)
                    })
                }
            }
        }
    }
    
    
    private func updateTabs(download: Download) {
        for ti in tabViewItems {
            if let vc = ti.viewController as? InspectorViewControllerPanel {
                vc.download = download
            }
        }
    }
    
    override func tabView(tabView: NSTabView, willSelectTabViewItem tabViewItem: NSTabViewItem?) {
            print(tabViewItem?.viewController)
    }
 
    deinit {
        if let observerId = observerId {
            NSNotificationCenter.defaultCenter().removeObserver(observerId)
        }
    }
}

