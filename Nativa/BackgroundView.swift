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
    override var opaque: Bool {
        get {
            return backgroundColor != nil
        }
    }
    
    override func drawRect(dirtyRect: NSRect){
        if let backgroundColor = backgroundColor {
            backgroundColor.setFill()
            NSRectFill(dirtyRect)
        }
        super.drawRect(dirtyRect)
    }
}
