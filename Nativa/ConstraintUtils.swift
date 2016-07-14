

//
//  ConstraintUtils.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 6/17/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Cocoa

extension NSView {
    
    @discardableResult
    func constraintsMakeWholeView(top: CGFloat? = 0, bottom: CGFloat? = 0, leading: CGFloat? = 0, trailing: CGFloat? = 0) -> (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?, leading: NSLayoutConstraint?, trailing: NSLayoutConstraint?)! {
        guard let superview = self.superview else { return nil }
        
        var t: NSLayoutConstraint?
        var b: NSLayoutConstraint?
        var l: NSLayoutConstraint?
        var tr: NSLayoutConstraint?
        
        if let top = top {
            t = topAnchor.constraint(equalTo: superview.topAnchor, constant: top)
            t?.isActive = true
        }

        if let bottom = bottom {
            b = bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: bottom)
            b?.isActive = true
        }
        
        if let leading = leading {
            l = leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: leading)
            l?.isActive = true
        }
        
        if let trailing = trailing {
            tr = trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: trailing)
            tr?.isActive = true
        }
        
        return (top: t, bottom: b, leading: l, trailing: tr)
    }
}
