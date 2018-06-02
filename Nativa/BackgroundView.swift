//
//  BackgroundView.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 9/3/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

@IBDesignable
class BackgroundView: NSView {
    @IBInspectable
    var backgroundColor: NSColor? {
        didSet {
            self.needsDisplay = true
        }
    }
    override var isOpaque: Bool {
        get {
            return backgroundColor != nil
        }
    }
    
    override func draw(_ dirtyRect: NSRect){
        if let backgroundColor = backgroundColor {
            backgroundColor.setFill()
            dirtyRect.fill()
        }
        super.draw(dirtyRect)
    }
}
