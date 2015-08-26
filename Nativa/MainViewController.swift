//
//  MainViewController.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/26/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class MainViewController: NSSplitViewController {
    
    @IBAction func showInspector(sender: AnyObject) {
        let item = splitViewItems.last!
        //animated
        //item.animator().collapsed = !item.collapsed
        item.collapsed = !item.collapsed
        
        if let downloadsViewController = splitViewItems.first?.viewController as? DownloadsViewController,
        let inspectorViewController = splitViewItems.last?.viewController as? InspectorViewController where !item.collapsed {
            inspectorViewController.downloads = downloadsViewController.selectedDownloads
        }
        
        
        
    }

}
