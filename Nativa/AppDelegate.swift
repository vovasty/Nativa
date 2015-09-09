//
//  AppDelegate.swift
//  Nativa
//
//  Created by Vlad Solomenchuk on 8/5/14.
//  Copyright (c) 2014 Aramzamzam LLC. All rights reserved.
//

import Cocoa

enum NotificationActions: Int {
    case Reconnect = 0
}

let TorrentFilesAddedNotification = "net.aramzamzam.Nativa.TorrentFilesAddedNotification"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate{
    private var connectionDropObserver: NSObjectProtocol?
    private var refreshTimer: Timer!

    
    var reconnectCounter = 0
    var maxReconnectCounter = 4
    var reconnectTimeout = 1
    var refreshTimeout = 5
    
    func reconnect() {
        reconnectCounter = 0
        connect()
    }
    
    private func connect() {
        refreshTimer.stop()
        self.reconnectCounter++

        guard reconnectCounter <= maxReconnectCounter else {
            let center = NSUserNotificationCenter.defaultUserNotificationCenter()
            center.removeAllDeliveredNotifications()
            let note = NSUserNotification()
            note.title = "Error"
            note.informativeText = "Unable to connect"
            note.hasActionButton = true
            note.actionButtonTitle = "Try again"
            note.userInfo = ["action": NotificationActions.Reconnect.rawValue]
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                center.scheduleNotification(note)
            })
            return
        }
        
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let scgi_string = defaults["rtorrent.scgi"] as? String ?? "localhost:5000"
        let scgi = scgi_string.hosAndPort(5000)
        
        let connectHandler: (NSError?) -> Void = {(error) -> Void in
            guard error == nil else {
                logger.debug("unable to connect \(error)")
                return
            }
            
            self.reconnectCounter = 0
            self.refreshTimer.start()
        }
        
        if let ssh_hp = defaults["ssh.host"] as? String,
            let user = defaults["ssh.user"] as? String,
            let password = defaults["ssh.password"] as? String,
            let useSSH = defaults["rtorrent.useSSH"] as? Bool where useSSH {
                
                let ssh = ssh_hp.hosAndPort(22)
                Datasource.instance.connect(user, host: ssh.host, port: ssh.port, password: password, serviceHost: scgi.host, servicePort: scgi.port, connect: connectHandler)
        }
        else {
            Datasource.instance.connect(scgi.host, port: scgi.port, connect: connectHandler)
        }
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification)
    {
        NSUserDefaults.standardUserDefaults().setValue(true, forKey: "NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints")
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        
        connectionDropObserver = NSNotificationCenter.defaultCenter().addObserverForName(DatasourceConnectionStateDidChange, object: nil, queue: nil) { (note) -> Void in
            
            switch Datasource.instance.connectionState {
            case .Disconnected(_):
                //reconnect after a delay
                dispatch_after(dispatch_time (DISPATCH_TIME_NOW , Int64(UInt64(self.reconnectTimeout) * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () in
                    self.connect()
                }
            default:
                break
            }
        }
        
        refreshTimer = Timer(timeout: refreshTimeout) { (Void) -> Void in
                Datasource.instance.update()
        }

        
        connect()
    }
    
    private func addDownloadsFromUrls(urls: [NSURL]) {
        Datasource.instance.parseTorrents(urls) { (parsed, error) -> Void in
            guard let parsed = parsed where error == nil else {
                logger.error("unable to open files: \(error)")
                return
            }
            
            notificationCenter.postOnMain(TorrentFilesAddedNotification, info: parsed)
        }

    }
    
    func application(sender: NSApplication,
        openFiles filenames: [String]) {
            
            let filenames = filenames.map { (s) -> NSURL in return NSURL(fileURLWithPath: s) }
            addDownloadsFromUrls(filenames)
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
    
    @IBAction func openDocument(sender: AnyObject) {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["org.bittorrent.torrent", "torrent"]
        panel.beginSheetModalForWindow(NSApp.mainWindow!) { (flag) -> Void in
            self.addDownloadsFromUrls(panel.URLs)
        }
    }
    
    //MARK: NSUserNotificationCenterDelegate
    func userNotificationCenter(center: NSUserNotificationCenter,
        didActivateNotification notification: NSUserNotification) {
            center.removeDeliveredNotification(notification)
            guard let actionRaw = notification.userInfo?["action"] as? Int, let action = NotificationActions(rawValue: actionRaw) else {
                return
            }
            
            switch action {
            case .Reconnect:
                reconnect()
            }
    }
}

