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
    let progress = NSProgressIndicator(frame: NSRect(x: 0, y:0, width: 40, height: 40))
    let message = NSTextField(frame: NSRect.zero)
    let button = NSButton(frame: NSRect.zero)
    var buttonHandler: ((AnyObject?)->Void)?
    
    override var isHidden: Bool {
        didSet {
            switch state {
            case .Progress(_):
                if isHidden {
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
                message.isHidden = true
                button.isHidden  = true
                progress.isHidden = false
                progress.startAnimation(nil)
            case .Error(let msg, let buttonTitle, let handler):
                message.isHidden = false
                progress.isHidden = true
                progress.stopAnimation(nil)
                button.isHidden  = false
                buttonHandler = handler
                
                message.stringValue = msg
                button.title = buttonTitle
                button.sizeToFit()
            case .Unknown:
                break
            }
        }
    }
    
    @objc
    @IBAction
    private func buttonClicked(_ sender: AnyObject?) {
        buttonHandler?(sender)
    }
    
    
    private func setup() {
        self.addSubview(progress)
        self.addSubview(message)
        self.addSubview(button)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        progress.style = .spinningStyle
        progress.controlSize = .regular
        progress.sizeToFit()
        
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progress.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        message.isEditable = false
        message.isBezeled = false
        message.drawsBackground = false
        message.alignment = .center
        
        message.translatesAutoresizingMaskIntoConstraints = false
        message.leftAnchor.constraint(equalTo: leftAnchor, constant: 20).isActive = true
        message.rightAnchor.constraint(equalTo: rightAnchor, constant: -20).isActive = true
        message.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        button.target = self
        button.action = #selector(buttonClicked(_:))
        button.bezelStyle = .texturedSquare
        button.setButtonType(.momentaryPushIn)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: message.centerYAnchor, constant: 20).isActive = true
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
