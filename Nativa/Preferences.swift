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
    
    @objc
    @IBAction
    private func saveChanges(_ sender: AnyObject?) {
        commitEditing()
        
        guard let processName = processName else{
            let error = NSError(domain: "net.aramzamzam.Nativa", code: -1, userInfo: [NSLocalizedDescriptionKey: "Some fields not defined"])
            NSApp.presentError(error)
            return
        }
        
        let defaults = UserDefaults.standard
        var processes = defaults[kAccountsKey] as? [[String: Any]] ?? []
        
        var dict: [String: Any] = [
            "name": processName as Any,
            "scgiPort": scgiPort as Any? ?? "localhost:5000" as Any
        ]
        
        func save() {
            processes.append(dict)
            defaults[kAccountsKey] = processes
            defaults.synchronize()
            dismiss(nil)
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
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        //save on close
        arrayController.commitEditing()
        
        if let app = NSApp.delegate as? AppDelegate {
            app.connect()
        }
    }
    
    //MARK :NSTableViewDelegate
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.make(withIdentifier: "NameCell", owner: self) as? NSTableCellView
        return cell
    }
    
    @objc
    @IBAction
    private func removeProcess(_ sender: AnyObject?) {
        guard self.tableView.selectedRow != -1 else {
            return
        }
        
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.messageText = "Delete the record?"
        alert.informativeText = "Deleted records cannot be restored."
        alert.alertStyle = .warning
        alert.beginSheetModal(for: self.view.window!) {
            guard $0 == NSAlertFirstButtonReturn else {
                return
            }
            
            self.arrayController.remove(atArrangedObjectIndex: self.arrayController.selectionIndex)
        }
    }
}
