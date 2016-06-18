//
//  InspectorDownloadInfoViewController.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 9/17/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class InspectorDownloadInfoViewController: NSViewController, InspectorViewControllerPanel {
    @IBOutlet weak var processId: NSTextField!
    @IBOutlet weak var downloadId: NSTextField!
    @IBOutlet weak var state: NSTextField!
    @IBOutlet weak var freeSpace: NSTextField!
    
    var download: Download? {
        didSet {
            update()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        update()
    }
    
    private func update() {
        guard let download = download where processId != nil && downloadId != nil && state != nil else { return }
        
        self.processId.stringValue = download.processId ?? "unknown"
        self.downloadId.stringValue = download.id.lowercaseString
        freeSpace.stringValue = Formatter.stringForSize(download.freeDiskspace)
        switch download.state
        {
        case .Downloading(_, _):
            if let peersConnected = download.peersConnected, let peersCompleted = download.peersCompleted,  let peersNotConnected = download.peersNotConnected {
                state.stringValue = String.localizedStringWithFormat("downloading from %i of %i", peersCompleted, peersConnected + peersNotConnected)
            }
        case .Seeding(_):
            if let peersConnected = download.peersConnected, let peersCompleted = download.peersCompleted {
                state.stringValue = String.localizedStringWithFormat("seeding to %i", peersConnected - peersCompleted)
            }
        case .Checking:
            state.stringValue = NSLocalizedString("checking", comment: "download->status")
        case .Stopped:
            state.stringValue = NSLocalizedString("stopped", comment: "download->status")
        case .Paused:
            state.stringValue = NSLocalizedString("paused", comment: "download->status")
        case .Unknown:
            state.stringValue = NSLocalizedString("unknown", comment: "download->status")
        }
    }
}
