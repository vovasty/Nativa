//
//  ToolbarItem.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/11/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa


class ButtonToolbarItem: NSToolbarItem
{
    var _menuFormRepresentation: NSMenuItem?
    
    override func validate()
    {
        if let target: AnyObject = self.target {
            self.isEnabled = target.validateToolbarItem(self)
        }
    }
    
    override var menuFormRepresentation: NSMenuItem! {
        get {
            
            if _menuFormRepresentation == nil
            {
                _menuFormRepresentation = NSMenuItem(title: self.label, action: self.action, keyEquivalent: "")
                _menuFormRepresentation?.target = self.target
                
                if let target: AnyObject = self.target {
                    _menuFormRepresentation?.isEnabled = target.validateToolbarItem(self)
                }
            }
            
            return _menuFormRepresentation
        }
        set(menuItem) {
        }
    }
}
