//
//  ConstraintUtils.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 6/17/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Cocoa

extension NSView {
    func constraintsMakeWholeView(top: CGFloat? = 0, bottom: CGFloat? = 0, leading: CGFloat? = 0, trailing: CGFloat? = 0) -> (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?, leading: NSLayoutConstraint?, trailing: NSLayoutConstraint?)! {
        guard let superview = self.superview else { return nil }
        
        var t: NSLayoutConstraint?
        var b: NSLayoutConstraint?
        var l: NSLayoutConstraint?
        var tr: NSLayoutConstraint?
        
        if let top = top {
            t = topAnchor.constraintEqualToAnchor(superview.topAnchor, constant: top)
            t?.active = true
        }

        if let bottom = bottom {
            b = bottomAnchor.constraintEqualToAnchor(superview.bottomAnchor, constant: bottom)
            b?.active = true
        }
        
        if let leading = leading {
            l = leadingAnchor.constraintEqualToAnchor(superview.leadingAnchor, constant: leading)
            l?.active = true
        }
        
        if let trailing = trailing {
            tr = trailingAnchor.constraintEqualToAnchor(superview.trailingAnchor, constant: trailing)
            tr?.active = true
        }
        
        return (top: t, bottom: b, leading: l, trailing: tr)
    }
}