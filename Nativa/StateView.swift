//
//  ProgressView.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 8/31/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

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
            case .Error(let msg, let buttonTitle, let handler):
                message.hidden = false
                progress.hidden = true
                progress.stopAnimation(nil)
                button.hidden  = false
                buttonHandler = handler
                
                message.stringValue = msg
                button.title = buttonTitle
                button.sizeToFit()
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
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        progress.style = NSProgressIndicatorStyle.SpinningStyle
        progress.controlSize = .RegularControlSize
        progress.sizeToFit()
        
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        progress.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true

        message.editable = false
        message.bezeled = false
        message.drawsBackground = false
        message.alignment = .Center
        
        message.translatesAutoresizingMaskIntoConstraints = false
        message.leftAnchor.constraintEqualToAnchor(leftAnchor, constant: 20).active = true
        message.rightAnchor.constraintEqualToAnchor(rightAnchor, constant: -20).active = true
        message.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        
        button.target = self
        button.action = #selector(buttonClicked(_:))
        button.bezelStyle = .TexturedSquareBezelStyle
        button.setButtonType(NSButtonType.MomentaryPushInButton)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        button.centerYAnchor.constraintEqualToAnchor(message.centerYAnchor, constant: 20).active = true
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