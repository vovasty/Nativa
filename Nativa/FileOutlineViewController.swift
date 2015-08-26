//
//  FileOutlineViewController.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 10/8/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

protocol FileOutlineViewControllerDelegate: class {
    func fileOutlineViewController(controller: FileOutlineViewController, didChangeFilePriorities priorities: [FileListNode: Int])
}

class FileOutlineViewController: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @IBOutlet weak var outlineView: NSOutlineView!
    weak var delegate: FileOutlineViewControllerDelegate?
    var filePriorities: [FileListNode: (priority: DownloadPriority, state: Int)] = [:]
    var torrent: Download? {
        didSet {
            
            if let files = torrent?.flatFileList {
                filePriorities = files.reduce([FileListNode: (priority: DownloadPriority, state: Int)](), combine: { (var dict, file) -> [FileListNode: (priority: DownloadPriority, state: Int)] in
                    
                    dict[file] = (priority: file.priority, state: file.priority == .Skip ? NSOffState : NSOnState)
                    return dict
                })
            }
            else if let file = torrent?.file{
                filePriorities[file] = (priority: file.priority, state: file.priority == .Skip ? NSOffState : NSOnState)
            }
            
            
            self.outlineView.reloadData()
        }
    }
    
    override init(){
        super.init()
    }
    
    init (outlineView: NSOutlineView, torrent: Download) {
        self.outlineView = outlineView
        self.torrent = torrent
        
        super.init()
        
        outlineView.setDelegate(self)
        outlineView.setDataSource(self)
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int
    {
        if let file = item as? FileListNode {
            if let children = file.children {
                return children.count
            }
            else {
                return torrent == nil ? 0 : 1
            }
        }
        else
        {
            if let children = torrent?.file?.children {
                return children.count
            }
            else {
                return torrent == nil ? 0 : 1
            }
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool
    {
        if let file = item as? FileListNode {
            if let children = file.children {
                return children.count > 0
            }
        }
        
        return false
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject
    {
        if let file = item as? FileListNode {
            if let children = file.children {
                return children[index]
            }
        }
        else {
            if let children = torrent?.file?.children {
                return children[index]
            }
            else {
                return torrent!.file!
            }
        }
        
        
        return NSNotFound
    }
    
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject?
    {
        if let file = item as? FileListNode {
            return file
        }
        
        return nil
    }
    
    // Delegate methods
    
    func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat {
        if let file = item as? FileListNode {
            if file.folder {
                return 17
            }
            else {
                return 34
            }
        }
        
        return 0;
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView?
    {
        var result: NSView?
        
        if let file = item as? FileListNode, let ci = tableColumn?.identifier {
            
            switch ci {
            case "FileNameColumn":
                if file.folder {
                    if let cell = outlineView.makeViewWithIdentifier("FolderNameCell", owner:self) as? NSTableCellView {
                        cell.imageView?.image = file.icon
                        cell.textField?.stringValue = file.name
                        
                        if let c = cell as? FolderNameCell {
                            c.setName(file.name, size: file.size)
                        }
                        
                        result = cell
                    }
                }
                else {
                    if let cell = outlineView.makeViewWithIdentifier("FileNameCell", owner:self) as? NSTableCellView {
                        if let c = cell as? FileNameCell {
                           c.statusText.stringValue = Formatter.stringForSize(file.size)
                        }
                        
                        cell.imageView?.image = file.icon
                        cell.textField?.stringValue = file.name
                        
                        result = cell
                    }
                }
            case "FileCheckColumn":
                if let cell = outlineView.makeViewWithIdentifier("FileCheckCell", owner:self) as? NSTableCellView {
                    if let button: NSButton = cell.findSubview() {
                        button.action = "fileChecked:"
                        button.target = self
                        button.allowsMixedState = file.folder
                        button.state = stateForFile(file)
                    }
                    result = cell
                }
                
            default:
                result = nil
            }
        }
        
        return result
    }
    
    @IBAction func fileChecked(sender: AnyObject?)
    {
        if let button = sender as? NSButton {
            let rowNumber = self.outlineView.rowForView(button)
            if let file = self.outlineView.itemAtRow(rowNumber) as? FileListNode {
                
                if button.state == NSMixedState {
                    button.state = NSOnState
                }
                
                setPriorityForFile(file, state: button.state)
                outlineView.reloadData()

                let filteredFiles = filePriorities.filter({ (file, priority) -> Bool in
                    return !file.folder && file.priority != priority.priority
                })
                .map({ (file, priority) -> (FileListNode, Int) in
                    return (file, priority.priority.rawValue)
                })
                
                delegate?.fileOutlineViewController(self, didChangeFilePriorities: filteredFiles)
            }
        }
    }
    
    func setPriorityForFile(file: FileListNode, state: Int) {
        let priority: DownloadPriority
        if state == NSOnState || state == NSMixedState {
            priority = .Normal
        }
        else {
            priority = .Skip
        }

        if file.folder{
            if let children = file.children {
                for child in children {
                    setPriorityForFile(child, state: state)
                }
            }
        }
        else {
            filePriorities[file] = (priority: priority, state: state)
        }
    }
    
    func stateForFile(file: FileListNode) -> Int {
        guard file.folder else {
            return filePriorities[file]!.state
        }
        
        guard let children = file.children else {
            return NSOffState
        }
        
        var skipped = 0
        var checked = 0
        for f in children {
            let state: Int
            if f.folder {
                state = stateForFile(f)
            }
            else {
                state = filePriorities[f]!.state
            }
            if state == NSOnState {
                checked++
            }
            else {
                skipped++
            }
        }
        
        let total = children.count
        
        if skipped == total {
            return NSOffState
        }
        if checked == total {
            return NSOnState
        }
        return NSMixedState
    }
}
