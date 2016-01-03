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

    @IBAction func showInspector(sender: AnyObject) {
        let item = splitViewItems.last!
        
        if let downloadsViewController = splitViewItems.first?.viewController as? DownloadsViewController,
            let inspectorViewController = splitViewItems.last?.viewController as? InspectorViewController where item.collapsed {
                inspectorViewController.downloads = downloadsViewController.selectedDownloads
        }
        
        //animated
        //item.animator().collapsed = !item.collapsed
        item.collapsed = !item.collapsed

    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.titleVisibility = .Hidden
        
        stateView.addToView(view, hidden: true)
        
        showConnectionState(Datasource.instance.connectionState)
        
        notificationCenter.add(self) {(state: DatasourceConnectionStateDidChange) -> Void in
            self.showConnectionState(state.state)
        }
        
        if ((NSUserDefaults.standardUserDefaults()[kAccountsKey] as? [[String: AnyObject]])?.count ?? 0) == 0 {
            let controller = storyboard?.instantiateControllerWithIdentifier("Preferences")
            presentViewControllerAsModalWindow(controller as! NSViewController)
        }
    }
    
    private func showConnectionState (state: DatasourceConnectionStatus) {
        switch state {
        case .Establishing:
            self.stateView.hidden = false
            self.splitView.hidden = true
            self.stateView.state = StateViewContent.Progress
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
