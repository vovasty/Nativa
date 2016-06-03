//
//  FileOutlineViewController.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 10/8/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

class FileOutlineViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @IBOutlet weak var outlineView: NSOutlineView!
    var filePriorities: [FileListNode: (priority: DownloadPriority, state: Int)] = [:]
    var flatPriorities: [FileListNode: Int]?
    private var expandedNodes: Set<FileListNode>?
    
    var download: Download? {
        willSet {
            guard newValue != download else {
                return
            }
            
            self.expandedNodes = Set<FileListNode>()
        }
        
        didSet {
            if let files = download?.flatFileList where files.count > 0 {
                filePriorities = files.reduce([FileListNode: (priority: DownloadPriority, state: Int)](), combine: { (var dict, file) -> [FileListNode: (priority: DownloadPriority, state: Int)] in
                    
                    dict[file] = (priority: file.priority, state: (file.percentCompleted == 1 || file.priority != .Skip) ? NSOnState : NSOffState)
                    return dict
                })
            }
            else if let file = download?.file{
                filePriorities = [file: (priority: file.priority, state: file.priority == .Skip ? NSOffState : NSOnState)]
            }
            
            self.outlineView?.reloadData()
            
            if let expandedNodes = expandedNodes {
                for node in expandedNodes {
                    outlineView.expandItem(node)
                }
            }
        }
    }
    
    func expand(node: FileListNode) {
        outlineView.expandItem(node)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fileNameNib = NSNib(nibNamed: "FileName", bundle: nil)
        self.outlineView.registerNib(fileNameNib!, forIdentifier: "FileNameCell")
        let folderNameNib = NSNib(nibNamed: "FolderName", bundle: nil)
        self.outlineView.registerNib(folderNameNib!, forIdentifier: "FolderNameCell")
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int
    {
        if let file = item as? FileListNode {
            if let children = file.children {
                return children.count
            }
            else {
                return download == nil ? 0 : 1
            }
        }
        else
        {
            if let children = download?.file.children {
                return children.count
            }
            else {
                return download == nil ? 0 : 1
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
            if let children = download?.file.children {
                return children[index]
            }
            else {
                return download!.file
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
    
    func outlineView(outlineView: NSOutlineView, shouldShowOutlineCellForItem item: AnyObject) -> Bool {
        return true
    }
    
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
                            c.setName(file.name, size: file.size, complete: file.percentCompleted)
                        }
                        
                        result = cell
                    }
                }
                else {
                    if let cell = outlineView.makeViewWithIdentifier("FileNameCell", owner:self) as? NSTableCellView {
                        if let c = cell as? FileNameCell {
                           c.statusText.stringValue = String(format: "%.2f%%", file.percentCompleted*100) + " of " + Formatter.stringForSize(file.size)
                        }
                        
                        cell.imageView?.image = file.icon
                        cell.textField?.stringValue = file.name
                        
                        result = cell
                    }
                }
            case "FileCheckColumn":
                if let cell = outlineView.makeViewWithIdentifier("FileCheckCell", owner:self) as? NSTableCellView {
                    if let button: NSButton = cell.findSubview() {
                        button.action = #selector(fileChecked(_:))
                        button.target = self
                        button.allowsMixedState = file.folder
                        button.state = stateForFile(file)
                        button.enabled = file.percentCompleted < 1 && download?.flatFileList?.count > 1
                    }
                    result = cell
                }
                
            default:
                result = nil
            }
        }
        
        return result
    }
    
    func outlineViewItemDidExpand(notification: NSNotification) {
        let obj = notification.userInfo?["NSObject"] as! FileListNode
        expandedNodes?.insert(obj)
    }
    func outlineViewItemDidCollapse(notification: NSNotification) {
        let obj = notification.userInfo?["NSObject"] as! FileListNode
        expandedNodes?.remove(obj)
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
                
                flatPriorities = filteredFiles.count > 0 ? filteredFiles : nil
                filePrioritiesDidChange(filteredFiles)
            }
        }
    }
    
    func setPriorityForFile(file: FileListNode, state: Int) {
        guard file.percentCompleted < 1 else {
            return
        }
        
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
                checked += 1
            }
            else if state == NSOffState{
                skipped += 1
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
    
    func filePrioritiesDidChange(priorities: [FileListNode: Int]) {
        
    }
}
