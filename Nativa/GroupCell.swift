//
//  GroupCell.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/17/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class GroupCell: NSTableCellView
{
    var group: Group! {
        didSet {
            update()
        }
    }
    
    private func update(){
        textField!.stringValue = group.title
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if let textField = self.textField {
            let color: NSColor = NSColor(srgbRed:0.80, green:0.80, blue:0.80, alpha:1)
            
            var rect = self.bounds
            rect.origin = NSPoint(x:NSMinX(textField.frame), y:0)
            rect.size.height = 1.0
            
            color.drawSwatch(in: rect)
        }
        update()
    }
}
