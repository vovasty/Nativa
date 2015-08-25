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
    var download: Download? {
        didSet {
            Datasource.instance.update(download!) { (download, error) -> Void in
                guard let download = download where error == nil else {
                    print("unable to update torrent info: \(error)")
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.title = download.title
                    self.updateTabs()
                })
            }
        }
    }
    
    private func updateTabs() {
        for ti in tabViewItems {
            if let vc = ti.viewController as? InspectorViewControllerPanel {
                vc.download = download
            }
        }
    }
    
    override func tabView(tabView: NSTabView, willSelectTabViewItem tabViewItem: NSTabViewItem?) {
            print(tabViewItem?.viewController)
    }
 
    override func viewWillAppear() {
//        updateTabs()
    }
}

