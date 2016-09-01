//
//  ProgressView.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 9/1/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Cocoa

@IBDesignable
class ProgressView: NSView {
    @IBInspectable
    var progressHeight: CGFloat = 8 {
        didSet {
            needsDisplay = true
        }
    }
    
    
    @IBInspectable
    var borderWidth: CGFloat = 2 {
        didSet {
            needsDisplay = true
        }
    }
    
    @IBInspectable
    var progressColor: NSColor = NSColor(deviceRed:0.0, green:0.55, blue:0.96, alpha:0.8) {
        didSet {
            needsDisplay = true
        }
    }
    
    @IBInspectable
    var backgroundColor: NSColor = NSColor(deviceRed: 0.93, green: 0.93, blue: 0.93, alpha: 1.0) {
        didSet {
            needsDisplay = true
        }
    }
    
    @IBInspectable
    var borderColor: NSColor = NSColor(deviceRed: 0.91, green:0.91, blue: 0.91, alpha: 1.0) {
        didSet {
            needsDisplay = true
        }
    }
    
    @IBInspectable
    var progress: Double = 0 {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let halfHeight = floor(progressHeight / 2)
        let halfBorderWidth = floor(borderWidth / 2)
        let yOffset = floor((bounds.height - progressHeight) / 2)
        
        let borderPath = NSBezierPath()
        
        //outer border
        borderPath.move(to: NSPoint(x: halfHeight, y: borderWidth + yOffset))
        borderPath.appendArc(withCenter: NSPoint(x: bounds.width - halfHeight, y: halfHeight + yOffset), radius: halfHeight - borderWidth, startAngle: -90, endAngle: 90)
        borderPath.appendArc(withCenter: NSPoint(x: halfHeight, y: halfHeight + yOffset), radius: halfHeight - borderWidth, startAngle: 90, endAngle: -90)
        
        borderPath.lineWidth = 2*borderWidth
        borderColor.set()
        backgroundColor.setFill()
        borderPath.stroke()
        borderPath.fill()
        
        //draw progress only if it is non zero
        if progress > 0 {
            let progressPath = NSBezierPath()
            progressPath.move(to: NSPoint(x: halfHeight, y: halfBorderWidth + yOffset))
            
            
            if progress < 1 {
                progressPath.appendArc(withCenter: NSPoint(x: halfHeight, y: halfHeight + yOffset), radius: halfHeight - halfBorderWidth, startAngle: 90, endAngle: -90)
                
                let progressWidth = max(bounds.width * CGFloat(progress) - halfBorderWidth, halfHeight - halfBorderWidth)
                progressPath.line(to: NSPoint(x: progressWidth, y: halfBorderWidth + yOffset))
                progressPath.line(to: NSPoint(x: progressWidth, y: progressHeight - halfBorderWidth + yOffset))
                progressPath.line(to: NSPoint(x: halfHeight - halfBorderWidth, y: progressHeight - halfBorderWidth + yOffset))
            }
            else { //special case when progress equal to 1
                progressPath.appendArc(withCenter: NSPoint(x: bounds.width - halfHeight, y: halfHeight + yOffset), radius: halfHeight - halfBorderWidth, startAngle: -90, endAngle: 90)
                progressPath.appendArc(withCenter: NSPoint(x: halfHeight, y: halfHeight + yOffset), radius: halfHeight - halfBorderWidth, startAngle: 90, endAngle: -90)
            }
            
            progressColor.setFill()
            progressPath.fill()
        }
    }
}
