//
//  BorderedView.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 6/18/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Cocoa

extension NSBezierPath {
    // Adapted from : https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Paths/Paths.html#//apple_ref/doc/uid/TP40003290-CH206-SW2
    // See also: http://www.dreamincode.net/forums/topic/370959-nsbezierpath-to-cgpathref-in-swift/
    func CGPath(forceClose:Bool) -> CGPath? {
        var cgPath:CGPath? = nil
        
        let numElements = self.elementCount
        if numElements > 0 {
            let newPath = CGMutablePath()
            var points = [NSPoint](repeating: NSPoint.zero, count: 3)
            var bDidClosePath:Bool = true
            
            for i in 0 ..< numElements {
                switch element(at: i, associatedPoints: &points) {
                    
                case .moveToBezierPathElement:
                    newPath.move(to: points[0])
                    
                case .lineToBezierPathElement:
                    newPath.addLine(to: points[0])
                    bDidClosePath = false
                    
                case .curveToBezierPathElement:
                    newPath.addCurve(to: points[2], control1: points[0], control2: points[1])
                    bDidClosePath = false
                    
                case NSBezierPath.ElementType.closePathBezierPathElement:
                    newPath.closeSubpath()
                    bDidClosePath = true
                }
                
                if forceClose && !bDidClosePath {
                    newPath.closeSubpath()
                }
            }
            cgPath = newPath.copy()
        }
        return cgPath
    }
}

@IBDesignable
class BorderedView: NSView {
    @IBInspectable
    var borderWidth: CGFloat = 1
    
    @IBInspectable
    var left: Bool = false {
        didSet {
            needsLayout = true
        }
    }
    
    @IBInspectable
    var right: Bool = false {
        didSet {
            needsLayout = true
        }
    }
    
    @IBInspectable
    var top: Bool = false {
        didSet {
            needsLayout = true
        }
    }
    
    @IBInspectable
    var bottom: Bool = false {
        didSet {
            needsLayout = true
        }
    }
    
    @IBInspectable
    var backgroundColor: NSColor = NSColor.clear {
        didSet {
            backgroundColorLayer.backgroundColor = backgroundColor.cgColor
            needsLayout = true
        }
    }
    
    @IBInspectable
    var borderColor: NSColor = NSColor(deviceRed: 0.83, green:  0.83, blue:  0.83, alpha:  1) {
        didSet {
            needsLayout = true
        }
    }
    
    private var borderLayer = CAShapeLayer()
    private var backgroundColorLayer = CALayer()
    
    private func setup() {
        layer = backgroundColorLayer
        layer?.addSublayer(borderLayer)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    override func layout() {
        super.layout()
        
        reloadBorders()
        borderLayer.zPosition = CGFloat(self.layer?.sublayers?.count ?? 0)
    }
    
    private func reloadBorders() {
        let path = NSBezierPath()
        let halfBorderWidth = borderWidth / 2
        
        if left { // left border
            let startPoint = CGPoint(x: halfBorderWidth, y: 0)
            let endPoint = CGPoint(x: halfBorderWidth, y: self.bounds.maxY)
            path.move(to: startPoint)
            path.line(to: endPoint)
        }
        
        if right { // right border
            let startPoint = CGPoint(x: self.bounds.maxX - halfBorderWidth, y: 0)
            let endPoint = CGPoint(x: self.bounds.maxX - halfBorderWidth, y: self.bounds.maxY)
            path.move(to: startPoint)
            path.line(to: endPoint)
        }
        
        if bottom { // bottom border
            let startPoint = CGPoint(x: 0, y:
                0 + halfBorderWidth)
            let endPoint = CGPoint(x: self.bounds.maxX, y: 0 + halfBorderWidth)
            path.move(to: startPoint)
            path.line(to: endPoint)
        }
        
        if top { // top border
            let startPoint = CGPoint(x: 0, y: self.bounds.maxY - halfBorderWidth)
            let endPoint = CGPoint(x: self.bounds.maxX, y: self.bounds.maxY - halfBorderWidth)
            path.move(to: startPoint)
            path.line(to: endPoint)
        }
        
        path.close()
        
        borderLayer.frame = bounds
        backgroundColorLayer.frame = bounds
        borderLayer.path = path.CGPath(forceClose: false)
        
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
    }
}
