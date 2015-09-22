//
//  Preferences.swift
//  SwiftySSH
//
//  Created by Solomenchuk, Vlad on 8/17/15.
//  Copyright © 2015 Vladimir Solomenchuk. All rights reserved.
//

import Cocoa

let kAccountsKey = "accounts"

class RTorrentProcessPreferences: NSViewController{
    dynamic var processName: String?
    dynamic var scgiPort: String?
    dynamic var useSSH: Bool = false
    dynamic var sshHost: String?
    dynamic var sshUser: String?
    dynamic var sshPassword: String?
    
    @IBAction func saveChanges(sender: AnyObject) {
        commitEditing()
        
        guard let processName = processName else{
            let error = NSError(domain: "net.aramzamzam.Nativa", code: -1, userInfo: [NSLocalizedDescriptionKey: "Some fields not defined"])
            NSApp.presentError(error)
            return
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        var processes = defaults[kAccountsKey] as? [[String: AnyObject]] ?? []
        
        var dict: [String: AnyObject] = [
            "name": processName,
            "scgiPort": scgiPort ?? "localhost:5000"
        ]
        
        func save() {
            processes.append(dict)
            defaults[kAccountsKey] = processes
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
    @IBOutlet var arrayController: NSArrayController!
    
    dynamic var useSSH: Bool = false
    dynamic var sshHost: String?
    dynamic var sshUser: String?
    dynamic var sshPassword: String?
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if arrayController.arrangedObjects.count == 0 {
            performSegueWithIdentifier("addAccount", sender: nil)
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        //save on close
        arrayController.commitEditing()
        
        if let app = NSApp.delegate as? AppDelegate {
            app.reconnect()
        }
    }
    
    //MARK :NSTableViewDelegate
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeViewWithIdentifier("NameCell", owner: self) as? NSTableCellView
        return cell
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
            
            self.arrayController.removeObjectAtArrangedObjectIndex(self.arrayController.selectionIndex)
        }
    }
}
