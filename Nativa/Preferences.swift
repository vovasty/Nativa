//
//  Preferences.swift
//  SwiftySSH
//
//  Created by Solomenchuk, Vlad on 8/17/15.
//  Copyright © 2015 Vladimir Solomenchuk. All rights reserved.
//

import Cocoa

class RTorrentProcessPreferences: NSViewController{
    @objc var processName: String?
    @objc var scgiPort: String?
    @objc var useSSH: Bool = false
    @objc var sshHost: String?
    @objc var sshUser: String?
    @objc var sshPassword: String?
    
    @IBAction func saveChanges(sender: AnyObject) {
        guard let processName = processName else{
            let error = NSError(domain: "net.aramzamzam.Nativa", code: -1, userInfo: [NSLocalizedDescriptionKey: "Some fields not defined"])
            NSApp.presentError(error)
            return
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var processes = defaults["processes"] as? [[String: AnyObject]] ?? []
        
        var dict: [String: AnyObject] = [
            "name": processName,
            "scgiPort": scgiPort ?? "localhost:5000"
        ]
        
        func save() {
            processes.append(dict)
            defaults["processes"] = processes
            defaults.synchronize()
            dismissController(nil)
        }
        
        guard useSSH else {
            dict["useSSH"] = false
            save()
            return
        }
        
        guard let sshHost = sshHost, let sshUser = sshUser, let sshPassword = sshPassword else{
            let error = NSError(domain: "net.aramzamzam.Nativa", code: -1, userInfo: [NSLocalizedDescriptionKey: "Some fields not defined"])
            NSApp.presentError(error)
            return
        }
        
        dict["useSSH"] = true
        dict["sshHost"] = sshHost
        dict["sshUser"] = sshUser
        dict["sshPassword"] = sshPassword
        save()
    }
}

class Processes: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var tableView: NSTableView!
    
    private var processes: [[String: AnyObject]] {
        return NSUserDefaults.standardUserDefaults()["processes"] as? [[String: AnyObject]] ?? []
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "processes", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    
    //MARK :NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return processes.count
    }
    

    //MARK :NSTableViewDelegate
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("NameCell", owner: self) as? NSTableCellView
        cell?.textField?.stringValue = processes[row]["name"] as? String ?? "Unknown"
        return cell
    }
    
//    func tableView(tableView: NSTableView, shouldEditTableColumn tableColumn: NSTableColumn?, row: Int) -> Bool {
//        return true
//    }

    func tableViewSelectionIsChanging(notification: NSNotification) {
        
    }
    
    
    @IBAction func removeProcess(sender: AnyObject) {
        guard self.tableView.selectedRow != -1 else {
            return
        }
        
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.addButtonWithTitle("Cancel")
        alert.messageText = "Delete the record?"
        alert.informativeText = "Deleted records cannot be restored."
        alert.alertStyle = NSAlertStyle.WarningAlertStyle
        alert.beginSheetModalForWindow(self.view.window!) {
            guard $0 == NSAlertFirstButtonReturn else {
                return
            }

            var processes = self.processes
            processes.removeAtIndex(self.tableView.selectedRow)
            NSUserDefaults.standardUserDefaults()["processes"] = processes
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        self.tableView.reloadData()
    }
    
    deinit {
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "processes")
    }
}
