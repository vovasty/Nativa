//
//  FolderCell.swift
//  Nativa
//
//  Created by Vladimir Solomenchuk on 10/22/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class FolderNameCell: NSTableCellView
{
    func setName(name: String, size: Double)
    {
        let ssize = Formatter.stringForSize(size)
        let title = NSMutableAttributedString(string: "\(name) \(ssize)")
        let sizeRange = NSRange(location: name.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)+" ".lengthOfBytesUsingEncoding(NSUTF8StringEncoding), length: ssize.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        title.addAttribute(NSFontAttributeName, value: NSFont.systemFontOfSize(NSFont.smallSystemFontSize()), range: sizeRange)
        title.addAttribute(NSForegroundColorAttributeName, value: NSColor.darkGrayColor(), range: sizeRange)

        
        self.textField?.attributedStringValue = title
    }
}
