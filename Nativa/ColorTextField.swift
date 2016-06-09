//
//  ColorTextField.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 6/8/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class ColorTextField: NSTextField {
    override var enabled: Bool {
        didSet {
            textColor = enabled ? NSColor.controlTextColor() : NSColor.disabledControlTextColor()
        }
    }
}
