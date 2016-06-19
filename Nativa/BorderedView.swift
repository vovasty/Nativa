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
    func CGPath(forceClose forceClose:Bool) -> CGPathRef? {
        var cgPath:CGPathRef? = nil
        
        let numElements = self.elementCount
        if numElements > 0 {
            let newPath = CGPathCreateMutable()
            let points = NSPointArray.alloc(3)
            var bDidClosePath:Bool = true
            
            for i in 0 ..< numElements {
                
                switch elementAtIndex(i, associatedPoints:points) {
                    
                case NSBezierPathElement.MoveToBezierPathElement:
                    CGPathMoveToPoint(newPath, nil, points[0].x, points[0].y )
                    
                case NSBezierPathElement.LineToBezierPathElement:
                    CGPathAddLineToPoint(newPath, nil, points[0].x, points[0].y )
                    bDidClosePath = false
                    
                case NSBezierPathElement.CurveToBezierPathElement:
                    CGPathAddCurveToPoint(newPath, nil, points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y )
                    bDidClosePath = false
                    
                case NSBezierPathElement.ClosePathBezierPathElement:
                    CGPathCloseSubpath(newPath)
                    bDidClosePath = true
                }
                
                if forceClose && !bDidClosePath {
                    CGPathCloseSubpath(newPath)
                }
            }
            cgPath = CGPathCreateCopy(newPath)
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
    var backgroundColor: NSColor = NSColor.clearColor() {
        didSet {
            backgroundColorLayer.backgroundColor = backgroundColor.CGColor
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
            let endPoint = CGPoint(x: halfBorderWidth, y: CGRectGetMaxY(self.bounds))
            path.moveToPoint(startPoint)
            path.lineToPoint(endPoint)
        }
        
        if right { // right border
            let startPoint = CGPoint(x: CGRectGetMaxX(self.bounds) - halfBorderWidth, y: 0)
            let endPoint = CGPoint(x: CGRectGetMaxX(self.bounds) - halfBorderWidth, y: CGRectGetMaxY(self.bounds))
            path.moveToPoint(startPoint)
            path.lineToPoint(endPoint)
        }
        
        if bottom { // bottom border
            let startPoint = CGPointMake(0, 0 + halfBorderWidth)
            let endPoint = CGPointMake(CGRectGetMaxX(self.bounds), 0 + halfBorderWidth)
            path.moveToPoint(startPoint)
            path.lineToPoint(endPoint)
        }
        
        if top { // top border
            let startPoint = CGPoint(x: 0, y: CGRectGetMaxY(self.bounds) - halfBorderWidth)
            let endPoint = CGPoint(x: CGRectGetMaxX(self.bounds), y: CGRectGetMaxY(self.bounds) - halfBorderWidth)
            path.moveToPoint(startPoint)
            path.lineToPoint(endPoint)
        }
        
        path.closePath()
        
        borderLayer.frame = bounds
        backgroundColorLayer.frame = bounds
        borderLayer.path = path.CGPath(forceClose: false)
        
        borderLayer.strokeColor = borderColor.CGColor
        borderLayer.lineWidth = borderWidth
    }
}
