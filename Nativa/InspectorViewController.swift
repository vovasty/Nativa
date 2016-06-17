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
    @IBOutlet var headerView: NSView!
    @IBOutlet weak var downloadName: NSTextField!
    @IBOutlet weak var downloadStatus: NSTextField!
    @IBOutlet weak var downloadIcon: NSImageView!
    var stateView = StateView(frame: CGRectZero)
    @IBOutlet var noSelectionView: NSView!
    private var updateTimer: Timer?
    
    var downloads: [Download]? {
        didSet {
            updateTimer?.stop()
            updateTimer = nil
            
            if let download = downloads?.first where (downloads?.count ?? 0) == 1 {
                noSelectionView.hidden = true
                self.title = download.title
                self.downloadName.stringValue = download.title
                self.downloadIcon.image = download.icon
                
                if let flatFileList = download.flatFileList{
                    if flatFileList.count == 1 {
                        self.downloadStatus.stringValue = Formatter.stringForSize(download.size)
                    }
                    else {
                        self.downloadStatus.stringValue = "\(flatFileList.count) files, \(Formatter.stringForSize(download.size))"
                    }
                    self.updateTabs(download)
                    self.loading = false
                }
                else {
                    self.downloadStatus.stringValue = Formatter.stringForSize(download.size)
                    self.loading = true
                }
                
                updateTimer = Timer(timeout: Config.refreshTimeout) {
                    Datasource.instance.update(download) { (dl, error) -> Void in
                        guard let dl = dl, let flatFileList = dl.flatFileList where dl == self.downloads?.first && error == nil else {
                            if let error = error {
                                logger.error("unable to update torrent info: \(error)")
                                
                                self.stateView.state = StateViewContent.Error(message: error.localizedDescription, buttonTitle: "try again", handler: { (sender) -> Void in
                                    self.downloads = self.downloads
                                })
                                self.loading = true
                            }
                            return
                        }
                        
                        self.updateTabs(dl)
                        
                        if flatFileList.count == 1 {
                            self.downloadStatus.stringValue = Formatter.stringForSize(download.size)
                        }
                        else {
                            self.downloadStatus.stringValue = "\(flatFileList.count) files, \(Formatter.stringForSize(download.size))"
                        }
                        
                        self.loading = false
                    }
                    }
                
                updateTimer?.start(true)
            }
            else {
                noSelectionView.hidden = false
            }
        }
    }
    
    private var loading: Bool {
        get {
            return !stateView.hidden
        }
        
        set {
            for v in view.subviews {
                switch v {
                case noSelectionView, headerView:
                    break
                case stateView:
                    stateView.hidden = !newValue
                default:
                    v.hidden = newValue
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stateView.state = .Progress
        stateView.hidden = true
        
        let tabView = view.subviews.first!
        let segmentedControl = view.subviews[1]
        
        view.addSubview(headerView, positioned: .Above, relativeTo: nil)
        view.addSubview(stateView, positioned: .Above, relativeTo: nil)
        view.addSubview(noSelectionView, positioned: .Above, relativeTo: nil)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.constraintsMakeWholeView(3, bottom: nil)
        headerView.heightAnchor.constraintEqualToConstant(50).active = true
        
        
        segmentedControl.topAnchor.constraintEqualToAnchor(headerView.bottomAnchor, constant: 3).active = true
        
        stateView.constraintsMakeWholeView(nil)
        stateView.topAnchor.constraintEqualToAnchor(headerView.bottomAnchor).active = true
        tabView.topAnchor.constraintEqualToAnchor(segmentedControl.bottomAnchor).active = true
        
        noSelectionView.translatesAutoresizingMaskIntoConstraints = false
        noSelectionView.constraintsMakeWholeView()
        
        notificationCenter.add(self) { [weak self] (note: SelectedDownloadsNotification) -> Void in
            self?.downloads = note.downloads
        }
        
    }
    
    private func updateTabs(download: Download) {
        for ti in tabViewItems {
            if let vc = ti.viewController as? InspectorViewControllerPanel {
                vc.download = download
            }
        }
    }
}

