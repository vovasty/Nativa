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
    var stateView = StateView(frame: CGRect.zero)
    @IBOutlet var noSelectionView: NSView!
    private var updateTimer: Timer?
    
    var downloads: [Download]? {
        didSet {
            updateTimer?.stop()
            updateTimer = nil
            
            if let download = downloads?.first where (downloads?.count ?? 0) == 1 {
                noSelectionView.isHidden = true
                self.title = download.title
                self.downloadName.stringValue = download.title
                self.downloadIcon.image = download.icon
                
                if let flatFileList = download.flatFileList{
                    if flatFileList.count == 1 {
                        self.downloadStatus.stringValue = Formatter.string(fromSize: download.size)
                    }
                    else {
                        self.downloadStatus.stringValue = "\(flatFileList.count) files, \(Formatter.string(fromSize: download.size))"
                    }
                    self.updateTabs(download: download)
                    self.loading = false
                }
                else {
                    self.downloadStatus.stringValue = Formatter.string(fromSize: download.size)
                    self.loading = true
                }
                
                updateTimer = Timer(timeout: Config.refreshTimeout) {
                    Datasource.instance.update(download: download) { (dl, error) -> Void in
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
                        
                        self.updateTabs(download: dl)
                        
                        if flatFileList.count == 1 {
                            self.downloadStatus.stringValue = Formatter.string(fromSize: download.size)
                        }
                        else {
                            self.downloadStatus.stringValue = "\(flatFileList.count) files, \(Formatter.string(fromSize: download.size))"
                        }
                        
                        self.loading = false
                    }
                    }
                
                updateTimer?.start(immediately: true)
            }
            else {
                noSelectionView.isHidden = false
            }
        }
    }
    
    private var loading: Bool {
        get {
            return !stateView.isHidden
        }
        
        set {
            for v in view.subviews {
                switch v {
                case noSelectionView, headerView:
                    break
                case stateView:
                    stateView.isHidden = !newValue
                default:
                    v.isHidden = newValue
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stateView.state = .Progress
        stateView.isHidden = true
        
        let tabView = view.subviews.first!
        let segmentedControl = view.subviews[1]
        
        view.addSubview(headerView, positioned: .above, relativeTo: nil)
        view.addSubview(stateView, positioned: .above, relativeTo: nil)
        view.addSubview(noSelectionView, positioned: .above, relativeTo: nil)
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.constraintsMakeWholeView(top: 3, bottom: nil)
        headerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        
        segmentedControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 3).isActive = true
        
        stateView.constraintsMakeWholeView(top: nil)
        stateView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        tabView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor).isActive = true
        
        noSelectionView.translatesAutoresizingMaskIntoConstraints = false
        noSelectionView.constraintsMakeWholeView()
        
        notificationCenter.add(owner: self) { [weak self] (note: SelectedDownloadsNotification) -> Void in
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

