//
//  SpeedLimitViewController.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 6/7/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Cocoa

//http://www.corbinstreehouse.com/blog/2014/04/nstableview-tips-not-delaying-the-first-responder/
class EditableOutlineView: NSOutlineView {
    override func validateProposedFirstResponder(responder: NSResponder, forEvent event: NSEvent?) -> Bool {
        return true
    }
}

private class TreeNode: NSObject {
    let stat: Statistics
    private (set) var children: [TreeNode]? = nil
    
    init(_ stat: Statistics) {
        self.stat = stat
    }
}

private class ProcessStatistics: TreeNode {
    override init(_ stat: Statistics) {
        super.init(stat)
        
        children = [DownloadStatistics(stat), UploadStatistics(stat)]
    }
}
private class DownloadStatistics: TreeNode {}
private class UploadStatistics: TreeNode {}

class SpeedLimitCell: NSTableCellView, NSTextFieldDelegate {
    @IBOutlet weak var checkBox: NSButton!
    @IBOutlet weak var valueField: NSTextField!
    @IBOutlet weak var labelField: ColorTextField!
    private var initialString: String?
    var handler: ((Bool, Int) -> Void)?
    
    //for some reason initial change doesn't apply, so trigger it
    var checked: Bool = false {
        didSet {
            willChangeValueForKey("checked")
            didChangeValueForKey("checked")
        }
    }
    
    //for some reason initial change doesn't apply, so trigger it
    var value: Int = 0 {
        didSet {
            willChangeValueForKey("value")
            didChangeValueForKey("value")
        }
    }

    @IBAction func setSpeedLimit(sender: AnyObject) {
        handler?(checked, value)
    }
    
    //MARK: NSTextFieldDelegate
    func control(control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        initialString = control.stringValue
        return true
    }
    
    func control(control: NSControl, didFailToFormatString string: String, errorDescription error: String?) -> Bool {
        NSBeep()
        
        if let initialString = initialString {
            control.stringValue = initialString
            self.initialString = nil
        }
        
        return true
    }
}

class SpeedLimitViewController: NSViewController {
    private var stats: [ProcessStatistics]!
    @IBOutlet weak var outlineView: NSOutlineView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let speedLimitCellNib = NSNib(nibNamed: "SpeedLimitCell", bundle: nil)!
        self.outlineView.registerNib(speedLimitCellNib, forIdentifier: "DownloadCell")
        self.outlineView.registerNib(speedLimitCellNib, forIdentifier: "UploadCell")

        update()
        resize()
    }
    
    private func  resize() {
        let rect = outlineView.rectOfRow(outlineView.numberOfRows - 1)
        let outlineViewHeight = CGRectGetMaxY(rect)
        let outlineViewVPaddings = CGRectGetHeight(view.frame) - CGRectGetHeight(outlineView.superview!.superview!.frame)
        let windowHeight = outlineViewHeight + outlineViewVPaddings

        let size = CGSize(width: outlineView.bounds.width, height: windowHeight)
        
        view.frame = CGRect(origin: CGPoint.zero, size: size)
    }

    private func update() {
        stats = Datasource.instance.statistics.values
        .sort{ (lhs, rhs) -> Bool in
            lhs.id > rhs.id
        }
        .map { ProcessStatistics($0) }
         ?? []
        
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
    }
}

//MARK: NSOutlineViewDataSource
extension SpeedLimitViewController: NSOutlineViewDataSource {
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        guard let stats = stats where stats.count > 0 else { return 0 }
        
        if item == nil {
            if stats.count == 1 {
                return stats.first?.children?.count ?? 0
            }
            else {
                return stats.count
            }
        }
        
        guard let item = item as? TreeNode else { return 0 }
            
        return item.children?.count ?? 0
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool
    {
        guard let item = item as? TreeNode else { precondition(false, "wrong object type") }
        
        return item.children != nil
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject
    {
        if item == nil {
            if stats.count == 1 {
                return stats.first!.children![index]
            }
            else {
                return stats[index]
            }
        }

        guard let item = item as? TreeNode else { precondition(false, "wrong object type") }
        
        return item.children![index]
    }
}

//MARK: NSOutlineViewDelegate
extension SpeedLimitViewController: NSOutlineViewDelegate {
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView?
    {
        switch item {
        case let item as ProcessStatistics:
            let result = outlineView.makeViewWithIdentifier("HeaderCell", owner:self) as? NSTableCellView
            result?.textField?.stringValue = item.stat.id.uppercaseString
            return result
        case let item as DownloadStatistics:
            let result = outlineView.makeViewWithIdentifier("DownloadCell", owner:self) as? SpeedLimitCell
            result?.checkBox.title = "Download limit"
            result?.value = Int(item.stat.maxDownloadSpeed / 1024)
            result?.checked = item.stat.downloadLimited
            result?.handler = { (checked, value) in
                let speed = (checked ? value : 0) * 1024
                Datasource.instance.setMaxDownloadSpeed(item.stat.id, speed: speed) { (error) in
                    if let error = error {
                        logger.error("unable to set max download speed: \(error)")
                    }
                }
            }
            return result
        case let item as UploadStatistics:
            let result = outlineView.makeViewWithIdentifier("UploadCell", owner:self) as? SpeedLimitCell
            result?.checkBox.title = "Upload limit"
            result?.value = Int(item.stat.maxUploadSpeed / 1024)
            result?.checked = item.stat.uploadLimited
            result?.handler = { (checked, value) in
                let speed = (checked ? value : 0) * 1024
                Datasource.instance.setMaxUploadSpeed(item.stat.id, speed: speed) { (error) in
                    
                    if let error = error {
                        logger.error("unable to set max upload speed: \(error)")
                    }
                }
            }
            return result
        default:
            assert(false, "unreachable")
            return nil
        }
    }
    
    func outlineView(outlineView: NSOutlineView, shouldShowOutlineCellForItem item: AnyObject) -> Bool {
        return false
    }
    
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        return false
    }
}