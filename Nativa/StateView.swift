//
//  ProgressView.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/31/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa
import SnapKit

private class VerticallyAlignedTextFieldCell: NSTextFieldCell {
    override func titleRectForBounds(frame: NSRect) -> NSRect {
        let stringHeight = self.attributedStringValue.size().height
        var titleRect = super.titleRectForBounds(frame)
        titleRect.origin.y = frame.origin.y + (frame.size.height - stringHeight) / 2.0
        return titleRect
    }
    
    override func drawInteriorWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        super.drawInteriorWithFrame(self.titleRectForBounds(cellFrame), inView: controlView)
    }
}


enum StateViewContent {
    case Progress(message: String)
    case Error(message: String, buttonTitle: String, handler: (AnyObject?)->Void)
    case Unknown
}

@IBDesignable
class StateView: NSView {
    let progress = NSProgressIndicator(frame: CGRectMake(0, 0, 40, 40))
    let message = NSTextField(frame: CGRectZero)
    let button = NSButton(frame: CGRectZero)
    var buttonHandler: ((AnyObject?)->Void)?
    
    @IBInspectable
    var state: StateViewContent = StateViewContent.Unknown {
        didSet {
            switch state {
            case .Progress(let msg):
                button.hidden  = true
                progress.hidden = false
                progress.startAnimation(nil)
                
                message.stringValue = msg
                
                message.snp_remakeConstraints { (make) -> Void in
                    let attributes = message.attributedStringValue.attributesAtIndex(0, effectiveRange: nil)
                    var size = message.stringValue.sizeWithAttributes(attributes)
                    size.width = size.width + 8
                    
                    make.size.equalTo(size)
                    make.centerY.equalTo(self)
                    make.centerX.equalTo(self).offset(progress.bounds.size.width/2)
                }
                
                progress.snp_remakeConstraints { (make) -> Void in
                    let size = progress.bounds.size
                    make.size.equalTo(size)
                    make.centerY.equalTo(self)
                    make.right.equalTo(message.snp_left).offset(-3)
                }
            case .Error(let msg, let buttonTitle, let handler):
                progress.hidden = true
                progress.stopAnimation(nil)
                button.hidden  = false
                buttonHandler = handler
                
                message.stringValue = msg
                button.title = buttonTitle
                button.sizeToFit()
                button.target = self
                button.action = "buttonClicked:"
                
                message.snp_remakeConstraints { (make) -> Void in
                    let attributes = message.attributedStringValue.attributesAtIndex(0, effectiveRange: nil)
                    var size = message.stringValue.sizeWithAttributes(attributes)
                    size.width = size.width + 8
                    
                    make.size.equalTo(size)
                    make.centerX.equalTo(self)
                    make.centerY.equalTo(self).offset(-size.height/2)
                }
                
                button.snp_remakeConstraints { (make) -> Void in
                    let size = button.bounds.size
                    make.size.equalTo(size)
                    make.centerX.equalTo(self)
                    make.centerY.equalTo(self).offset(size.height/2 + 3)
                }
                
                break
            case .Unknown:
                break
            }
        }
    }
    
    @IBAction func buttonClicked(sender: AnyObject?) {
        buttonHandler?(sender)
    }
    
    
    private func setup() {
        self.addSubview(progress)
        self.addSubview(message)
        self.addSubview(button)
        
        progress.style = NSProgressIndicatorStyle.SpinningStyle
        progress.controlSize = .SmallControlSize
        progress.sizeToFit()
        
        message.editable = false
        message.selectable = false
        message.cell = VerticallyAlignedTextFieldCell()
        
        button.bezelStyle = .TexturedSquareBezelStyle
        button.setButtonType(NSButtonType.MomentaryPushInButton)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
}