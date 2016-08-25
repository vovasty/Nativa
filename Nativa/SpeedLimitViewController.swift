//
//  SpeedLimitViewController.swift
//  Nativa
//
//  Created by Solomenchuk, Vlad on 6/7/16.
//  Copyright © 2016 Aramzamzam LLC. All rights reserved.
//

import Cocoa

private let kMaxUploadSpeedKey = "maxUploadSpeed"
private let kMaxDownloadSpeed = "maxDownloadSpeed"

//http://www.corbinstreehouse.com/blog/2014/04/nstableview-tips-not-delaying-the-first-responder/
class EditableOutlineView: NSOutlineView {
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return true
    }
}

private class TreeNode: NSObject {
    let stat: Statistics
    var children: [TreeNode]? = nil
    
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
            willChangeValue(forKey: "checked")
            didChangeValue(forKey: "checked")
        }
    }
    
    //for some reason initial change doesn't apply, so trigger it
    var value: Int = 0 {
        didSet {
            willChangeValue(forKey: "value")
            didChangeValue(forKey: "value")
        }
    }

    @objc
    @IBAction
    private func setSpeedLimit(_ sender: AnyObject?) {
        handler?(checked, value)
    }
    
    //MARK: NSTextFieldDelegate
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        initialString = control.stringValue
        return true
    }
    
    func control(_ control: NSControl, didFailToFormatString string: String, errorDescription error: String?) -> Bool {
        NSBeep()
        
        if let initialString = initialString {
            control.stringValue = initialString
            self.initialString = nil
        }
        
        return true
    }
}

class SpeedLimitViewController: NSViewController {
    fileprivate var stats: [ProcessStatistics]!
    @IBOutlet weak var outlineView: NSOutlineView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let speedLimitCellNib = NSNib(nibNamed: "SpeedLimitCell", bundle: nil)!
        self.outlineView.register(speedLimitCellNib, forIdentifier: "DownloadCell")
        self.outlineView.register(speedLimitCellNib, forIdentifier: "UploadCell")

        update()
        resize()
    }
    
    private func  resize() {
        let rect = outlineView.rect(ofRow: outlineView.numberOfRows - 1)
        let outlineViewHeight = rect.maxY
        let outlineViewVPaddings = view.frame.height - outlineView.superview!.superview!.frame.height
        let windowHeight = outlineViewHeight + outlineViewVPaddings

        let size = CGSize(width: outlineView.bounds.width, height: windowHeight)
        
        view.frame = CGRect(origin: CGPoint.zero, size: size)
    }

    private func update() {
        var stats = Array<Statistics>(Datasource.instance.statistics.values)
        
        stats.sort{ (lhs, rhs) -> Bool in
            lhs.id > rhs.id
        }
        
        for stat in stats {
            if stat.maxDownloadSpeed != 0 {
                self.setSpeed(id: stat.id, key: kMaxDownloadSpeed, value: Int(stat.maxDownloadSpeed))
            }
            
            if stat.maxUploadSpeed != 0 {
                self.setSpeed(id: stat.id, key: kMaxUploadSpeedKey, value: Int(stat.maxUploadSpeed))
            }
        }
        
        self.stats = stats.map { ProcessStatistics($0) }
        
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
    }
}

//MARK: NSOutlineViewDataSource
extension SpeedLimitViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let stats = stats, stats.count > 0 else { return 0 }
        
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
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool
    {
        guard let item = item as? TreeNode else {
            precondition(false, "wrong object type")
            return false
        }
        
        return item.children != nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any
    {
        if item == nil {
            if stats.count == 1 {
                return stats.first!.children![index]
            }
            else {
                return stats[index]
            }
        }

        guard let item = item as? TreeNode else {
            precondition(false, "wrong object type")
            return ""
        }
        
        return item.children![index]
    }
}

//MARK: NSOutlineViewDelegate
extension SpeedLimitViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView?
    {
        switch item {
        case let item as ProcessStatistics:
            let result = outlineView.make(withIdentifier: "HeaderCell", owner:self) as? NSTableCellView
            result?.textField?.stringValue = item.stat.id.uppercased()
            return result
        case let item as DownloadStatistics:
            let result = outlineView.make(withIdentifier: "DownloadCell", owner:self) as? SpeedLimitCell
            result?.checkBox.title = "Download limit"
            result?.value = (item.stat.maxDownloadSpeed == 0 ? getSpeed(id: item.stat.id, key: kMaxDownloadSpeed) : Int(item.stat.maxDownloadSpeed)) / 1024
            result?.checked = item.stat.downloadLimited
            result?.handler = { (checked, value) in

                let speed = (checked ? value : 0) * 1024

                if speed != 0 {
                    self.setSpeed(id: item.stat.id, key: kMaxDownloadSpeed, value: speed)
                }
                
                Datasource.instance.setMaxDownloadSpeed(processId: item.stat.id, speed: speed) { (error) in
                    if let error = error {
                        logger.error("unable to set max download speed: \(error)")
                    }
                }
            }
            return result
        case let item as UploadStatistics:
            let result = outlineView.make(withIdentifier: "UploadCell", owner:self) as? SpeedLimitCell
            result?.checkBox.title = "Upload limit"
            result?.value = (item.stat.maxUploadSpeed == 0 ? getSpeed(id: item.stat.id, key: kMaxUploadSpeedKey) : Int(item.stat.maxUploadSpeed)) / 1024
            result?.checked = item.stat.uploadLimited
            result?.handler = { (checked, value) in
                
                let speed = (checked ? value : 0) * 1024
                
                if speed != 0 {
                    self.setSpeed(id: item.stat.id, key: kMaxUploadSpeedKey, value: speed)
                }
                
                Datasource.instance.setMaxUploadSpeed(processId: item.stat.id, speed: speed) { (error) in
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
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return false
    }
    
    fileprivate func setSpeed(id: String, key: String, value: Int) {
        let sd = UserDefaults.standard
        
        guard let info = getAccount(id: id) else {
            assert(false, "no accounts")
            return
        }
        
        var accounts = info.accounts
        var account = info.account
        let index = info.index
        
        account[key] = value
        accounts[index] = account
        
        sd[kAccountsKey] = accounts
        sd.synchronize()
    }
    
    private func getSpeed(id: String, key: String) -> Int {
        
        guard let info = getAccount(id: id) else {
            assert(false, "no accounts")
            return 0
        }

        
        return info.account[key] as? Int ?? 0
    }
    
    private func getAccount(id: String) -> (accounts: [[String: Any]], account: [String: Any], index: Int)? {
        let sd = UserDefaults.standard
        
        guard var accounts = sd.array(forKey: kAccountsKey) as? [[String: Any]] else { return nil }
        
        var index: Int!
        var account: [String: Any]!
        
        for i in 0..<accounts.count {
            let d = accounts[i]
            if d["name"] as? String ?? "" == id {
                index = i
                account = d
                break
            }
        }
        
        guard index != nil && account != nil else { return nil }
        
        return (accounts, account, index)
    }

}
