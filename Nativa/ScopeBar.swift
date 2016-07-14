//
//  ScopeBar.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 12/10/15.
//  Copyright © 2015 Aramzamzam LLC. All rights reserved.
//

import Cocoa

func trace(s: Any) {
    print(s)
}

protocol ScopeBarDelegate: class {
    func scopeBar(scopeBar: ScopeBar, buttonClicked button: NSButton)
}

@IBDesignable
class ScopeBar: NSStackView {
    weak var scopeBarDelegate: ScopeBarDelegate?
    
    private func setup() {
        orientation = NSUserInterfaceLayoutOrientation.horizontal
        alignment = NSLayoutAttribute.centerY
        edgeInsets = EdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        for v in subviews {
            guard let button  = v as? NSButton  else { continue }
            button.target = self
            button.action = #selector(buttonClicked(_:))
            button.showsBorderOnlyWhileMouseInside = true
            button.cell?.backgroundStyle = .raised
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    @objc
    @IBAction
    private func buttonClicked(_ sender: NSButton){
        for button in subviews {
            guard let button  = button as? NSButton  else { return }
            button.state = NSOffState
        }
        
        sender.state = NSOnState
        
        scopeBarDelegate?.scopeBar(scopeBar: self, buttonClicked: sender)
    }
    
    var selectedButton: NSButton? {
        for button in subviews {
            guard let button  = button as? NSButton  else { continue }
            if button.state == NSOnState {
                return button
            }
        }
        
        return nil
    }
}
