//
//  ColorTextField.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 6/8/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class ColorTextField: NSTextField {
    override var isEnabled: Bool {
        didSet {
            textColor = isEnabled ? NSColor.controlTextColor : NSColor.disabledControlTextColor
        }
    }
}
