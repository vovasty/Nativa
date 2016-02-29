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
    func setName(name: String, size: Double, complete: Float)
    {
        let ssize = String(format: "%.2f%%", complete*100) + " of " + Formatter.stringForSize(size)
        let title = NSMutableAttributedString(string: "\(name) \(ssize)")
        //count in characters, not in .lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        let sizeRange = NSRange(location: (name + " ").characters.count, length: ssize.characters.count)
        
        title.addAttribute(NSFontAttributeName, value: NSFont.systemFontOfSize(NSFont.smallSystemFontSize()), range: sizeRange)
        title.addAttribute(NSForegroundColorAttributeName, value: NSColor.darkGrayColor(), range: sizeRange)

        
        self.textField?.attributedStringValue = title
    }
}
