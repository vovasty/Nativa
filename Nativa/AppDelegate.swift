//
//  AppDelegate.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate{
    
    private let refreshTimer: Timer = Timer(timeout: 60) { (Void) -> Void in
        Datasource.instance.update()
    }

    private func connect() {
        refreshTimer.stop()
        let defaults = NSUserDefaults.standardUserDefaults()
        let scgi = defaults["rtorrent.scgi"] as? String ?? "localhost:5000"
        
        if let ssh_hp = defaults["ssh.host"] as? String,
            let user = defaults["ssh.user"] as? String,
            let password = defaults["ssh.password"] as? String,
            let useSSH = defaults["rtorrent.useSSH"] as? Bool where useSSH {
                
                let scgi = scgi.hosAndPort(5000)
                let ssh = ssh_hp.hosAndPort(5000)
                
                Datasource.instance.connect(user, host: ssh.host, port: ssh.port, password: password, serviceHost: scgi.host, servicePort: scgi.port, connect: { (error) -> Void in
                    guard error == nil else {
                        print(error!)
                        self.connect()
                        return
                    }
                    
                    self.refreshTimer.start()
                })
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        NSUserDefaults.standardUserDefaults().setValue(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        connect()
    }
    
    //hide window instead of close
    //http://iswwwup.com/t/4904b499b7a1/osx-how-to-handle-applicationshouldhandlereopen-in-a-non-document-based-st.html
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag{
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        
        return true
    }
    
    @IBAction func openDocument(sender: AnyObject) {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["org.bittorrent.torrent", "torrent"]
        panel.beginSheetModalForWindow(NSApp.mainWindow!) { (flag) -> Void in
            Datasource.instance.addTorrentFiles(panel.URLs)
        }
    }
}

