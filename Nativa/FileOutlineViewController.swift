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
            if let files = download?.flatFileList, files.count > 0 {
                filePriorities = files.reduce([FileListNode: (priority: DownloadPriority, state: Int)](), { (d, file) -> [FileListNode: (priority: DownloadPriority, state: Int)] in
                    
                    var dict = d
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
        self.outlineView.register(fileNameNib!, forIdentifier: "FileNameCell")
        let folderNameNib = NSNib(nibNamed: "FolderName", bundle: nil)
        self.outlineView.register(folderNameNib!, forIdentifier: "FolderNameCell")
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int
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
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
    {
        if let file = item as? FileListNode {
            if let children = file.children {
                return children.count > 0
            }
        }
        
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
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
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any?
    {
        if let file = item as? FileListNode {
            return file
        }
        
        return nil
    }
    
    // Delegate methods
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
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
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
    {
        var result: NSView?
        
        if let file = item as? FileListNode, let ci = tableColumn?.identifier {
            
            switch ci {
            case "FileNameColumn":
                if file.folder {
                    if let cell = outlineView.make(withIdentifier: "FolderNameCell", owner:self) as? NSTableCellView {
                        cell.imageView?.image = file.icon
                        cell.textField?.stringValue = file.name
                        
                        if let c = cell as? FolderNameCell {
                            c.setName(name: file.name, size: file.size, complete: file.percentCompleted)
                        }
                        
                        result = cell
                    }
                }
                else {
                    if let cell = outlineView.make(withIdentifier: "FileNameCell", owner:self) as? NSTableCellView {
                        if let c = cell as? FileNameCell {
                            c.statusText.stringValue = String(format: "%.2f%%", file.percentCompleted*100) + " of " + Formatter.string(fromSize: file.size)
                        }
                        
                        cell.imageView?.image = file.icon
                        cell.textField?.stringValue = file.name
                        
                        result = cell
                    }
                }
            case "FileCheckColumn":
                if let cell = outlineView.make(withIdentifier: "FileCheckCell", owner:self) as? NSTableCellView {
                    if let button: NSButton = cell.findSubview() {
                        button.action = #selector(fileChecked(_:))
                        button.target = self
                        button.allowsMixedState = file.folder
                        button.state = state(fromFile: file)
                        button.isEnabled = file.percentCompleted < 1 && download?.flatFileList?.count ?? 1 > 1
                    }
                    result = cell
                }
                
            default:
                result = nil
            }
        }
        
        return result
    }
    
    func outlineViewItemDidExpand(_ notification: Foundation.Notification) {
        let obj = notification.userInfo?["NSObject"] as! FileListNode
        expandedNodes?.insert(obj)
    }
    
    func outlineViewItemDidCollapse(_ notification: Foundation.Notification) {
        let obj = notification.userInfo?["NSObject"] as! FileListNode
        _ = expandedNodes?.remove(obj)
    }
    
    @objc
    @IBAction
    private func fileChecked(_ sender: AnyObject?)
    {
        if let button = sender as? NSButton {
            let rowNumber = self.outlineView.row(for: button)
            if let file = self.outlineView.item(atRow: rowNumber) as? FileListNode {
                
                if button.state == NSMixedState {
                    button.state = NSOnState
                }
                
                setPriority(forFile: file, state: button.state)
                outlineView.reloadData()

                var filteredFiles = [FileListNode: Int]()
                
                for (file, priority) in filePriorities {
                    guard !file.folder && file.priority != priority.priority else { return }
                    
                    filteredFiles[file] = priority.priority.rawValue
                }
                
                flatPriorities = filteredFiles.count > 0 ? filteredFiles : nil
                
                filePrioritiesDidChange(priorities: filteredFiles)
            }
        }
    }
    
    func setPriority(forFile file: FileListNode, state: Int) {
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
                    setPriority(forFile: child, state: state)
                }
            }
        }
        else {
            filePriorities[file] = (priority: priority, state: state)
        }
    }
    
    func state(fromFile file: FileListNode) -> Int {
        guard file.folder else {
            return filePriorities[file]!.state
        }
        
        guard let children = file.children else {
            return NSOffState
        }
        
        var skipped = 0
        var checked = 0
        for f in children {
            let st: Int = f.folder ? state(fromFile: f) : filePriorities[f]!.state
            
            if st == NSOnState {
                checked += 1
            }
            else if st == NSOffState{
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
