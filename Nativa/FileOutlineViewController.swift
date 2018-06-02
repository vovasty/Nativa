//
//  FileOutlineViewController.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 10/8/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

extension NSUserInterfaceItemIdentifier {
    static let FileNameColumn = NSUserInterfaceItemIdentifier("FileNameColumn")
    static let FileCheckColumn = NSUserInterfaceItemIdentifier("FileCheckColumn")
}

class FileOutlineViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @IBOutlet weak var outlineView: NSOutlineView!
    var filePriorities: [FileListNode: (priority: DownloadPriority, state: NSControl.StateValue)] = [:]
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
                filePriorities = files.reduce([FileListNode: (priority: DownloadPriority, state: NSControl.StateValue)](), { (d, file) -> [FileListNode: (priority: DownloadPriority, state: NSControl.StateValue)] in
                    
                    var dict = d
                    dict[file] = (priority: file.priority, state: (file.percentCompleted == 1 || file.priority != .Skip) ? .on : .off)
                    return dict
                })
            }
            else if let file = download?.file{
                filePriorities = [file: (priority: file.priority, state: file.priority == .Skip ? .off : .on)]
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
        let fileNameNib = NSNib(nibNamed: NSNib.Name(rawValue: "FileName"), bundle: nil)
        self.outlineView.register(fileNameNib!, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileNameCell"))
        let folderNameNib = NSNib(nibNamed: NSNib.Name(rawValue: "FolderName"), bundle: nil)
        self.outlineView.register(folderNameNib!, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FolderNameCell"))
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
            case .FileNameColumn:
                if file.folder {
                    if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FolderNameCell"), owner:self) as? NSTableCellView {
                        cell.imageView?.image = file.icon
                        cell.textField?.stringValue = file.name
                        
                        if let c = cell as? FolderNameCell {
                            c.setName(name: file.name, size: file.size, complete: file.percentCompleted)
                        }
                        
                        result = cell
                    }
                }
                else {
                    if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileNameCell"), owner:self) as? NSTableCellView {
                        if let c = cell as? FileNameCell {
                            c.statusText.stringValue = String(format: "%.2f%%", file.percentCompleted*100) + " of " + Formatter.string(fromSize: file.size)
                        }
                        
                        cell.imageView?.image = file.icon
                        cell.textField?.stringValue = file.name
                        
                        result = cell
                    }
                }
            case .FileCheckColumn:
                if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FileCheckCell"), owner:self) as? NSTableCellView {
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
    private func fileChecked(_ sender: NSButton)
    {
        let rowNumber = self.outlineView.row(for: sender)
        guard let file = self.outlineView.item(atRow: rowNumber) as? FileListNode else { return }

        if sender.state == .mixed {
            sender.state = .on
        }
        
        setPriority(forFile: file, state: sender.state)
        outlineView.reloadData()

        var filteredFiles = [FileListNode: Int]()
        
        for (file, priority) in filePriorities {
            guard !file.folder && file.priority != priority.priority else { continue }
            
            filteredFiles[file] = priority.priority.rawValue
        }
        
        flatPriorities = filteredFiles.count > 0 ? filteredFiles : nil
        
        filePrioritiesDidChange(priorities: filteredFiles)
    }
    
    func setPriority(forFile file: FileListNode, state: NSControl.StateValue) {
        guard file.percentCompleted < 1 else {
            return
        }
        
        let priority: DownloadPriority
        
        if state == .on || state == .mixed {
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
    
    func state(fromFile file: FileListNode) -> NSControl.StateValue {
        guard file.folder else {
            return filePriorities[file]!.state
        }
        
        guard let children = file.children else {
            return .off
        }
        
        var skipped = 0
        var checked = 0
        for f in children {
            let st = f.folder ? state(fromFile: f) : filePriorities[f]!.state
            
            if st == .on {
                checked += 1
            }
            else if st == .off {
                skipped += 1
            }
        }
        
        let total = children.count
        
        if skipped == total {
            return .off
        }
        if checked == total {
            return .on
        }
        return .mixed
    }
    
    func filePrioritiesDidChange(priorities: [FileListNode: Int]) {
        
    }
}
