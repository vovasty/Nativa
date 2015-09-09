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
    case Progress
    case Error(message: String, buttonTitle: String, handler: (AnyObject?)->Void)
    case Unknown
}

@IBDesignable
class StateView: NSView {
    let progress = NSProgressIndicator(frame: CGRectMake(0, 0, 40, 40))
    let message = NSTextField(frame: CGRectZero)
    let button = NSButton(frame: CGRectZero)
    var buttonHandler: ((AnyObject?)->Void)?
    
    override var hidden: Bool {
        didSet {
            switch state {
            case .Progress(_):
                if hidden {
                    progress.stopAnimation(nil)
                }
                else {
                    progress.startAnimation(nil)
                }
            case .Error(_, _, _):
                progress.stopAnimation(nil)
            case .Unknown:
                progress.stopAnimation(nil)
                break
            }
        }
    }

    
    @IBInspectable
    var state: StateViewContent = StateViewContent.Unknown {
        didSet {
            switch state {
            case .Progress:
                message.hidden = true
                button.hidden  = true
                progress.hidden = false
                progress.startAnimation(nil)
                
                message.snp_remakeConstraints { (make) -> Void in
                    let attributes = message.attributedStringValue.attributesAtIndex(0, effectiveRange: nil)
                    var size = message.stringValue.sizeWithAttributes(attributes)
                    size.width = size.width + 8
                    
                    make.size.equalTo(size)
                    make.centerY.equalTo(self)
                    make.centerX.equalTo(self).offset(progress.bounds.size.width/2)
                }
                
                progress.snp_remakeConstraints { (make) -> Void in
                    var size = progress.frame.size
                    size.width = max(size.width, size.height)
                    size.height = size.width

                    make.size.equalTo(size)
                    make.center.equalTo(self)
                }
            case .Error(let msg, let buttonTitle, let handler):
                message.hidden = false
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
        progress.controlSize = .RegularControlSize
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
    
    func addToView(view: NSView, hidden: Bool) -> Void {
        view.addSubview(self, positioned: .Above, relativeTo: nil)
        
        self.snp_makeConstraints { (make) -> Void in
            make.left.right.top.bottom.equalTo(0)
        }
        
        self.hidden = hidden
    }
}