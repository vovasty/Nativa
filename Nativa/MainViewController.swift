//
//  MainViewController.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/26/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class MainViewController: NSSplitViewController {
    let stateView = StateView(frame: CGRectZero)
    private var connectionObserver: NSObjectProtocol?
    

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
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        let superView = view
        
        superView.addSubview(stateView, positioned: .Above, relativeTo: nil)
        
        stateView.snp_makeConstraints { (make) -> Void in
            make.left.right.top.bottom.equalTo(0)
        }
        
        stateView.hidden = true
        
        connectionObserver = NSNotificationCenter.defaultCenter().addObserverForName(DatasourceConnectionStateDidChange, object: nil, queue: nil) { (note) -> Void in
            
            switch Datasource.instance.connectionState {
            case .Establishing:
                self.stateView.hidden = false
                self.splitView.hidden = true
                self.stateView.state = StateViewContent.Progress(message: "Connecting")
            case .Disconnected(let error):
                self.stateView.hidden = false
                self.splitView.hidden = true
                let msg = error?.localizedDescription ?? "Unknwown Error"
                self.stateView.state = StateViewContent.Error(message: msg, buttonTitle: "try again", handler: { (sender) -> Void in
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.reconnect()
                    }
                })
            case .Established:
                self.stateView.hidden = true
                self.splitView.hidden = false
            }
        }
    }
}
