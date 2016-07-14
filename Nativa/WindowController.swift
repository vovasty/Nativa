//
//  WindowController.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 6/18/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        windowFrameAutosaveName = "autosaveMainWindow"
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        guard let window = window else { return }
        window.isExcludedFromWindowsMenu = true
        window.isMovableByWindowBackground = true
    }
    
}
