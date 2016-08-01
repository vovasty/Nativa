//
//  MainViewController.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/26/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class MainViewController: NSSplitViewController {
    let stateView = StateView(frame: CGRect.zero)
    var prevSize: CGSize?

    @IBAction
    @objc
    private func showInspector(_ sender: AnyObject) {
        let item = splitViewItems.last!
        
        if let downloadsViewController = splitViewItems.first?.viewController as? DownloadsViewController,
            let inspectorViewController = splitViewItems.last?.viewController as? InspectorViewController, item.isCollapsed {
                inspectorViewController.downloads = downloadsViewController.selectedDownloads
        }
        
        if item.isCollapsed {
            prevSize = view.window?.frame.size
        }
        
        //animated
//        item.animator().collapsed = !item.collapsed
        
        item.isCollapsed = !item.isCollapsed
        
        if item.isCollapsed {
            if let prevSize = prevSize {
                if var frame = view.window?.frame {
                    frame.size = prevSize
                    view.window?.setFrame(frame, display: true, animate: false)
                }
            }
        }
        
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.titleVisibility = .hidden
        
        view.addSubview(stateView)
        stateView.constraintsMakeWholeView()
        stateView.isHidden = true
        
        showConnectionState(state: Datasource.instance.connectionState)
        
        notificationCenter.add(owner: self) {(state: DatasourceConnectionStateDidChange) -> Void in
            self.showConnectionState(state: state.state)
        }
        
        if ((UserDefaults.standard[kAccountsKey] as? [[String: AnyObject]])?.count ?? 0) == 0 {
            let controller = storyboard?.instantiateController(withIdentifier: "Preferences")
            presentViewControllerAsModalWindow(controller as! NSViewController)
        }
    }
    
    private func showConnectionState (state: DatasourceConnectionStatus) {
        switch state {
        case .Establishing:
            self.stateView.isHidden = false
            self.splitView.isHidden = true
            self.stateView.state = StateViewContent.Progress
        case .Disconnected(let error):
            self.stateView.isHidden = false
            self.splitView.isHidden = true
            let msg = error?.localizedDescription ?? "Unknwown Error"
            self.stateView.state = StateViewContent.Error(message: msg, buttonTitle: "try again", handler: { (sender) -> Void in
                if let appDelegate = NSApp.delegate as? AppDelegate {
                    appDelegate.reconnect()
                }
            })
        case .Established:
            self.stateView.isHidden = true
            self.splitView.isHidden = false
        }
    }
}
