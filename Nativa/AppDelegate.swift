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
    private var connectionDropObserver: NSObjectProtocol?
    
    private let refreshTimer: Timer = Timer(timeout: 60) { (Void) -> Void in
        Datasource.instance.update()
    }

    private func connect() {
        refreshTimer.stop()
        
//        NSThread.sleepForTimeInterval(1)
        let defaults = NSUserDefaults.standardUserDefaults()
        let scgi_string = defaults["rtorrent.scgi"] as? String ?? "localhost:5000"
        let scgi = scgi_string.hosAndPort(5000)
        
        if let ssh_hp = defaults["ssh.host"] as? String,
            let user = defaults["ssh.user"] as? String,
            let password = defaults["ssh.password"] as? String,
            let useSSH = defaults["rtorrent.useSSH"] as? Bool where useSSH {
                
                let ssh = ssh_hp.hosAndPort(5000)
                Datasource.instance.connect(user, host: ssh.host, port: ssh.port, password: password, serviceHost: scgi.host, servicePort: scgi.port)
                    { (error) -> Void in
                    guard error == nil else {
                        print(error!)
                        self.connect()
                        return
                    }
                    
                    self.refreshTimer.start()
                }
        }
        else {
            Datasource.instance.connect(scgi.host, port: scgi.port)
                { (error) -> Void in
                    guard error == nil else {
                        print(error!)
                        self.connect()
                        return
                    }
                    
                    self.refreshTimer.start()
            }
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        NSUserDefaults.standardUserDefaults().setValue(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        connectionDropObserver = NSNotificationCenter.defaultCenter().addObserverForName(ConnectionDroppedNotification, object: nil, queue: nil) { (note) -> Void in
            self.connect()
        }
        
        connect()
        
        NSNotificationCenter.defaultCenter().postNotificationName(ConnectionDroppedNotification, object: self)
    }
    
    func application(sender: NSApplication,
        openFiles filenames: [String]) {
            Datasource.instance.parseTorrents(filenames) { (parsed, error) -> Void in
                guard let parsed = parsed where error == nil else {
                    print("unable to open files: \(error)")
                    return
                }
                
                try! Datasource.instance.addTorrentFiles(parsed)
            }
            sender.replyToOpenOrPrint(.Success)
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
    
    @IBAction func open(sender: AnyObject) {
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

