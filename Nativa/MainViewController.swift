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
        item.collapsed = !item.collapsed
//        item.animator().collapsed = !item.collapsed
    }

}
